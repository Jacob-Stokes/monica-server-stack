#!/usr/bin/env bash
# End-to-end test, as CI runs it. Needs Docker, Node 20+, git and root (or
# sudo); leaves nothing behind.
#
#   1. compose only: a .env filled in by hand, `docker compose up -d`; the
#      setup container creates the account and the MCP's token
#   2. every monica-mcp tool against it (monica-mcp's own end-to-end test)
#   3. the CLI: status, token rotation (the MCP keeps working), backup and
#      restore (data added after the backup is gone again)
#   4. the installer, non-interactively, in a second folder
#   5. uninstall
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
A="$WORK/compose-only" B="$WORK/installer"
MCP_REF="$(sed -n 's|.*monica-mcp.git#\(v[0-9.]*\).*|\1|p' "$SRC/compose.yml" | head -1)"
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; for d in "$A" "$B"; do [ -f "$d/compose.yml" ] && (cd "$d" && docker compose logs --tail 15 2>&1 | tail -30); done; exit 1; }

copy_stack() {
  mkdir -p "$1"
  (cd "$SRC" && git ls-files -z | xargs -0 -I{} cp --parents {} "$1/")
  cp "$SRC/monica-stack" "$SRC/compose.yml" "$1/"   # untracked edits too, when run by hand
  cp -r "$SRC/setup" "$SRC/config" "$1/"
}

