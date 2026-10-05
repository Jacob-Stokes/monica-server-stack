# Connecting AI tools

The MCP server speaks Streamable HTTP at `/mcp`:

- on the server itself: `http://127.0.0.1:7011/mcp` (`MCP_BIND` in `.env`)
- with an [HTTPS option](https.md): `https://<domain>/mcp`

Clients send `Authorization: Bearer <token>`. To see the endpoint and the token:

```bash
monica-stack endpoint --show-token
```

`/health` answers without authentication, for monitoring.

## Clients

**Claude Code:**

```bash
claude mcp add --transport http monica https://monica.example.com/mcp \
  --header "Authorization: Bearer <token>"
```

**Clients with a JSON config** (Cursor, Windsurf, VS Code and others):

```json
{
  "mcpServers": {
    "monica": {
      "url": "https://monica.example.com/mcp",
      "headers": { "Authorization": "Bearer <token>" }
    }
  }
}
```

**Claude.ai, ChatGPT and other clients that log in** rather than take a token need [OAuth](#oauth) and a public HTTPS address.

## OAuth

For clients that log in with OAuth 2.1, set these in `.env` alongside the bearer token, then `docker compose up -d`:

| Setting | |
|---|---|
| `MCP_OAUTH_ISSUER` | The identity provider's issuer URL (e.g. an Authentik or Keycloak application) |
| `MCP_OAUTH_CANONICAL_URL` | The MCP server's public URL, e.g. `https://monica.example.com` |
| `MCP_OAUTH_AUDIENCE` | Only if the provider puts the client id in the token's `aud` |

The bearer token keeps working for other clients.

## The tools

14 tools, each with an `action`, covering contacts and their details, relationships, notes, activities, calls, conversations, reminders, tasks, gifts and debts, the journal, reference data, documents and photos, and the account's status. Contacts are found by name. Deleting anything needs `confirm: true`.

The full list is in [monica-mcp's README](https://github.com/Jacob-Stokes/monica-mcp#what-it-does). monica-mcp also runs on its own, against any Monica 4 instance including monicahq.com.
