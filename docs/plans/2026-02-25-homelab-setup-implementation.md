# homelab_setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a sanitized, public, modular homelab repository that anyone can clone and deploy on Windows or Linux.

**Architecture:** Docker Compose with profiles for modular service selection. Core services (Glance, DoIt, MacroNotion, Telegram Bot, Beaver Habits, Fitness Dashboard + infrastructure) run by default. Optional services (Strava, Spotify, Huginn, n8n, SearXNG, Actual Budget, Vikunja, Boostcamp Sync) activate via `--profile`. All secrets via `.env` file. Custom apps pulled as pre-built GHCR images.

**Tech Stack:** Docker Compose, Caddy (reverse proxy), CoreDNS, Bash/PowerShell setup scripts, GitHub Actions (GHCR publishing)

**Source reference:** Existing homelab at `~/homelab` — audit everything against it but never copy secrets.

---

### Task 1: Repository Scaffolding

**Files:**
- Create: `~/homelab_setup/.gitignore`
- Create: `~/homelab_setup/CLAUDE.md`

**Step 1: Create .gitignore**

```gitignore
# Environment (contains secrets)
.env

# Runtime data
*.log
*.db
*.sqlite
__pycache__/

# Service data directories (populated at runtime)
beaver-habits/data/*.json
beaver-habits/data/*.db
beaver-habits/data/.nicegui/
homarr/appdata/
strava/build/
strava/storage/
vikunja/db/
vikunja/files/

# OS
.DS_Store
Thumbs.db
```

**Step 2: Create CLAUDE.md**

Write a CLAUDE.md that explains:
- What this project is (public homelab distribution)
- How to set up: clone, run `scripts/setup.sh` or `scripts/setup.ps1`
- Architecture: Docker Compose profiles, Caddy reverse proxy, CoreDNS DNS
- Core vs optional services (reference the design doc)
- How to add new services
- Link to `docs/plans/2026-02-25-homelab-setup-design.md` for full design

**Step 3: Commit**

```bash
cd ~/homelab_setup
git add .gitignore CLAUDE.md
git commit -m "chore: add .gitignore and CLAUDE.md scaffolding"
```

---

### Task 2: Create .env.example

**Files:**
- Create: `~/homelab_setup/.env.example`

**Step 1: Write .env.example with ALL variables**

Every env var from the source `docker-compose.yml` and `~/homelab/.env`, organized by service. Include descriptions and generation commands. Use empty values (never real secrets).