cleanup() {
  for d in "$A" "$B"; do [ -f "$d/compose.yml" ] && (cd "$d" && docker compose down -v --remove-orphans >/dev/null 2>&1 || true); done
  docker image rm e2e-a-monica-mcp:"${MCP_REF#v}" e2e-b-monica-mcp:"${MCP_REF#v}" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

# MCP client: one tool call over HTTP, prints the result text
mcp() {
  local url="$1" token="$2" tool="$3" args="$4"
  node --input-type=module -e "
    import { Client } from '$WORK/monica-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
    import { StreamableHTTPClientTransport } from '$WORK/monica-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/streamableHttp.js';
    const c = new Client({ name: 'e2e', version: '1' }, { capabilities: {} });
    await c.connect(new StreamableHTTPClientTransport(new URL('$url'), { requestInit: { headers: { Authorization: 'Bearer $token' } } }));
    const r = await c.callTool({ name: '$tool', arguments: $args });
    if (r.isError) { console.error(r.content[0].text); process.exit(1); }
    console.log(r.content[0].text);
    await c.close();"
}

echo "== monica-mcp $MCP_REF (for its test suite and an MCP client)"
git clone -q --depth 1 --branch "$MCP_REF" https://github.com/Jacob-Stokes/monica-mcp.git "$WORK/monica-mcp"
(cd "$WORK/monica-mcp" && npm ci --silent && npx tsc) || fail "build monica-mcp"
pass "monica-mcp $MCP_REF built"

echo "== 1. compose only"
copy_stack "$A"
cd "$A"
cp .env.example .env
PW_A="$(openssl rand -hex 8)"
sed -i "s|^INSTANCE_PREFIX=.*|INSTANCE_PREFIX=e2e-a-|; s|^APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|; s|^DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -hex 16)|;
  s|^MCP_BEARER_TOKEN=.*|MCP_BEARER_TOKEN=bearer-a|; s|^MONICA_EMAIL=.*|MONICA_EMAIL=a@example.com|; s|^MONICA_PASSWORD=.*|MONICA_PASSWORD=$PW_A|;
  s|^MONICA_NAME=.*|MONICA_NAME=Ada Lovelace|; s|^MONICA_CURRENCY=.*|MONICA_CURRENCY=GBP|; s|^TZ=.*|TZ=Europe/London|;
  s|^MONICA_BIND=.*|MONICA_BIND=127.0.0.1:18180|; s|^MCP_BIND=.*|MCP_BIND=127.0.0.1:17111|; s|^APP_URL=.*|APP_URL=http://localhost:18180|" .env
docker compose up -d --quiet-pull >"$WORK/up.log" 2>&1 || { tail -20 "$WORK/up.log"; fail "docker compose up -d"; }
for _ in $(seq 1 90); do [ "$(docker inspect -f '{{.State.Status}}' e2e-a-monica-setup 2>/dev/null)" = exited ] && break; sleep 2; done
[ "$(docker inspect -f '{{.State.ExitCode}}' e2e-a-monica-setup)" = 0 ] || fail "the setup container finished cleanly"
docker logs e2e-a-monica-setup 2>&1 | grep -q "created the account a@example.com" || fail "setup created the account"
[ -s data/mcp/token ] && [ "$(stat -c '%u %a' data/mcp/token)" = "1000 600" ] || fail "setup wrote the token, for uid 1000 only"
pass "docker compose up -d: account and token created"
for _ in $(seq 1 30); do curl -sf http://127.0.0.1:17111/health >/dev/null && break; sleep 2; done
status="$(mcp http://127.0.0.1:17111/mcp bearer-a monica_status '{}')" || fail "monica_status through the MCP server"
grep -q '"user": "Ada Lovelace"' <<<"$status" && grep -q '"currency": "GBP"' <<<"$status" && grep -q '"timezone": "Europe/London"' <<<"$status" || fail "the account's name, currency and timezone: $status"
pass "the MCP server answers with the account (name, currency, timezone)"
docker compose up -d >/dev/null 2>&1
for _ in $(seq 1 60); do [ "$(docker inspect -f '{{.State.Status}}' e2e-a-monica-setup)" = exited ] && break; sleep 2; done
docker logs e2e-a-monica-setup 2>&1 | tail -1 | grep -q "MCP token: valid until" || fail "a second up keeps the token"
pass "a second docker compose up -d changes nothing"

echo "== 2. every monica-mcp tool"
(cd "$WORK/monica-mcp" && MONICA_BASE_URL=http://127.0.0.1:18180 MONICA_API_TOKEN="$(cat "$A/data/mcp/token")" node scripts/e2e.mjs) || fail "monica-mcp end-to-end test"
pass "monica-mcp's end-to-end test"

echo "== 3. the CLI"
./monica-stack status </dev/null | grep -q "Monica accepted" || fail "status says the token is accepted"
pass "status"
before="$(sha256sum data/mcp/token)"
./monica-stack token </dev/null >/dev/null || fail "token"
[ "$(sha256sum data/mcp/token)" != "$before" ] || fail "token replaced the token"
mcp http://127.0.0.1:17111/mcp bearer-a monica_contacts '{"action":"create","first_name":"Kept"}' >/dev/null || fail "the MCP server works with the new token, without a restart"
pass "token: replaced, and the MCP server carried on"
./monica-stack backup </dev/null >/dev/null || fail "backup"
backup="$(ls backups/*.tar.gz)"
mcp http://127.0.0.1:17111/mcp bearer-a monica_contacts '{"action":"create","first_name":"Lost"}' >/dev/null
./monica-stack restore "$backup" --yes </dev/null >"$WORK/restore.log" 2>&1 || { tail -20 "$WORK/restore.log"; fail "restore"; }
for _ in $(seq 1 30); do curl -sf http://127.0.0.1:17111/health >/dev/null && break; sleep 2; done
names="$(mcp http://127.0.0.1:17111/mcp bearer-a monica_contacts '{"action":"list"}')"
grep -q '"Kept"' <<<"$names" && ! grep -q '"Lost"' <<<"$names" || fail "restore brought back the backup's data: $names"
pass "backup and restore"

echo "== 4. the installer (non-interactive)"
copy_stack "$B"
cd "$B"
cp .env.example .env
sed -i 's/^INSTANCE_PREFIX=.*/INSTANCE_PREFIX=e2e-b-/; s/^MONICA_BIND=.*/MONICA_BIND=127.0.0.1:18181/; s/^MCP_BIND=.*/MCP_BIND=127.0.0.1:17112/' .env
export PW_B="$(openssl rand -hex 8)"
./monica-stack install --yes --email b@example.com --name "Grace Hopper" --password-env PW_B --tz America/New_York --currency USD --https none </dev/null >"$WORK/install.log" 2>&1 \
  || { tail -30 "$WORK/install.log"; fail "install --yes"; }
grep -q '^MONICA_PASSWORD=""' .env || fail "the password isn't kept in .env after setup"
token_b="$(sed -n 's/^MCP_BEARER_TOKEN="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' .env)"
mcp http://127.0.0.1:17112/mcp "$token_b" monica_status '{}' | grep -q '"user": "Grace Hopper"' || fail "the installed MCP server answers"
pass "install --yes: account, token, MCP server"

echo "== 5. uninstall"
./monica-stack uninstall --yes </dev/null >/dev/null
[ -z "$(docker ps -aq --filter name=e2e-b-)" ] || fail "uninstall removed the containers"
[ -d data/db ] || fail "uninstall --yes keeps the data"
pass "uninstall (data kept)"

echo "== all passed"
