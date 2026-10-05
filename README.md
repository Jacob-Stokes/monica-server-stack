<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.gif">
    <img src="assets/logo-light.gif" alt="Monica Server Stack logo" width="90">
  </picture>
</p>

<h1 align="center">Monica Server Stack</h1>

<p align="center">Self-hosted <a href="https://www.monicahq.com">Monica</a> 4 with an <a href="https://github.com/Jacob-Stokes/monica-mcp">MCP server</a>, in one Docker Compose project.</p>

<p align="center">
  <a href="https://github.com/Jacob-Stokes/monica-server-stack/actions/workflows/e2e.yml"><img src="https://github.com/Jacob-Stokes/monica-server-stack/actions/workflows/e2e.yml/badge.svg" alt="e2e"></a>
  <a href="https://jacob-stokes.github.io/monica-server-stack/"><img src="https://img.shields.io/badge/docs-online-009688" alt="Documentation"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Jacob-Stokes/monica-server-stack" alt="MIT license"></a>
</p>

> The MCP server is [monica-mcp](https://github.com/Jacob-Stokes/monica-mcp), which also runs on its own against any Monica 4 instance, including monicahq.com.

[Monica](https://www.monicahq.com) is a personal CRM: contacts, notes, activities, reminders, gifts, debts and a journal. This stack runs Monica 4 on a server together with an MCP server, so any MCP client can read and update it over HTTP.

<p align="center">
  <img src="assets/installer.gif" alt="monica-stack installing Monica and its MCP server, sped up" width="720">
</p>

## Features

**Set up end to end.** The first account, the MCP server's API token (created, and renewed before its one-year expiry), the reminder scheduler, and an API rate limit high enough for AI clients. Monica's usual setup leaves all of these to be done by hand.

**14 MCP tools.** Contacts and their details, relationships, notes, activities, calls, conversations, reminders, tasks, gifts and debts, the journal and documents. Contacts are found by name, and deleting anything needs confirming.

**Plain Docker Compose.** `compose.yml` is the whole stack; the installer only writes `.env`. Everything it keeps is in the install folder, nothing in Docker volumes.

**HTTPS built in.** Optional Caddy, Tailscale or Cloudflare Tunnel, with Monica at the domain's root and the MCP server at `/mcp`; bearer token and optional OAuth login for MCP clients.

**Backups and updates.** `monica-stack backup` and `restore`, `update`, `status`, and token replacement with no downtime.

**Tested end to end.** CI installs the stack, runs every MCP tool against it, and exercises the CLI, on every change.

## Install

Two ways, giving the same compose project. Requires Linux with Docker and Compose 2.24 or newer.

**Installer**: asks for the account, the address and email settings, then starts everything.

```bash
git clone https://github.com/Jacob-Stokes/monica-server-stack.git
cd monica-server-stack
./install.sh
```

**Docker Compose**: copy `.env.example` to `.env`, fill in the secrets and the account, then `docker compose up -d`. See [Docker Compose](https://jacob-stokes.github.io/monica-server-stack/compose/).

The MCP endpoint is then `http://127.0.0.1:7011/mcp`; `monica-stack endpoint --show-token` prints its bearer token.

## Documentation

**[jacob-stokes.github.io/monica-server-stack](https://jacob-stokes.github.io/monica-server-stack/)**

- [Installer](https://jacob-stokes.github.io/monica-server-stack/installer/) and [Docker Compose](https://jacob-stokes.github.io/monica-server-stack/compose/)
- [How it works](https://jacob-stokes.github.io/monica-server-stack/how-it-works/): the services, the setup container, where data lives
- [Connecting AI tools](https://jacob-stokes.github.io/monica-server-stack/mcp/): clients, OAuth
- [HTTPS](https://jacob-stokes.github.io/monica-server-stack/https/): Caddy, Tailscale, Cloudflare Tunnel, an existing proxy
- [Managing with monica-stack](https://jacob-stokes.github.io/monica-server-stack/managing/): status, backups, updates

## License

MIT, for this repository. Monica (AGPL-3.0), MariaDB (GPL-2.0) and the other images are used as published, unmodified; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
