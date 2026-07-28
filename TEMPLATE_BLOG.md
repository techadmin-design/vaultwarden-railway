# Deploy and Host Vaultwarden Self-Hosted on Railway

Vaultwarden is the lightweight, Rust-based server that speaks the Bitwarden API. Every official Bitwarden client, browser extension, phone app, desktop app, connects to it exactly like it would to Bitwarden's own cloud, so you get a full password manager with zero client-side compromise and every byte of vault data on infrastructure you control.

## About Hosting Vaultwarden-Self-Hosted

Bitwarden Teams costs $4/user/month, Enterprise runs $6/user/month, both billed annually. A 15-person company pays $720 to $1,080 a year just for vault access, and that number climbs every time you hire. Vaultwarden self-hosted on Railway costs a flat infrastructure fee no matter how many people or organizations you add, so the math only gets better as your team grows.

The bigger reason people choose this over price alone is what's actually stored in a password vault. It's not just logins, it's every credential you've ever saved: banking, email, work systems, the master keys to your digital life. Handing that to a third party means trusting their breach history, their retention policies, and their incident response, forever. Self-hosting means your encrypted vault never leaves a server you control. For teams handling client credentials specifically, that's often a real compliance requirement, not a nice-to-have.

It's worth being direct about something too: Vaultwarden is not the official Bitwarden server. It's an independent, actively-maintained reimplementation written in Rust, popular specifically because the official server is heavier to self-host and Vaultwarden's smaller footprint runs comfortably on a fraction of the resources. The official Bitwarden server ships as a multi-container stack meant for larger deployments; Vaultwarden collapses that down to a single lightweight binary that a small team or individual can run cheaply, without giving up any client compatibility along the way.

This also isn't a fringe project. Vaultwarden has more GitHub stars than most self-hosted alternatives in this category, and it's been through years of community security review because so many people trust it with something as sensitive as a password vault. That track record matters more here than for, say, a scheduling tool, since the value proposition rests entirely on the server being trustworthy.

## Common Use Cases

- **Small teams and startups**: Share credentials for shared tools like AWS, hosting dashboards, and analytics accounts without a per-seat bill eating into a lean budget.
- **Privacy-conscious individuals**: Keep master passwords and every saved credential off any third-party server, with full control over backups and encryption at rest.
- **Families**: Share logins between household members through Vaultwarden's built-in organizations at zero extra cost per person added.
- **Developers and sysadmins**: Store SSH keys, API tokens, and server credentials in the same vault you already use for everyday logins, accessible from the same browser extension.
- **Agencies managing client access**: Keep client credential handoffs centralized and auditable instead of scattered across shared documents, spreadsheets, or chat threads.
- **Security-conscious hobbyists**: Run your own vault the same way you might run your own DNS or VPN, one less service where your data sits on someone else's infrastructure.

## Dependencies for Vaultwarden-Self-Hosted Hosting

- PostgreSQL for Vaultwarden's own application data, users, encrypted vault entries, and organizations.
- A persistent volume for file attachments and cached website icons.

### Deployment Dependencies

This template provisions Railway-managed PostgreSQL and a persistent volume automatically, both wired to the Vaultwarden container over Railway's private network. Nothing needs manual connection setup between services. Reference: [Vaultwarden GitHub Repository](https://github.com/dani-garcia/vaultwarden), [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki), [Environment Variable Reference](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template).

### Implementation Details

This template runs `vaultwarden/server:1.37.0`, the newest stable release tag in the registry at build time, matching the image's own `latest` digest rather than trusting a floating tag that could change under you. Vaultwarden's Rocket web server reads `ROCKET_PORT`, not Railway's own `PORT` variable, so both get set explicitly to the same value, a lesson learned the hard way on another template in this collection where a Dockerfile-only port default never got picked up by Railway's routing layer. `ADMIN_TOKEN` auto-generates at deploy time and gates the `/admin` panel; `DOMAIN` points at your Railway domain automatically so exports, U2F, and email links resolve correctly out of the box.