```env
# ============================================================================
# HOMELAB SETUP — Environment Variables
# ============================================================================
# Copy this file to .env and fill in your values:
#   cp .env.example .env
#
# For secrets, generate random values with:
#   openssl rand -hex 32
# ============================================================================

# === NETWORKING ===
# Your machine's Tailscale IP (run: tailscale ip -4)
TAILSCALE_IP=

# Timezone (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
TZ=America/Denver

# === ANTHROPIC (Claude AI) ===
# API key from https://console.anthropic.com/settings/keys
ANTHROPIC_API_KEY=

# === TELEGRAM BOT ===
# Bot token from @BotFather on Telegram
TELEGRAM_TOKEN=
# Comma-separated Telegram chat IDs allowed to use the bot
ALLOWED_CHAT_IDS=
# Claude model for the bot (default: claude-haiku-4-5-20251001)
CLAUDE_MODEL=claude-haiku-4-5-20251001
# API key for Apple Shortcuts / Siri integration (generate: openssl rand -hex 32)
SIRI_API_KEY=

# Telegram Bot — Service URLs (auto-configured, change only if customizing ports)
SEARXNG_URL=http://searxng:8080
VIKUNJA_URL=http://vikunja:3456
DOIT_URL=http://doit-backend:8000
BEAVER_HABITS_URL=http://beaver-habits:8080
BOOSTCAMP_SYNC_URL=http://boostcamp-sync:8087

# Telegram Bot — Vikunja integration
# Create at: http://vikunja.homelab → Settings → API Tokens
VIKUNJA_TOKEN=

# Telegram Bot — Beaver Habits credentials
# Create an account at http://habits.homelab, then enter credentials here
BEAVER_HABITS_EMAIL=
BEAVER_HABITS_PASSWORD=

# Telegram Bot — Google Calendar (pipe-separated iCal URLs)
# Get from: Google Calendar → Settings → Integrate calendar → Secret address in iCal format
GOOGLE_ICAL_URLS=

# === DOIT (Task Management) ===
# JWT secret (generate: openssl rand -hex 32)
DOIT_SECRET_KEY=
# Internal API key for telegram bot ↔ DoIt communication (generate: openssl rand -hex 32)
DOIT_INTERNAL_API_KEY=
# Google Calendar OAuth — optional (https://console.cloud.google.com)
DOIT_GOOGLE_CLIENT_ID=
DOIT_GOOGLE_CLIENT_SECRET=

# === MACRONOTION (Meal Planning) ===
# JWT secret (generate: openssl rand -hex 32)
MACRONOTION_SECRET_KEY=
# Notion OAuth — create integration at https://www.notion.so/my-integrations
MACRONOTION_NOTION_CLIENT_ID=
MACRONOTION_NOTION_CLIENT_SECRET=

# === STRAVA (Activity Tracking) — optional, profile: media ===
# Create app at https://www.strava.com/settings/api
STRAVA_CLIENT_ID=
STRAVA_CLIENT_SECRET=
STRAVA_REFRESH_TOKEN=

# === BOOSTCAMP SYNC — optional, profile: media ===
# API key for iOS Shortcut authentication (generate: openssl rand -hex 32)
BOOSTCAMP_SYNC_API_KEY=

# === YOUR SPOTIFY — optional, profile: media ===
# Create app at https://developer.spotify.com/dashboard
YOUR_SPOTIFY_PUBLIC=
YOUR_SPOTIFY_SECRET=

# === HUGINN (Automation) — optional, profile: automation ===
# MySQL passwords (generate: openssl rand -hex 16)
HUGINN_DB_ROOT_PASSWORD=
HUGINN_DB_PASSWORD=
# App secret token (generate: openssl rand -hex 64)
HUGINN_APP_SECRET_TOKEN=

# === HOMARR (Dashboard) — optional ===
# Encryption key (generate: openssl rand -hex 32)
HOMARR_SECRET_KEY=

# === SEARXNG — optional, profile: search ===
# Instance secret key (generate: openssl rand -hex 32)
SEARXNG_SECRET_KEY=homelab-searxng-secret-key-change-me
```

**Step 2: Commit**

```bash
git add .env.example
git commit -m "chore: add .env.example with all service variables documented"
```

---

### Task 3: Sanitized Infrastructure Configs

**Files:**
- Create: `~/homelab_setup/coredns/Corefile`
- Create: `~/homelab_setup/caddy/Caddyfile`

**Step 1: Create CoreDNS Corefile**

The Corefile cannot use env vars natively. The setup script will template the Tailscale IP into it. Ship a placeholder:

```
homelab:53 {
    template IN A {
        answer "{{ .Name }} 60 IN A TAILSCALE_IP_PLACEHOLDER"
    }
    log
}
```

The setup scripts will `sed` replace `TAILSCALE_IP_PLACEHOLDER` with the user's actual Tailscale IP.

**Step 2: Create Caddy Caddyfile**

Port from source `~/homelab/caddy/Caddyfile`. Remove the Spotify token redirect (personal data). Keep all service routes. The `.homelab` domain is generic and doesn't need parameterization.

