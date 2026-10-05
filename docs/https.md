# HTTPS

By default Monica and the MCP server listen on this machine only: Monica on `127.0.0.1:8080` and the MCP server on `127.0.0.1:7011` (`MONICA_BIND` and `MCP_BIND` in `.env`). From elsewhere, an SSH tunnel reaches them:

```bash
ssh -L 8080:127.0.0.1:8080 -L 7011:127.0.0.1:7011 user@server
```

For a real address, the installer offers four options. Each puts Monica at the domain's root and the MCP server at `/mcp` on the same domain.

| Option | Needs | Address |
|---|---|---|
| Caddy | A domain pointing at the server, ports 80 and 443 open | `https://<domain>`, with a Let's Encrypt certificate |
| Tailscale | A Tailscale auth key | `https://<name>.<tailnet>.ts.net`, private to the tailnet |
| Cloudflare Tunnel | A domain on Cloudflare and a tunnel token | `https://<domain>`, no open ports |
| An existing reverse proxy | The proxy already running on the server | Its domain |

The installer sets `COMPOSE_PROFILES` (which of `caddy`, `tailscale` or `cloudflare` starts) and `APP_URL`. Monica builds its links from `APP_URL`, so it has to match the address people use.

## Caddy

Set `COMPOSE_PROFILES=caddy`, `DOMAIN` and `ACME_EMAIL`, and `APP_URL=https://<domain>`. Caddy gets and renews the certificate; its configuration is `config/Caddyfile`.

## Tailscale

Set `COMPOSE_PROFILES=tailscale`, `TS_AUTHKEY` (admin console → Settings → Keys) and optionally `TS_HOSTNAME` (default `monica`). The installer reads the machine's tailnet name once it has joined and sets `APP_URL` to it. HTTPS must be enabled for the tailnet (admin console → DNS → HTTPS Certificates). The routes are in `config/ts-serve.json`.

## Cloudflare Tunnel

Set `COMPOSE_PROFILES=cloudflare` and `CF_TUNNEL_TOKEN` (Zero Trust → Networks → Tunnels), and `APP_URL=https://<hostname>`. The tunnel's public hostname routes are set in Cloudflare: `/mcp*` to `http://monica-mcp:8080`, and everything else to `http://monica:80`.

## An existing reverse proxy

Point it at `MONICA_BIND` for Monica and at `MCP_BIND` for `/mcp` and `/.well-known/oauth-protected-resource`, and set `APP_URL` to its address. For example, with Caddy:

```
monica.example.com {
	@mcp path /mcp /mcp/* /.well-known/oauth-protected-resource
	reverse_proxy @mcp 127.0.0.1:7011
	reverse_proxy 127.0.0.1:8080
}
```
