# Railway Template Composer Checklist — Vaultwarden

Apply these settings in the Railway template composer when generating the template from the project.

**Expected services this template deploys:** `vaultwarden` (the app), `Postgres`. **Verify against the actual live service names once deployed** — Railway auto-assigns a random adjective-noun name to GitHub-connected services (e.g. `selfless-dedication` on the Postiz template), so `vaultwarden` below is a placeholder until confirmed live via `railway status --json`.

---

## 1. Healthcheck Settings

### `vaultwarden` (app service)
- **Healthcheck Path:** `/alive` — Vaultwarden's real, unauthenticated healthcheck endpoint (confirmed via community discussion and Vaultwarden's own Docker healthcheck usage; also reachable at `/api/alive`, same response).
- **Healthcheck Timeout:** `60` seconds — Vaultwarden is a small Rust binary with no JVM/schema-migration startup cost, so it should come up fast. Shorter than the 120-180s timeouts used on JVM-based templates in this project (Metabase). Verify empirically on first real deploy.

### `Postgres`
- No public port exposed — no healthcheck needed (internal service only)

---

## 2. Variable Descriptions (Add to EVERY variable)

### `vaultwarden` (App) Variables

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `PORT` | `8080` | No | Port Railway routes external traffic to. Must be an explicit Railway variable, not just a Dockerfile `ENV` default — this project has confirmed the hard way (Metabase, Postiz) that a Dockerfile-only default alone doesn't get picked up by Railway's edge routing. |
| `ROCKET_PORT` | `8080` | No | Vaultwarden's actual port-configuration variable — it runs on the Rocket web framework and does not read Railway's generic `PORT` itself. Set to the same value as `PORT` above. |
| `ROCKET_ADDRESS` | `0.0.0.0` | No | Binds the server to all network interfaces. Without this, Rocket may default to binding only `127.0.0.1` inside the container, which Railway's edge cannot reach. |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | No | Connection string for Vaultwarden's own application database (users, encrypted vault entries, organizations). |
| `ADMIN_TOKEN` | `${{secret(48)}}` | No | Password gating the `/admin` panel. Auto-generated per deploy — treat like any other credential. Vaultwarden also accepts an Argon2-hashed token, but a plaintext `secret()` value is simpler for a one-click template and works fine (only generates a cosmetic startup log warning recommending the hashed form). |
| `DOMAIN` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Public URL of the instance. Used to build correct links in outgoing emails, and required for WebAuthn/U2F two-factor methods to work at all. |
| `SIGNUPS_ALLOWED` | `true` | **Yes** | Whether new accounts can self-register. Ships open by default like most self-hosted tools in this project (Postiz, Typebot) — deployer should set to `false` immediately after creating their own account. Document this clearly in README/composer description since Vaultwarden does not warn about it on its own. |
| `ENABLE_WEBSOCKET` | `true` | **Yes** | Enables real-time sync across connected clients. Runs over the same port as the main app in current Vaultwarden versions — no separate port/service needed, unlike some older self-hosted setup guides. |

### `Postgres` Variables (Railway's standard managed database plugin)

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `DATABASE_URL` | Auto-set by Railway's plugin — leave as is | No | Standard connection string, referenced directly by `vaultwarden`'s `DATABASE_URL` above. |
| `DATABASE_PUBLIC_URL` | Auto-set by Railway's plugin — leave as is | No | Public/external connection string for reaching this database from outside Railway's network. |
| `PGHOST` | `${{RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname for the database. |
| `PGPORT` | `5432` | No | Port Postgres listens on internally. **Verify this is actually filled in, not left as an empty "to be filled by the user" placeholder** — this exact composer glitch has recurred on this project's Umami and NocoDB templates. |
| `PGUSER` | `${{POSTGRES_USER}}` | No | Database username. |
| `PGDATABASE` | `${{POSTGRES_DB}}` | No | Database name. |
| `PGPASSWORD` | `${{POSTGRES_PASSWORD}}` | No | Database password. |
| `POSTGRES_USER` | `postgres` | **Yes** | Username for the Postgres superuser account. |
| `POSTGRES_PASSWORD` | Whatever Railway's plugin actually prefills — **verify live via the composer screenshot, don't assume a specific `secret()` length**. This exact wrong guess has already happened on multiple other templates in this project. | No | Auto-generated superuser password. |
| `POSTGRES_DB` | `railway` (Railway's own default) | **Yes** | Default database name created on startup. |
| `PGDATA` | `/var/lib/postgresql/data/pgdata` | **Yes** | Directory where Postgres stores its data files. Must be a subdirectory of the volume mount, not the mount root itself, or `initdb` fails on the volume's own `lost+found` directory. |
| `SSL_CERT_DAYS` | `820` | **Yes** | SSL certificate validity period. |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | **Yes** | Seconds Railway waits for active connections before a redeploy. Verify this is actually filled in, same empty-placeholder caveat as `PGPORT` above. |

---

## 3. Secrets That Must Use `${{secret()}}`

| Variable | Template Syntax |
|----------|-----------------|
| `ADMIN_TOKEN` | `${{secret(48)}}` |
| `POSTGRES_PASSWORD` | Whatever Railway's plugin already prefilled — verify live, don't assume a length |

---

## 4. Volumes

**Required.** Mount a Railway Volume to `/data` on the `vaultwarden` service. This is where Vaultwarden stores file attachments, cached website icons, and (if not using Postgres) its default SQLite database. Since this template uses Postgres for the actual database, the volume specifically protects attachments and icon caching, both real data a deployer would not want to lose on redeploy.

---

## 5. Known Troubleshooting

- **`/admin` panel changes disappear after a redeploy:** this is expected Vaultwarden behavior, not a template bug. Anything changed through the admin panel is written to `DATA_FOLDER/config.json` inside the container, which is not part of the volume mount unless explicitly configured to be. Document this clearly — set persistent config via Railway variables, not the admin UI.
- **Rocket binds to `127.0.0.1` instead of `0.0.0.0`:** if the app builds and deploys but Railway's edge can't reach it, confirm `ROCKET_ADDRESS=0.0.0.0` is actually set. This is a Rocket-framework default gotcha, not specific to Vaultwarden, but easy to miss since the reference `railwayapp-starters/vaultwarden` Dockerfile doesn't set it explicitly.
- **Floating `latest` tag risk:** the official `railwayapp-starters/vaultwarden` reference repo pins `FROM vaultwarden/server:latest`, which this project's own standing rule avoids. This template pins `1.37.0` instead, verified against Docker Hub's tags API as the current numbered release matching `latest`'s push date at authoring time. Re-verify this is still current before publishing if significant time has passed since authoring.
- **Signups left open:** Vaultwarden does not disable public registration by default. Flag this prominently in the README/composer description so deployers set `SIGNUPS_ALLOWED=false` right after creating their own account, not as an afterthought.

---

## 6. Post-Deploy Steps

After the template is published, test-deploy from a fresh Railway account (incognito window) and verify:

1. No "needs configuration" prompts appear for Postgres's auto-injected variables.
2. Both services (`vaultwarden`, `Postgres`) come online — Vaultwarden should be healthy within under a minute given its small Rust binary.
3. The app responds with a real `200` at `/alive`.
4. Open the actual Railway domain in a browser and complete real account creation through the signup screen, not just a curl check.
5. Connect an actual Bitwarden browser extension or mobile app as a self-hosted server pointed at the deployed domain, log in, and confirm a vault entry can be saved and synced, not just that the web vault loads.
6. Open `/admin` with the real `ADMIN_TOKEN` value from Railway's variables and confirm it loads.
