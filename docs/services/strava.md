# Strava Statistics

**URL:** `http://strava.homelab`
**Profile:** `media`
**Image:** `robiningelbrecht/statistics-for-strava:latest`

## What It Does

A self-hosted Strava analytics dashboard. Imports your Strava activities and generates detailed statistics, charts, and insights. Uses FrankenPHP (Caddy+PHP) with SQLite storage.

## Required Environment Variables

In `.env`:

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `STRAVA_CLIENT_ID` | Strava API app ID | [Strava API Settings](https://www.strava.com/settings/api) |
| `STRAVA_CLIENT_SECRET` | Strava API secret | Same as above |
| `STRAVA_REFRESH_TOKEN` | OAuth refresh token | Generated after OAuth flow |

In `strava/.env` (separate file):

| Variable | Description |
|----------|-------------|
| `APP_SECRET` | App secret (any random string) |
| `STRAVA_CLIENT_ID` | Same as above |
| `STRAVA_CLIENT_SECRET` | Same as above |
| `STRAVA_REFRESH_TOKEN` | Same as above |

## First-Time Setup

1. Create a Strava API application:
   - Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
   - Authorization Callback Domain: `strava.homelab`
2. Copy `strava/.env.example` to `strava/.env` and fill in credentials
3. Add Strava credentials to the main `.env` file too (for Telegram bot integration)
4. Start with media profile: `docker compose --profile media up -d`
5. Open `http://strava.homelab` → complete the Strava OAuth flow
6. Run initial import: `docker exec strava bin/console app:strava:import-data`

## Configuration

**Config:** `strava/config/config.yaml` — controls units, locale, import settings, cron schedule
**Data:** SQLite database + files in `strava/storage/`
**Cron:** Imports new activities every 6 hours by default

## Troubleshooting

**OAuth flow fails:** Verify the Authorization Callback Domain is set to `strava.homelab` in your Strava API settings.

**No data after import:** Check the daemon logs:
```bash
docker compose logs strava-daemon
```