```
# Global options
{
}

# Glance — dashboard (landing page)
http://home.homelab {
	reverse_proxy glance:8080
}

# Glance — feed dashboard
http://glance.homelab {
	reverse_proxy glance:8080
}

# DoIt — task management
http://tasks.homelab {
	reverse_proxy doit:3000
}

# Vikunja — task management (used by Telegram bot)
http://vikunja.homelab {
	reverse_proxy vikunja:3456
}

# MacroNotion — meal planning
http://meals.homelab {
	reverse_proxy macronotion-frontend:3000
}

# SearXNG — private search engine
http://search.homelab {
	reverse_proxy searxng:8080
}

# n8n — workflow automation
http://flows.homelab {
	reverse_proxy n8n:5678
}

# Huginn — automation platform
http://automate.homelab {
	reverse_proxy huginn:3000
}

# Actual Budget — budgeting
budget.homelab {
	tls internal
	reverse_proxy actual-budget:5006
}

# Portainer — Docker management
http://docker.homelab {
	reverse_proxy portainer:9000
}

# Strava Statistics — activity dashboard
http://strava.homelab {
	reverse_proxy strava:8080
}

# Fitness Dashboard — exercise & reading tracker
http://fitness.homelab {
	reverse_proxy fitness-dashboard:8080
}

# Beaver Habits — habit tracker
http://habits.homelab {
	reverse_proxy beaver-habits:8080
}

# Your Spotify — web client
http://spotify.homelab {
	reverse_proxy your-spotify-client:3000
}

# Your Spotify — API server
http://spotify-api.homelab {
	reverse_proxy your-spotify-server:8080
}

# Boostcamp Sync — workout sync API
http://boostcamp-sync.homelab {
	reverse_proxy boostcamp-sync:8087
}

# Siri API — Apple Shortcuts -> Telegram bot
http://siri.homelab {
	reverse_proxy telegram-bot:8088
}
```

**Step 3: Commit**

```bash
git add coredns/ caddy/
git commit -m "feat: add sanitized CoreDNS and Caddy configs"
```

---

### Task 4: Sanitized Service Configs

**Files:**
- Create: `~/homelab_setup/glance/config/glance.yml`
- Create: `~/homelab_setup/searxng/settings.yml`
- Create: `~/homelab_setup/searxng/limiter.toml`
- Create: `~/homelab_setup/strava/config/config.yaml`

**Step 1: Create Glance config with generic content**

Replace personal feeds with generic tech feeds. Replace personal weather location with a placeholder.

```yaml
server:
  port: 8080

theme:
  background-color: 0 0 100
  primary-color: 0 0 12
  positive-color: 120 57 45
  negative-color: 0 70 53
  contrast-multiplier: 1.1
  text-saturation-multiplier: 0.5
  light: true

branding:
  custom-footer: "&nbsp; Self-Hosted Homelab"

pages:
  - name: Dashboard
    columns:
      - size: full
        widgets:
          - type: weather
            # TODO: Change to your city
            location: New York, New York, United States
            units: imperial
            hour-format: 12h

          - type: bookmarks
            title: Homelab
            groups:
              - title: Productivity
                links:
                  - title: Tasks
                    url: http://tasks.homelab
                  - title: Meals
                    url: http://meals.homelab
                  - title: Budget
                    url: http://budget.homelab
                  - title: Habit Tracker
                    url: http://habits.homelab
                  - title: Fitness Tracker
                    url: http://fitness.homelab
              - title: Automation
                links:
                  - title: Huginn
                    url: http://automate.homelab
                  - title: n8n
                    url: http://flows.homelab

      - size: small
        widgets:
          - type: hacker-news
            title: Hacker News
            limit: 15
            collapse-after: 5

          - type: rss
            title: Tech News
            feeds:
              - url: https://feeds.arstechnica.com/arstechnica/index
                title: Ars Technica
              - url: https://www.theverge.com/rss/index.xml
                title: The Verge
            limit: 15
            collapse-after: 5

      - size: small
        widgets:
          - type: reddit
            subreddit: selfhosted
            title: r/selfhosted
            limit: 10
            collapse-after: 5

          - type: rss
            title: Linux & Open Source
            feeds:
              - url: https://www.phoronix.com/rss.php
                title: Phoronix
              - url: https://linuxhandbook.com/rss/
                title: Linux Handbook
            limit: 10
            collapse-after: 5
```

**Step 2: Create SearXNG config files**

Copy from source, no PII present:

`searxng/settings.yml`:
```yaml
use_default_settings: true

server:
  secret_key: "homelab-searxng-secret-key-change-me"
  bind_address: "0.0.0.0"
  port: 8080

search:
  formats:
    - html
    - json

general:
  instance_name: "Homelab Search"
```

`searxng/limiter.toml`:
```toml
# Disable rate limiting for local use
[botdetection.ip_limit]
link_token = false
```

**Step 3: Create Strava config template**

Remove personal birthday, use generic values:

