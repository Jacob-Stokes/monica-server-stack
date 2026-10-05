# How it works

One Docker Compose project, named `monica` (or `<prefix>monica`), with everything it keeps in the install folder.

## Services

- **`monica`** serves Monica's web app and REST API (the official `monica:4.1.2-apache` image, unmodified).
- **`monica-cron`** runs Monica's scheduler, the same image with `cron.sh`. It sends reminders and birthday notices, and runs Monica's other periodic jobs. Monica setups often leave it out, and then reminders never arrive.
- **`monica-db`** is MariaDB 11.4.
- **`monica-mcp`** is [monica-mcp](https://github.com/Jacob-Stokes/monica-mcp), built from its release tag. It reaches Monica at `http://monica` on the project's network, with the API token the setup container writes.
- **`monica-setup`** runs once on each `docker compose up`, then exits.
- **`caddy`**, **`tailscale`** or **`cloudflared`** start only with their [profile](https.md).

## The setup container

`monica-setup` runs `setup/setup.php` inside Monica's own image, using Monica's own commands and models. Each time, it checks three things and only acts where something is missing:

1. **The account.** With no account yet, it creates one from `MONICA_EMAIL` and `MONICA_PASSWORD`, then sets its name, timezone and currency (Monica would otherwise start every account as John Doe, America/Chicago, US dollars).
2. **Passport's personal access client**, which Monica needs before it can issue API tokens.
3. **The MCP server's API token**, in `data/mcp/token`. A new one is created if there's none, if it was revoked or deleted in Monica, or if it expires within 30 days (Monica's tokens last a year). The token it replaces is revoked.

The token file belongs to the MCP server's user (uid 1000) and only it can read it. The MCP server notices a new token without restarting, so `monica-stack token` replaces it with no downtime.

The MCP server only starts once the setup container has finished successfully.

## Data

Everything is in the install folder, nothing in Docker volumes:

| Path | |
|---|---|
| `.env` | Settings and secrets, including the app key that Monica's encrypted data needs |
| `monica.env` | Optional extra Monica settings |
| `data/db` | The database |
| `data/storage` | Monica's files: photos, documents, Passport's keys |
| `data/mcp/token` | The MCP server's API token |
| `data/caddy`, `data/tailscale` | HTTPS state, when used |
| `backups/` | [Backups](managing.md#backups) |

Moving to another server is copying the folder (with the stack stopped), or a backup and a restore.

## Rate limit

Monica allows 60 API requests a minute by default, which an AI client working through contacts can use up in seconds. The stack sets `RATE_LIMIT_PER_MINUTE_API=600`; monica-mcp also waits and retries when Monica says to slow down.