## How Vaultwarden Compares to the Alternatives

**Vs. Bitwarden Cloud**: Bitwarden's cloud tier is fully managed and requires zero server knowledge, but charges per seat and stores your encrypted vault on Bitwarden's own infrastructure. Vaultwarden trades a small amount of setup effort for full data ownership and zero ongoing per-user cost, using the exact same client apps either way.

**Vs. 1Password**: 1Password has a polished UI and strong enterprise features, but offers no self-hosted server option at all, your vault lives on 1Password's servers no matter what plan you're on. Vaultwarden is built specifically to be self-hosted from day one.

**Vs. LastPass**: LastPass has had a rough public breach history involving encrypted vault data, which is precisely the risk self-hosting removes entirely. Vaultwarden's smaller, actively-audited Rust codebase is also easier for a security-conscious admin to actually reason about than a large commercial codebase.

## Getting Started

After deploying, wait for the healthcheck to pass. Vaultwarden is a small, efficient Rust binary, so first boot is fast, usually well under a minute, nothing like the multi-minute JVM startup you'd see on a heavier self-hosted tool.

Open your Railway domain and you'll land on Vaultwarden's own web vault. Create your account through the standard Bitwarden signup screen: email, name, master password. Your master password never leaves your device unencrypted, it's the key that derives your vault's encryption key client-side.

Immediately after creating your account, set `SIGNUPS_ALLOWED=false` in your Railway variables so nobody else can register on your instance. This isn't locked down by default, the same way most self-hosted admin tools leave registration open until you close it yourself.

From there, install the Bitwarden browser extension or mobile app, choose "self-hosted" during setup, and point it at your Railway domain instead of Bitwarden's default server. Log in with the account you just created, and start saving logins. If you're setting this up for a team, create an organization from the web vault and invite members, they'll each need their own account first.

One thing worth testing directly rather than assuming: open the admin panel at `/admin` using your `ADMIN_TOKEN` and confirm it loads. Vaultwarden's own documentation is explicit that anything you change there, diagnostics settings, user management actions, gets stored in a local config file that does not survive a redeploy on a platform like Railway. Treat Railway variables, not the admin panel, as the source of truth for anything you need to persist long-term.

While you're in there, check the diagnostics page. It shows whether your instance can reach the internet for icon downloads and whether the websocket connection is live, easy to overlook until a client silently falls back to slow polling instead of instant sync.

## Why Deploy Vaultwarden-Self-Hosted on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Vaultwarden-self-hosted on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

## Frequently Asked Questions

### Is Vaultwarden the same as Bitwarden?
No. Vaultwarden is an independent, open-source reimplementation of the Bitwarden server API, written in Rust by a different team than Bitwarden itself. Every official Bitwarden client connects to it without any modification, since it speaks the same API.

### Will my vault survive a redeploy?
Yes, as long as the Postgres and volume this template provisions stay attached to your project. Vault data lives in the database; attachments and icon caches live on the volume. What does not survive a redeploy is anything changed through the `/admin` panel, since that's stored in a local config file inside the container.

### Do I need to configure SMTP to use Vaultwarden?
No, SMTP is optional and only needed for email verification and password hint emails. Vaultwarden works fully without it, you just won't get email-based account recovery flows until you configure it.

### What happens if I lose my admin token?
You lose access to the `/admin` panel specifically, not your vault. Generate a new `ADMIN_TOKEN` value in Railway's variables and redeploy; your vault data and user accounts are untouched since the token only gates the admin interface.

### Can multiple people use one Vaultwarden instance?
Yes. Each person creates their own account, and you can group accounts into organizations for shared vaults and permission-based access, the same organization model Bitwarden's paid Teams and Enterprise tiers offer, included here at no extra cost.

### Where can I download Vaultwarden?
Source code is at `github.com/dani-garcia/vaultwarden`, with Docker images published to Docker Hub as `vaultwarden/server`. This template pulls a specific verified version automatically.
