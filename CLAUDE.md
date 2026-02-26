# homelab_setup

Public, modular homelab distribution. Clone it, run the setup script, and get a fully functional self-hosted stack on Windows or Linux.

## Quick Start

```bash
# Linux
git clone https://github.com/standw7/homelab_setup.git
cd homelab_setup
bash scripts/setup.sh

# Windows (PowerShell)
git clone https://github.com/standw7/homelab_setup.git
cd homelab_setup
powershell scripts/setup.ps1
```

The setup script installs Docker, Tailscale, and Git if missing, then walks you through configuring environment variables and starts the stack.

## Architecture

- **Docker Compose** with profiles for modular service selection
- **Caddy** reverse proxy: routes `*.homelab` domains to containers
- **CoreDNS**: resolves `*.homelab` to your Tailscale IP
- **Tailscale VPN**: secure remote access from any device

```
[Browser] → [Caddy :80] → [Service Containers]
[Tailscale VPN] → [CoreDNS :53] → *.homelab → [Caddy]
```

## Core Services (default)

Run with `docker compose up -d`:

| Service | Domain | Description |
|---------|--------|-------------|
| Glance | home.homelab / glance.homelab | Dashboard with feeds, weather, bookmarks |
| DoIt | tasks.homelab | Task management (Next.js + FastAPI) |
| MacroNotion | meals.homelab | Meal planning with Notion integration |
| Telegram Bot | (polling) | AI assistant with Claude, search, tasks, calendar |
| Beaver Habits | habits.homelab | Habit tracker |
| Fitness Dashboard | fitness.homelab | Exercise & reading tracker |
| Caddy | — | Reverse proxy |
| CoreDNS | — | DNS server |
| Portainer | docker.homelab | Docker management UI |

## Optional Services (profiles)

Enable with `docker compose --profile <name> up -d`:

| Profile | Services |
|---------|----------|
| `media` | Strava Statistics, Your Spotify, Boostcamp Sync |
| `automation` | Huginn, n8n |
| `search` | SearXNG |
| `budget` | Actual Budget |
| `tasks` | Vikunja |

## Project Structure

```
homelab_setup/
├── docker-compose.yml        # All services with profiles
├── .env.example              # All env vars documented
├── caddy/Caddyfile           # Reverse proxy routes
├── coredns/Corefile          # DNS config
├── glance/config/glance.yml  # Dashboard config
├── searxng/                  # Search engine config
├── strava/config/            # Strava dashboard config
├── scripts/                  # Setup scripts (bash + powershell)
│   ├── setup.sh / setup.ps1
│   └── helpers/              # Docker, Tailscale installers
└── docs/
    ├── tailscale.md          # VPN & DNS setup guide
    ├── dns-adblocking.md     # Ad-blocking options
    └── services/             # Per-service setup guides
```

## Adding a New Service

1. Add the service to `docker-compose.yml` (with a `profiles:` key if optional)
2. Add a Caddy route in `caddy/Caddyfile`
3. Add any required env vars to `.env.example` and `.env`
4. Create a service guide in `docs/services/`
5. Restart: `docker compose up -d`

## Key Files

- **`.env.example`** — all environment variables with descriptions
- **`docker-compose.yml`** — the entire stack definition
- **`caddy/Caddyfile`** — all reverse proxy routes
- **`coredns/Corefile`** — DNS resolution (templated by setup script)

## Design Document

See [docs/plans/2026-02-25-homelab-setup-design.md](docs/plans/2026-02-25-homelab-setup-design.md) for full architecture decisions and rationale.
