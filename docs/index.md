# Monica Server Stack

Self-hosted [Monica](https://www.monicahq.com) 4 with an MCP server, in one Docker Compose project.

Monica is a personal CRM: contacts, notes, activities, reminders, gifts, debts and a journal. This stack runs it on a server together with [monica-mcp](https://github.com/Jacob-Stokes/monica-mcp), so any MCP client can read and update it over HTTP.

![The installer, sped up](https://raw.githubusercontent.com/Jacob-Stokes/monica-server-stack/main/assets/installer.gif)

## What runs

| Service | |
|---|---|
| `monica` | Monica 4.1.2, the classic version's latest release (pinned) |
| `monica-cron` | Monica's scheduler, which sends reminders |
| `monica-db` | MariaDB 11.4 |
| `monica-setup` | Runs once on each start: creates the first account and the MCP server's API token, and renews the token before it expires |
| `monica-mcp` | 14 tools for contacts, notes, activities, reminders and more, over Streamable HTTP with a bearer token (OAuth optional) |
| `caddy`, `tailscale` or `cloudflared` | Optional [HTTPS](https.md): Monica at the domain's root, the MCP server at `/mcp` |

Handled automatically: the first account, the MCP server's API token (created, and renewed before its one-year expiry), the reminder scheduler, and an API rate limit high enough for AI clients (Monica's default is 60 requests a minute).

## Two ways to set it up

Both give the same compose project, so either can be managed with `monica-stack` or plain `docker compose` afterwards.

| | [Installer](installer.md) | [Docker Compose](compose.md) |
|---|---|---|
| Setup | `./install.sh` asks a few questions | `.env` filled in by hand, then `docker compose up -d` |
| Secrets | Generated | Generated with the commands in `.env.example` |
| HTTPS, email | Asked for | Set in `.env` |
| Suits | Most setups | Servers where everything is a compose file |

It's light: Monica, its scheduler, the database and the MCP server idle at about 130 MB of RAM together. The images are about 1.7 GB on disk, most of it Monica's.

## Versions

Monica stays on 4.1.2 until a pin in `compose.yml` changes. Monica 5 is a separate rewrite, still in beta, with a different API; monica-mcp targets Monica 4. [Renovate](https://docs.renovatebot.com) proposes new versions of the pinned images and of monica-mcp, and each is tested by the [end-to-end test](managing.md#testing) before it's merged.
