# Homelab Setup — Design Document

**Date:** 2026-02-25
**Status:** Approved
**Repo:** `standw7/homelab_setup`

## Overview

Refactor the existing `standw7/homelab` into a sanitized, public, portable repository (`homelab_setup`) that a third party can clone and use to deploy a fully functional homelab on Windows or Linux.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Service modularity | Docker Compose profiles | Native feature, clean UX, single file |
| Custom app distribution | Pre-built GHCR images | No source in repo, users don't build |
| Image registry | GitHub Container Registry | Free for public repos, tied to GitHub |
| DNS/networking | CoreDNS + Caddy + Tailscale | Proven stack from existing homelab |
| Target platforms | Windows + Linux | PowerShell + Bash setup scripts |
| Setup experience | Full bootstrap scripts | Install Docker, Tailscale, Git, configure .env |
| Telegram bot | Full-featured, parameterized | All integrations available, all secrets via env vars |

## Repository Structure

```
homelab_setup/
├── README.md
├── .env.example
├── .gitignore
├── docker-compose.yml
├── CLAUDE.md
├── caddy/
│   └── Caddyfile
├── coredns/
│   └── Corefile
├── glance/
│   └── config/
│       └── glance.yml
├── beaver-habits/
│   └── data/
├── strava/
│   └── config/
│       └── config.yaml
├── searxng/
│   └── (config templates)
├── docs/
│   ├── tailscale.md
│   ├── dns-adblocking.md
│   ├── services/
│   │   ├── glance.md
│   │   ├── doit.md
│   │   ├── macronotion.md
│   │   ├── telegram-bot.md
│   │   ├── beaver-habits.md
│   │   ├── fitness-dashboard.md
│   │   ├── strava.md
│   │   ├── huginn.md
│   │   ├── n8n.md
│   │   ├── searxng.md
│   │   ├── actual-budget.md
│   │   ├── vikunja.md
│   │   ├── your-spotify.md
│   │   └── boostcamp-sync.md
│   └── plans/
├── scripts/
│   ├── setup.ps1
│   ├── setup.sh
│   └── helpers/
│       ├── install-docker.ps1
│       ├── install-docker.sh
│       ├── install-tailscale.ps1
│       ├── install-tailscale.sh
│       └── generate-env.sh / generate-env.ps1
```

## Core Services (Default)

These run with a plain `docker compose up -d`:

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| coredns | coredns/coredns | 53 | DNS: *.homelab → Tailscale IP |
| caddy | caddy | 80, 443 | Reverse proxy |
| portainer | portainer/portainer-ce | 9443, 9000 | Docker management |
| glance | glanceapp/glance | 8085 | Dashboard |
| doit | ghcr.io/standw7/doit | 3003 | Task management (frontend) |
| doit-backend | ghcr.io/standw7/doit-backend | internal | Task management (API) |
| macronotion-frontend | ghcr.io/standw7/macronotion-frontend | 3002 | Meal planning (frontend) |
| macronotion-backend | ghcr.io/standw7/macronotion-backend | internal | Meal planning (API) |
| telegram-bot | ghcr.io/standw7/telegram-bot | 8088 | Personal assistant bot |
| beaver-habits | daya0576/beaverhabits | 8083 | Habit tracker |
| fitness-dashboard | ghcr.io/standw7/fitness-dashboard | internal | Fitness tracker |

## Optional Profiles

Enabled with `docker compose --profile <name> up -d`:

| Profile | Services | Purpose |
|---------|----------|---------|
| `media` | strava, strava-daemon, your-spotify-server, your-spotify-client, your-spotify-mongo, boostcamp-sync | Activity & music tracking |
| `automation` | huginn, huginn-db, n8n | Workflow automation |
| `search` | searxng | Private search engine |
| `budget` | actual-budget | Envelope budgeting |
| `tasks` | vikunja | Alternative task management |

## Secrets & Sanitization

### Approach
- All tokens, API keys, passwords → environment variables in `.env`
- `.env.example` documents every variable with descriptions and generation commands
- Tailscale IP auto-detected by setup scripts, stored as `TAILSCALE_IP`
- CoreDNS and Caddy configs use env var substitution where supported, or are templated by setup scripts

### Items to sanitize from source homelab
- Telegram token, Vikunja token, Beaver Habits credentials (hardcoded in docker-compose.yml)
- Strava client secret, refresh token (in docker-compose.yml and strava/.env)
- Google OAuth credentials (DoIt, MacroNotion)
- Notion OAuth credentials (MacroNotion)
- Anthropic API key
- Spotify app credentials
- Huginn DB passwords
- Boostcamp sync API key, Siri API key
- Google Calendar iCal URLs
- Tailscale IP (hardcoded)
- Email address (hardcoded)
- Personal RSS feeds → replace with generic feeds
- Glance weather location → placeholder

### Pre-push audit
Run `gitleaks` on the repository before first public push.

## Setup Scripts

### Linux (`scripts/setup.sh`)
1. Check/install Docker Engine + Docker Compose
2. Check/install Git
3. Check/install Tailscale, prompt authentication
4. Auto-detect Tailscale IP
5. Copy `.env.example` → `.env`, fill `TAILSCALE_IP`
6. Interactive prompts for remaining env vars (skip optional with Enter)
7. `docker compose up -d`
8. Print access URLs
9. Remind about Tailscale DNS configuration

### Windows (`scripts/setup.ps1`)
Same flow with PowerShell. Installs Docker Desktop, checks WSL2.

Scripts are idempotent — safe to re-run.

## GHCR Image Publishing

Each custom app repo gets a GitHub Actions workflow:
- Trigger: push to main branch
- Action: build Docker image → push to `ghcr.io/standw7/<app>:latest`
- Tagging: semver on releases

Apps requiring workflows:
- DoIt (frontend + backend = 2 images)
- MacroNotion (frontend + backend = 2 images)
- Telegram Bot (1 image)
- Fitness Dashboard (1 image)
- Boostcamp Sync (1 image)

Total: 7 images to publish.

## Documentation

### README.md
- Project overview (1 paragraph)
- Architecture diagram (ASCII)
- Prerequisites list
- Quick start: clone → run setup script
- Manual setup alternative
- Service table with ports
- Profile activation guide
- Tailscale DNS configuration
- Troubleshooting

### docs/tailscale.md
- Tailscale client installation
- Auth key creation
- DNS configuration to point to CoreDNS
- Subnet routing for remote access

### docs/dns-adblocking.md
- NextDNS integration with Tailscale
- Pi-hole containerized alternative

### docs/services/*.md
Per-service pages: description, required env vars, access URL, configuration.

All documentation for non-technical users without automated tools.
