# Fitness Dashboard

**URL:** `http://fitness.homelab`
**Profile:** core (always running)
**Image:** `ghcr.io/standw7/fitness-dashboard:latest`

## What It Does

A personal fitness and reading tracker dashboard. Displays exercise logs and reading progress in a clean web interface. Shares data with the Telegram bot.

## Required Environment Variables

None — uses shared data from the Telegram bot volume.

## First-Time Setup

1. Start the stack: `docker compose up -d`
2. Open `http://fitness.homelab`
3. Data is shared with the Telegram bot via the `telegram_bot_data` volume

## Configuration

**Data:** Shares the `telegram_bot_data` Docker volume with the Telegram bot

## Troubleshooting

**No data showing:** The fitness dashboard reads data from the Telegram bot's storage. Make sure the Telegram bot is running and has data.

**Container not starting:** Check logs:
```bash
docker compose logs fitness-dashboard
```
