# Vaultwarden — Open-Source Bitwarden-Compatible Password Manager

Deploy Vaultwarden, the lightweight Rust implementation of the Bitwarden server API, on Railway with one click. Works with every official Bitwarden client (browser extension, mobile, desktop) without any changes.

## Deploy on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template)

## Features

- **Full Bitwarden client compatibility** — Browser extensions, mobile apps, and desktop apps all connect exactly like they would to Bitwarden's own cloud service.
- **End-to-end encryption** — Your vault is encrypted client-side; the server never sees plaintext passwords.
- **Organizations & sharing** — Multiple users, shared vaults, and permission levels, all included at no extra cost.
- **Live sync** — Websocket-based sync keeps every connected device updated in real time.
- **Admin panel** — A password-protected `/admin` page for managing users, diagnostics, and server config without redeploying.
- **Pinned, stable image** — Runs `vaultwarden/server:1.37.0`, a specific verified release rather than a floating `latest` tag that could change behavior under you between deploys.

## How to Use

1. Click the Deploy on Railway button above.
2. Railway automatically provisions PostgreSQL for Vaultwarden's own data (users, encrypted vault entries, organizations) and a volume for attachments and icon caching.
3. Wait for the healthcheck to pass — Vaultwarden is a small Rust binary, so first boot is fast, usually under 30 seconds.
4. Open your Railway domain and create your first account through the normal Bitwarden signup flow.
5. **Immediately after creating your account, set `SIGNUPS_ALLOWED=false`** so nobody else can register on your instance.
6. Point any official Bitwarden client at your Railway domain as a self-hosted server, log in, and start saving vault entries.

## Notes

- **Data persistence** — All vault data lives on the Railway volume this template provisions, mounted at `/data`. As long as that volume exists, your vault survives redeploys.
- **Admin panel settings don't survive redeploys** — Vaultwarden's own docs are explicit about this: anything changed through `/admin` is stored in `DATA_FOLDER/config.json`, but redeploys on Railway rebuild the container. Set critical config through Railway variables, not the admin panel, for anything you need to persist.
- **Signups are open by default** — Vaultwarden doesn't lock this down out of the box. Disable it right after creating your own account.
- **Admin token** — `ADMIN_TOKEN` is auto-generated at deploy time and gates access to `/admin`. Treat it like a password.
- **Port** — Vaultwarden's Rocket web server listens on port 8080 internally. Railway exposes it via HTTPS automatically.

## Self-Hosting on Other Platforms

Clone the repository:
```bash
git clone https://github.com/dani-garcia/vaultwarden
```

For Docker:
```bash
docker run -d --name vaultwarden \
  -e "DATABASE_URL=postgresql://user:password@host:5432/vaultwarden" \
  -e "ADMIN_TOKEN=your-admin-token" \
  -e "DOMAIN=https://your-domain.tld" \
  -v /vw-data/:/data/ \
  -p 8080:80 \
  vaultwarden/server:1.37.0
```

## License

Vaultwarden is released under the GPL-3.0 open-source license, free to self-host indefinitely with no user or organization limits.

## Support

- **GitHub** — https://github.com/dani-garcia/vaultwarden
- **Wiki** — https://github.com/dani-garcia/vaultwarden/wiki
- **Discussions** — https://github.com/dani-garcia/vaultwarden/discussions
- **Issues** — https://github.com/dani-garcia/vaultwarden/issues