```yaml
general:
  appUrl: http://strava.homelab
  athlete.birthday: 1990-01-01
  athlete.maxHeartRateFormula: fox

appearance:
  locale: en_US
  unitSystem: imperial
  timeFormat: 12

import:
  numberOfNewActivitiesToProcessPerImport: 250

daemon:
  cron:
    - action: importDataAndBuildApp
      expression: '0 */6 * * *'
      enabled: true
```

**Step 4: Create empty data directories with .gitkeep**

```bash
mkdir -p beaver-habits/data strava/storage/database strava/storage/files strava/storage/gear-maintenance strava/build vikunja/db vikunja/files homarr/appdata
touch beaver-habits/data/.gitkeep strava/storage/database/.gitkeep strava/storage/files/.gitkeep strava/storage/gear-maintenance/.gitkeep strava/build/.gitkeep vikunja/db/.gitkeep vikunja/files/.gitkeep homarr/appdata/.gitkeep
```

**Step 5: Commit**

```bash
git add glance/ searxng/ strava/ beaver-habits/ vikunja/ homarr/
git commit -m "feat: add sanitized service configs with generic placeholder data"
```

---

### Task 5: Docker Compose File (Core Services)

**Files:**
- Create: `~/homelab_setup/docker-compose.yml`

**Step 1: Write core services section**

Port each core service from `~/homelab/docker-compose.yml`. Key changes:
- Replace `build: ./DoIt` with `image: ghcr.io/standw7/doit:latest` (and similar for all custom apps)
- Replace ALL hardcoded secrets with `${ENV_VAR}` references
- Replace hardcoded `TZ=America/Denver` with `TZ=${TZ:-America/Denver}`
- Remove the Strava `build: context: ../statistics-for-strava` — use the official image `robiningelbrecht/statistics-for-strava` instead
- Add `profiles:` to optional services

The full compose file should include these sections in order:

1. **Infrastructure** (no profile): coredns, caddy, portainer
2. **Core Apps** (no profile): glance, doit, doit-backend, macronotion-frontend, macronotion-backend, telegram-bot, beaver-habits, fitness-dashboard
3. **Optional — media profile**: strava, strava-daemon, boostcamp-sync, your-spotify-mongo, your-spotify-server, your-spotify-client
4. **Optional — automation profile**: huginn-db, huginn, n8n
5. **Optional — search profile**: searxng
6. **Optional — budget profile**: actual-budget
7. **Optional — tasks profile**: vikunja
8. **Volumes section**

Critical details per service:
- `telegram-bot`: Replace ALL hardcoded values (token, Vikunja token, Beaver Habits creds, Strava secrets, calendar URLs, chat IDs) with env var references. Remove `depends_on` for optional services — the bot should handle missing integrations gracefully.
- `huginn`: Move `APP_SECRET_TOKEN` to `${HUGINN_APP_SECRET_TOKEN}` env var
- `boostcamp-sync`: Move hardcoded Strava secrets to env vars
- `strava` and `strava-daemon`: Use official image, create `strava/.env.example` for Strava-specific env file
- `your-spotify-server`: Uses `${YOUR_SPOTIFY_PUBLIC}` and `${YOUR_SPOTIFY_SECRET}` (already parameterized in source)

**Step 2: Create strava/.env.example**

```env
APP_ENV=prod
APP_SECRET=change-me-to-a-random-string
STRAVA_CLIENT_ID=
STRAVA_CLIENT_SECRET=
STRAVA_REFRESH_TOKEN=
```

**Step 3: Validate compose file syntax**

Run: `cd ~/homelab_setup && docker compose config --quiet`
Expected: no errors (warnings about unset env vars are OK)

**Step 4: Commit**

```bash
git add docker-compose.yml strava/.env.example
git commit -m "feat: add docker-compose.yml with profiles for modular services"
```

---

### Task 6: Linux Setup Script

**Files:**
- Create: `~/homelab_setup/scripts/setup.sh`
- Create: `~/homelab_setup/scripts/helpers/install-docker.sh`
- Create: `~/homelab_setup/scripts/helpers/install-tailscale.sh`

**Step 1: Write install-docker.sh**

Detect distro (Ubuntu/Debian/Fedora/Arch). Install Docker Engine + Docker Compose plugin using official repos. Verify with `docker --version` and `docker compose version`. Add current user to `docker` group.

