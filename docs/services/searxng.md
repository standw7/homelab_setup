# SearXNG

**URL:** `http://search.homelab`
**Profile:** `search`
**Image:** `searxng/searxng:latest`

## What It Does

A privacy-respecting, self-hosted metasearch engine. Aggregates results from multiple search engines without tracking. Also provides a JSON API used by the Telegram bot for web searches.

## Required Environment Variables

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `SEARXNG_SECRET_KEY` | Instance secret key | Generate: `openssl rand -hex 32` |

## First-Time Setup

1. Add secret key to `.env`
2. Start with search profile: `docker compose --profile search up -d`
3. Open `http://search.homelab`
4. Start searching

## Configuration

**Config files:**
- `searxng/settings.yml` — search settings, instance name, enabled formats
- `searxng/limiter.toml` — rate limiting (disabled for local use)

**JSON API:** Enabled by default. The Telegram bot uses it at `http://searxng:8080`.

## Troubleshooting

**Search returns no results:** Some upstream search engines may block requests. Check which engines are enabled in `searxng/settings.yml`.

**Rate limiting issues:** Rate limiting is disabled by default in `searxng/limiter.toml` for local use.
