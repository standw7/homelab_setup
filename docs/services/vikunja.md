# Vikunja

**URL:** `http://vikunja.homelab`
**Profile:** `tasks`
**Image:** `vikunja/vikunja:latest`

## What It Does

A self-hosted task management and to-do list application. Supports projects, labels, priorities, due dates, and an API used by the Telegram bot for task commands.

## Required Environment Variables

None in `.env` — but the Telegram bot needs a Vikunja API token for integration:

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `VIKUNJA_TOKEN` | API token for Telegram bot | Create in Vikunja UI (see below) |

## First-Time Setup

1. Start with tasks profile: `docker compose --profile tasks up -d`
2. Open `http://vikunja.homelab`
3. Create an account (registration is enabled by default)
4. (Optional) Create an API token for Telegram bot integration:
   - Go to Settings → API Tokens
   - Create a new token
   - Add to `.env`: `VIKUNJA_TOKEN=your-token`
   - Restart: `docker compose restart telegram-bot`

## Configuration

**Data:**
- Database: `./vikunja/db/` (SQLite)
- Files: `./vikunja/files/`

**Registration:** Enabled by default. Set `VIKUNJA_SERVICE_ENABLEREGISTRATION=false` in `docker-compose.yml` to disable after creating your account.

## Troubleshooting

**Can't create account:** Check that registration is enabled in the environment variables.

**Telegram bot can't create tasks:** Verify the `VIKUNJA_TOKEN` is set correctly and the Vikunja container is running.
