# Third-party notices

This repository's own files (the compose file, configuration, the setup script and `monica-stack`) are MIT-licensed. The stack runs these as published, unmodified, pulled from their registries; none is copied into this repository:

| Software | Image | License |
|---|---|---|
| [Monica](https://github.com/monicahq/monica) | `monica:4.1.2-apache` | AGPL-3.0 |
| [MariaDB](https://mariadb.org) | `mariadb:11.4` | GPL-2.0 |
| [monica-mcp](https://github.com/Jacob-Stokes/monica-mcp) | built from its release tag | MIT |
| [Caddy](https://caddyserver.com) (optional) | `caddy:2.10` | Apache-2.0 |
| [Tailscale](https://tailscale.com) (optional) | `tailscale/tailscale` | BSD-3-Clause |
| [cloudflared](https://github.com/cloudflare/cloudflared) (optional) | `cloudflare/cloudflared` | Apache-2.0 |

Monica's AGPL-3.0 applies to Monica itself: anyone offering a modified Monica over a network must offer its source. This stack doesn't modify it; `setup/setup.php` runs inside the unmodified image and uses Monica's own commands and models.
