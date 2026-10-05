# Managing with monica-stack

`monica-stack` acts on the install it belongs to: the folder it lives in, following the link when it's on the PATH, or one given with `--dir`.

| Command | Does |
|---|---|
| `monica-stack status` | Containers, the MCP server, and whether Monica accepts its API token (and when it expires) |
| `monica-stack logs [service] [-f]` | Logs: `monica`, `cron`, `db`, `setup`, `mcp`, `caddy`, … |
| `monica-stack restart [service]` | Restart one service, or everything |
| `monica-stack endpoint [--show-token]` | The MCP server's address and bearer token |
| `monica-stack token` | Replace the MCP server's API token (no restart needed) |
| `monica-stack backup [file]` | Database, files and `.env` in one archive |
| `monica-stack restore <file>` | Put a backup back |
| `monica-stack update` | Update to the latest version |
| `monica-stack uninstall [--yes]` | Remove the containers; data is kept unless chosen |
| `monica-stack link [name]` | Put the command on the PATH (`/usr/local/bin`) |

Plain Compose works in the folder too: `docker compose ps`, `logs`, `up -d`, `down`.

## Backups

`monica-stack backup` writes `backups/monica-<date>.tar.gz` (or the file given): a dump of the database, Monica's files, `.env` and `monica.env`. It's readable by root only. A backup includes the app key, which Monica's encrypted data needs, so keep backups private.

`monica-stack restore <file>` asks first, then stops Monica, its scheduler and the MCP server, imports the database, and replaces Monica's files; the current files are kept in `data/storage.before-restore-<time>`. It also brings back the app key and the account settings from the backup's `.env`, so a backup can be restored onto a fresh install on another server.

## Updating

`monica-stack update` pulls this repository, downloads new images, rebuilds the MCP server and restarts on the new version. `.env`, `monica.env`, `compose.override.yml` and the data are left as they are.

## Uninstalling

`monica-stack uninstall` stops and removes the containers and the `monica-stack` command, then asks whether to delete the data (database, files, `.env`). It's kept unless chosen; `--yes` keeps it without asking.

## Testing

[`scripts/test-e2e.sh`](https://github.com/Jacob-Stokes/monica-server-stack/blob/main/scripts/test-e2e.sh) runs in CI on every change. It:

- installs with plain Compose, and checks the account and the token
- runs monica-mcp's own end-to-end test, every tool against the new install
- checks the CLI: status, replacing the token while the MCP server keeps working, backup and restore
- installs again with the installer, non-interactively
- uninstalls, keeping the data

It runs on any machine with Docker and Node.js, and leaves nothing behind.