**Step 2: Write install-tailscale.sh**

Install Tailscale using the official install script (`curl -fsSL https://tailscale.com/install.sh | sh`). Prompt user to authenticate with `sudo tailscale up`. Extract IP with `tailscale ip -4`.

**Step 3: Write setup.sh (main script)**

Full flow:
1. Check if running as root (warn, recommend running as user)
2. Check/install Git → `command -v git || sudo apt install git` (adapt per distro)
3. Call `helpers/install-docker.sh` if `docker` not found
4. Call `helpers/install-tailscale.sh` if `tailscale` not found
5. Get Tailscale IP: `TAILSCALE_IP=$(tailscale ip -4)`
6. If `.env` doesn't exist, copy `.env.example` → `.env`
7. Replace `TAILSCALE_IP=` line in `.env` with detected IP
8. Sed-replace `TAILSCALE_IP_PLACEHOLDER` in `coredns/Corefile` with actual IP
9. Interactive prompts for key env vars:
   - Required: `TELEGRAM_TOKEN`, `ANTHROPIC_API_KEY`, `ALLOWED_CHAT_IDS`
   - Auto-generate: `DOIT_SECRET_KEY`, `MACRONOTION_SECRET_KEY`, `DOIT_INTERNAL_API_KEY`, `SIRI_API_KEY` (using `openssl rand -hex 32`)
   - Optional (skip with Enter): Google OAuth, Notion OAuth, Strava, Spotify
10. `docker compose up -d`
11. Print summary:
    ```
    Homelab is running!
    Dashboard:  http://glance.homelab
    Tasks:      http://tasks.homelab
    Meals:      http://meals.homelab
    Habits:     http://habits.homelab
    Docker:     http://docker.homelab

    IMPORTANT: Configure your Tailscale DNS to use this machine as a DNS server.
    See docs/tailscale.md for instructions.
    ```

**Step 4: Make scripts executable**

```bash
chmod +x scripts/setup.sh scripts/helpers/install-docker.sh scripts/helpers/install-tailscale.sh
```

**Step 5: Test script runs without errors (dry-run check)**

Run: `bash -n scripts/setup.sh` (syntax check only)
Expected: no output (no syntax errors)

**Step 6: Commit**

```bash
git add scripts/
git commit -m "feat: add Linux bootstrap setup scripts"
```

---

### Task 7: Windows Setup Script

**Files:**
- Create: `~/homelab_setup/scripts/setup.ps1`
- Create: `~/homelab_setup/scripts/helpers/install-docker.ps1`
- Create: `~/homelab_setup/scripts/helpers/install-tailscale.ps1`

**Step 1: Write install-docker.ps1**

Check for Docker Desktop. If missing, download installer via `winget install Docker.DockerDesktop` or direct download. Check WSL2 is enabled (`wsl --status`). Prompt restart if needed.

**Step 2: Write install-tailscale.ps1**

Install via `winget install Tailscale.Tailscale`. Prompt user to sign in. Get IP with `tailscale ip -4`.

**Step 3: Write setup.ps1**

Same flow as `setup.sh` but in PowerShell:
- Use `Read-Host` for interactive prompts
- Use `[System.Security.Cryptography.RandomNumberGenerator]` for secret generation
- Use `-replace` for string substitution in config files
- Use `docker compose up -d` to start services

**Step 4: Commit**

```bash
git add scripts/
git commit -m "feat: add Windows PowerShell bootstrap setup scripts"
```

---

### Task 8: Documentation — README.md

**Files:**
- Create: `~/homelab_setup/README.md`

**Step 1: Write the master README**

Sections:
1. **Header**: Project name, one-line description, badges
2. **What This Is**: 2-3 sentences explaining this is a self-hosted homelab stack
3. **Architecture Diagram**: ASCII art showing the service layers:
   ```
   [Browser] → [Caddy Reverse Proxy] → [Services]
                                         ├── Glance (Dashboard)
                                         ├── DoIt (Tasks)
                                         ├── MacroNotion (Meals)
                                         ├── Telegram Bot (AI Assistant)
                                         ├── Beaver Habits (Habit Tracker)
                                         └── Fitness Dashboard
   [Tailscale VPN] → [CoreDNS] → *.homelab → [Caddy]
   ```
