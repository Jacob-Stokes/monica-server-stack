# Installer

```bash
git clone https://github.com/Jacob-Stokes/monica-server-stack.git
cd monica-server-stack
./install.sh
```

Requires Linux with Docker and Compose 2.24 or newer, `openssl` and `curl`, run as a user that can use Docker. Putting the `monica-stack` command on the PATH needs root.

![The installer, sped up](https://raw.githubusercontent.com/Jacob-Stokes/monica-server-stack/main/assets/installer.gif)

*A full install, sped up.*

## What it asks

1. **The account**: email (the login), name, and password. A blank password generates one, shown once at the end.
2. **Timezone and currency**, guessed from the server, for the account's settings.
3. **The address**: this machine only, a domain with HTTPS (Caddy), Tailscale, a Cloudflare Tunnel, or an existing reverse proxy. See [HTTPS](https.md).
4. **Email**, optional: an SMTP server for reminders. Without it, reminders are only logged.

It then writes `.env` (secrets generated), downloads the images, builds the MCP server, runs `docker compose up -d`, and waits for the [setup container](how-it-works.md#the-setup-container) to create the account and the API token. The password is cleared from `.env` once the account exists.

At the end it prints Monica's address, the login, the MCP endpoint and the start of its bearer token, and offers to put a `monica-stack` command on the PATH (`/usr/local/bin`).

Running `./install.sh` again on an existing install repairs it: missing secrets are generated, nothing that's set is changed, and the account isn't asked for again.

## Without questions

For scripts and CI, `--yes` takes defaults for anything not given as an option:

```bash
export MONICA_PW='a-long-password'
./monica-stack install --yes \
  --email ada@example.com --name "Ada Lovelace" --password-env MONICA_PW \
  --tz Europe/London --currency GBP --https none
```

| Option | For |
|---|---|
| `--email`, `--name` | The account |
| `--password-env VAR` | The account's password, from an environment variable (never on the command line) |
| `--tz`, `--currency` | The account's timezone and currency |
| `--https none\|caddy\|tailscale\|cloudflare\|proxy` | The address |
| `--domain`, `--acme-email` | Caddy, and the Cloudflare Tunnel's hostname |
| `--url` | The public URL, behind an existing reverse proxy |
| `--ts-hostname` | The machine name on the tailnet |

Secrets for HTTPS come from the environment: `TS_AUTHKEY` for Tailscale, `CF_TUNNEL_TOKEN` for a Cloudflare Tunnel.

## Running a second copy

Set `INSTANCE_PREFIX` (e.g. `test-`) and different `MONICA_BIND` and `MCP_BIND` in its `.env` before installing:

```bash
cp .env.example .env
sed -i 's/^INSTANCE_PREFIX=.*/INSTANCE_PREFIX=test-/; s/^MONICA_BIND=.*/MONICA_BIND=127.0.0.1:8180/; s/^MCP_BIND=.*/MCP_BIND=127.0.0.1:7111/' .env
./install.sh
```

Its containers get the prefix, and its command is `monica-stack-test`.
