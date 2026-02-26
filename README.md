# Homelab Setup

A modular, self-hosted homelab stack that runs on Docker Compose. Clone it, run the setup script, and get a full productivity + automation stack accessible from anywhere via Tailscale VPN.

## What This Is

A collection of self-hosted services for task management, meal planning, habit tracking, fitness tracking, AI chat, automation, and more — all running on a single machine with Docker. Services are organized into **core** (always running) and **optional profiles** you can enable as needed.

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │            Docker Compose               │
                        │                                         │
[Browser] ──────────────┤  [Caddy :80] ──► Service Containers    │
                        │      ▲                                  │
[Tailscale VPN] ────────┤      │                                  │
                        │  [CoreDNS :53]                          │
                        │   *.homelab ──► Tailscale IP ──► Caddy  │
                        └─────────────────────────────────────────┘
```

**How it works:**
1. **CoreDNS** resolves all `*.homelab` domains to your machine's Tailscale IP
2. **Caddy** reverse-proxies requests to the correct container based on subdomain
3. **Tailscale** provides secure remote access from any device

## Prerequisites

- **Docker** (Docker Engine on Linux, Docker Desktop on Windows)
- **Git**
- **Tailscale** account (free at [tailscale.com](https://tailscale.com))

The setup script will install Docker, Git, and Tailscale if they're missing.

## Quick Start

### Linux

```bash
git clone https://github.com/standw7/homelab_setup.git
cd homelab_setup
bash scripts/setup.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/standw7/homelab_setup.git
cd homelab_setup
powershell scripts/setup.ps1
```

The script will:
1. Install Docker, Git, and Tailscale (if missing)
2. Detect your Tailscale IP
3. Configure DNS and environment variables
4. Walk you through setting API keys and tokens
5. Start the stack with `docker compose up -d`

## Core Services

These run by default with `docker compose up -d`:

| Service | URL | Description |
|---------|-----|-------------|
| [Glance](https://github.com/glanceapp/glance) | `http://home.homelab` | Dashboard with feeds, weather, bookmarks |
| [DoIt](https://github.com/standw7/DoIt) | `http://tasks.homelab` | Task management with calendar integration |
| [MacroNotion](https://github.com/standw7/MacroNotion) | `http://meals.homelab` | Meal planning with Notion sync |
| Telegram Bot | (polling mode) | AI assistant (Claude) with search, tasks, calendar |
| [Beaver Habits](https://github.com/daya0576/beaverhabits) | `http://habits.homelab` | Habit tracker |
| Fitness Dashboard | `http://fitness.homelab` | Exercise & reading tracker |
| [Portainer](https://www.portainer.io/) | `http://docker.homelab` | Docker management UI |

## Optional Services

Enable profiles to add more services:

```bash
# Enable a single profile
docker compose --profile media up -d

# Enable multiple profiles
docker compose --profile media --profile automation up -d

# Enable everything
docker compose --profile media --profile automation --profile budget up -d
```

| Profile | Services | Description |
|---------|----------|-------------|
| `media` | Strava Statistics, Your Spotify, Boostcamp Sync | Activity & music tracking |
| `automation` | Huginn, n8n | Workflow automation |
| `budget` | Actual Budget | Envelope-style budgeting |

## Tailscale DNS Setup

After starting the stack, configure Tailscale so `*.homelab` domains resolve:

1. Open the [Tailscale Admin Console](https://login.tailscale.com/admin/dns)
2. Go to **DNS** → **Nameservers** → **Add nameserver** → **Custom**
3. Enter your machine's Tailscale IP (shown at end of setup script)
4. **Restrict to domain:** `homelab`
5. Save

Now `http://home.homelab`, `http://tasks.homelab`, etc. will work from any Tailscale-connected device.

See [docs/tailscale.md](docs/tailscale.md) for detailed instructions.

## Auto-Start on Boot

The homelab stack starts automatically when your machine boots:

**Linux**: The setup script runs `systemctl enable docker`, which starts Docker on boot. All containers use `restart: unless-stopped`, so they come up with Docker.

**Windows**: Open Docker Desktop > Settings > General > "Start Docker Desktop when you sign in". Containers with `restart: unless-stopped` will start automatically once Docker Desktop is running.

## Syncing Changes / Refresh

When the homelab code or container images are updated (e.g., new features pushed to GitHub, new GHCR images built), pull everything down with the refresh script:

```bash
# Linux
bash scripts/refresh.sh

# Windows (PowerShell)
powershell scripts/refresh.ps1
```

The refresh script:
1. Pulls the latest code (`git pull`)
2. Pulls the latest container images (`docker compose pull`)
3. Auto-detects which profiles are currently running
4. Restarts everything with `docker compose up -d`

## Configuration

### Environment Variables

All configuration is in the `.env` file. Edit it and restart:

```bash
# Edit .env
nano .env

# Restart services
docker compose down && docker compose up -d
```

See [.env.example](.env.example) for all available variables with descriptions.

### Service Configs

| Config | Purpose |
|--------|---------|
| `glance/config/glance.yml` | Dashboard layout, feeds, weather location |
| `caddy/Caddyfile` | Reverse proxy routes |
| `coredns/Corefile` | DNS resolution |
| `strava/config/config.yaml` | Strava dashboard settings |

### Adding a New Service

1. Add the service to `docker-compose.yml` (with `profiles:` if optional)
2. Add a Caddy route in `caddy/Caddyfile`
3. Add env vars to `.env.example` and `.env`
4. `docker compose up -d`

## Troubleshooting

**DNS not resolving (`*.homelab` doesn't work)**
- Verify Tailscale is connected: `tailscale status`
- Check DNS config in Tailscale admin console
- Verify CoreDNS is running: `docker ps | grep coredns`
- Test DNS: `dig @<tailscale-ip> home.homelab`

**Port conflict (port already in use)**
- Check what's using the port: `sudo lsof -i :<port>` (Linux) or `netstat -ano | findstr :<port>` (Windows)
- Change the host port in `docker-compose.yml` (left side of `ports:` mapping)

**Docker not starting**
- Linux: `sudo systemctl start docker`
- Windows: Start Docker Desktop from the Start menu

**Services not accessible**
- Check container status: `docker compose ps`
- Check logs: `docker compose logs <service-name>`

## Documentation

- [Service Guides](docs/services/) — setup instructions for each service
- [Tailscale Setup](docs/tailscale.md) — VPN and DNS configuration
- [DNS & Ad-blocking](docs/dns-adblocking.md) — ad-blocking options