4. **Prerequisites**: Docker, Git, Tailscale account
5. **Quick Start**:
   - Linux: `git clone ... && cd homelab_setup && bash scripts/setup.sh`
   - Windows: `git clone ... && cd homelab_setup && powershell scripts/setup.ps1`
6. **Core Services Table**: Name, URL, port, description
7. **Optional Services**: How to enable profiles with `--profile`
8. **Tailscale DNS Setup**: Brief instructions + link to `docs/tailscale.md`
9. **Configuration**: How to edit `.env`, restart services
10. **Troubleshooting**: Common issues (port conflicts, DNS not resolving, Docker not starting)

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README with setup instructions"
```

---

### Task 9: Documentation — Service Guides

**Files:**
- Create: `~/homelab_setup/docs/services/glance.md`
- Create: `~/homelab_setup/docs/services/doit.md`
- Create: `~/homelab_setup/docs/services/macronotion.md`
- Create: `~/homelab_setup/docs/services/telegram-bot.md`
- Create: `~/homelab_setup/docs/services/beaver-habits.md`
- Create: `~/homelab_setup/docs/services/fitness-dashboard.md`
- Create: `~/homelab_setup/docs/services/strava.md`
- Create: `~/homelab_setup/docs/services/huginn.md`
- Create: `~/homelab_setup/docs/services/n8n.md`
- Create: `~/homelab_setup/docs/services/searxng.md`
- Create: `~/homelab_setup/docs/services/actual-budget.md`
- Create: `~/homelab_setup/docs/services/vikunja.md`
- Create: `~/homelab_setup/docs/services/your-spotify.md`
- Create: `~/homelab_setup/docs/services/boostcamp-sync.md`

**Step 1: Write each service guide**

Each guide follows this template (adapt content from `~/homelab/CLAUDE.md`):

```markdown
# [Service Name]

**URL:** `http://[subdomain].homelab`
**Profile:** [core / media / automation / search / budget / tasks]
**Image:** [docker image]

## What It Does

[1-2 sentences]

## Required Environment Variables

| Variable | Description | How to Get |
|----------|-------------|-----------|
| ... | ... | ... |

## First-Time Setup

1. Step-by-step manual instructions
2. No Claude Code references

## Configuration

Where config files live, what can be customized.

## Troubleshooting

Common issues and fixes.
```

Use the setup instructions from `~/homelab/CLAUDE.md` for DoIt, MacroNotion, Strava, Your Spotify, Boostcamp Sync, Huginn, and Vikunja. Sanitize any personal URLs or credentials in examples.

**Step 2: Commit**

```bash
git add docs/services/
git commit -m "docs: add individual service setup guides"
```

---

### Task 10: Documentation — Tailscale & DNS

**Files:**
- Create: `~/homelab_setup/docs/tailscale.md`
- Create: `~/homelab_setup/docs/dns-adblocking.md`

**Step 1: Write docs/tailscale.md**

Cover:
- What Tailscale is and why it's used (access homelab from anywhere)
- Installing Tailscale client on devices (phone, laptop, etc.)
- Creating an Auth Key (for automated setups)
- **DNS Configuration**: The critical step — set Tailscale DNS to use the homelab machine as a custom nameserver so `*.homelab` resolves
  - Tailscale Admin Console → DNS → Add nameserver → Custom → enter homelab IP, restrict to `homelab` domain
- Subnet routing (optional, for accessing other LAN devices)
- Testing: `ping glance.homelab` from a Tailscale-connected device

**Step 2: Write docs/dns-adblocking.md**

Cover:
- Option A: NextDNS — sign up, configure in Tailscale DNS settings
- Option B: Pi-hole — add a Pi-hole container to the compose file (provide compose snippet), configure CoreDNS to forward non-homelab queries to Pi-hole

**Step 3: Commit**

```bash
git add docs/tailscale.md docs/dns-adblocking.md
git commit -m "docs: add Tailscale setup and DNS ad-blocking guides"
```

---

### Task 11: GHCR Image Publishing — GitHub Actions

**Files:**
- Create GitHub Actions workflow in each custom app repo

This task requires working in the SOURCE repos, not in `homelab_setup`.

**Step 1: Create workflow template**

The standard workflow for each repo (`.github/workflows/docker-publish.yml`):

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest,enable={{is_default_branch}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

**Step 2: Apply to each repo**

Repos that need this workflow:
1. `standw7/DoIt` — needs TWO workflows: one for frontend (root Dockerfile), one for backend (`backend/Dockerfile`)
2. `standw7/MacroNotion` — needs TWO workflows: one for `frontend/Dockerfile`, one for `backend/Dockerfile`
3. `standw7/telegram-bot` (if separate repo) or the `telegram-bot/` dir in homelab
4. `standw7/fitness-dashboard` (if separate repo) or the `fitness-dashboard/` dir in homelab
5. `standw7/boostcamp-sync` (if separate repo) or the `boostcamp-sync/` dir in homelab

For apps that only exist as subdirs of `~/homelab` (telegram-bot, fitness-dashboard, boostcamp-sync), they need to be promoted to standalone repos first. Create new repos on GitHub, push the source code, then add the workflow.

**Step 3: Verify images publish**

After pushing workflows, check that images appear at `https://github.com/standw7?tab=packages`.

