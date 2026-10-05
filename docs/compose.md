# Docker Compose

The repository's `compose.yml` is the whole stack; the installer only writes `.env`. Setting up without it:

```bash
git clone https://github.com/Jacob-Stokes/monica-server-stack.git
cd monica-server-stack
cp .env.example .env
```

Fill in `.env`:

| Setting | |
|---|---|
| `APP_KEY` | `base64:` followed by `openssl rand -base64 32` |
| `DB_PASSWORD` | `openssl rand -hex 24` |
| `MCP_BEARER_TOKEN` | `openssl rand -hex 32`: what MCP clients send |
| `MONICA_EMAIL`, `MONICA_PASSWORD` | The first account (password 8+ characters) |
| `MONICA_NAME`, `MONICA_CURRENCY`, `TZ` | Optional: the account's name, currency and timezone |
| `APP_URL` | The URL people open Monica at; Monica builds its links from it |

Then:

```bash
docker compose up -d
```

The [setup container](how-it-works.md#the-setup-container) creates the account and the MCP server's API token on the first start. `docker compose logs monica-setup` shows what it did. Once the account exists, `MONICA_PASSWORD` can be cleared from `.env`.

The rest of `.env` (HTTPS, email, the rate limit, OAuth) is described in the file itself and in [HTTPS](https.md) and [Connecting AI tools](mcp.md).

## From another compose project

To run the stack from a compose file somewhere else, `include` it:

```yaml
include:
  - path: /opt/monica-server-stack/compose.yml
    env_file: /opt/monica-server-stack/.env
```

## Local changes

Changes for one server (an extra network, another port, labels) go in `compose.override.yml` next to `compose.yml`: Compose merges it automatically, git ignores it, and `monica-stack update` leaves it alone. For example, to put the MCP server on a network shared with other containers:

```yaml
services:
  monica-mcp:
    networks: [default, shared]

networks:
  shared:
    external: true
```

Monica settings that `compose.yml` doesn't pass go in `monica.env` next to it (see [Monica's `.env.example`](https://github.com/monicahq/monica/blob/4.x/.env.example)); it's optional, and git ignores it.

The `monica-stack` command works with an install set up this way, too: `./monica-stack status`, or `./monica-stack link` to put it on the PATH.
