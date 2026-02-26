# Beaver Habits

**URL:** `http://habits.homelab`
**Profile:** core (always running)
**Image:** `daya0576/beaverhabits:latest`

## What It Does

A simple habit tracker with a clean web interface. Track daily habits with streaks and completion history. Uses file-based storage (JSON files per user).

## Required Environment Variables

None required in `.env`. The Telegram bot uses these for integration:

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `BEAVER_HABITS_EMAIL` | Your Beaver Habits login email | Create account at `http://habits.homelab` |
| `BEAVER_HABITS_PASSWORD` | Your Beaver Habits login password | Same as above |

## First-Time Setup

1. Start the stack: `docker compose up -d`
2. Open `http://habits.homelab`
3. Create an account with email and password
4. Start adding habits to track
5. (Optional) Add your credentials to `.env` for Telegram bot integration

## Configuration

**Storage:** User data stored in `./beaver-habits/data/` (mounted from host)
**Storage mode:** `HABITS_STORAGE=USER_DISK` (JSON files per user)

## Troubleshooting

**Permission errors:** The container runs as root (`user: "0:0"`) to ensure write access to the data directory.

**Data not persisting:** Check that `./beaver-habits/data/` exists and is writable.