**Step 4: Commit (in homelab_setup)**

No files to commit in homelab_setup for this task — the work is in the source repos.

---

### Task 12: Create GitHub Repo & Push

**Step 1: Create the public GitHub repo**

```bash
cd ~/homelab_setup
gh repo create standw7/homelab_setup --public --source=. --push
```

**Step 2: Run gitleaks audit**

```bash
# Install gitleaks if not present
# Then scan the repo
gitleaks detect --source ~/homelab_setup --verbose
```

Expected: 0 findings. If any secrets found, fix and force-push to remove from history.

**Step 3: Verify the repo is clean**

Manually review on GitHub that no secrets, personal IPs, email addresses, or calendar URLs are visible in any file.

---

### Task 13: End-to-End Validation

**Step 1: Clone fresh and run setup**

```bash
cd /tmp
git clone https://github.com/standw7/homelab_setup.git test-homelab
cd test-homelab
# Verify .env.example has all needed vars
# Verify docker-compose.yml references correct GHCR images
# Verify Caddyfile has all routes
# Verify CoreDNS has placeholder IP
# Verify no PII in any file
```

**Step 2: Search for any remaining PII**

```bash
# Search for personal email, IPs, token prefixes, and location references
# Expected: zero matches for all searches
grep -ri "<personal-email>" .
grep -ri "<tailscale-ip>" .
grep -ri "<telegram-token-prefix>" .
grep -ri "<api-key-prefix>" .
grep -ri "<personal-location>" .
```

Expected: zero matches for all searches.

**Step 3: Validate compose file parses**

```bash
cp .env.example .env
# Fill in dummy values for required vars
docker compose config --quiet
```

Expected: no errors.

---

## Summary

| Task | Description | Estimated Complexity |
|------|-------------|---------------------|
| 1 | Repository scaffolding (.gitignore, CLAUDE.md) | Simple |
| 2 | .env.example with all variables | Medium |
| 3 | Sanitized infra configs (CoreDNS, Caddy) | Simple |
| 4 | Sanitized service configs (Glance, SearXNG, Strava) | Medium |
| 5 | Docker Compose file with profiles | Complex |
| 6 | Linux setup script | Complex |
| 7 | Windows setup script | Complex |
| 8 | README.md | Medium |
| 9 | Service documentation (14 guides) | Medium |
| 10 | Tailscale & DNS docs | Medium |
| 11 | GHCR image publishing (GitHub Actions) | Complex |
| 12 | GitHub repo creation & security audit | Simple |
| 13 | End-to-end validation | Medium |

**Dependencies:**
- Tasks 1-4 can run in parallel
- Task 5 depends on Tasks 2-4 (needs env vars and configs defined)
- Tasks 6-7 depend on Task 5 (need compose file to reference)
- Tasks 8-10 can run in parallel after Task 5
- Task 11 is independent (works on source repos)
- Task 12 depends on all other tasks
- Task 13 depends on Task 12
