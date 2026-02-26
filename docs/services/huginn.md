# Huginn

**URL:** `http://automate.homelab`
**Profile:** `automation`
**Image:** `ghcr.io/huginn/huginn`

## What It Does

A self-hosted automation platform (like IFTTT or Zapier). Create agents that monitor websites, send notifications, process data, and automate workflows. Uses MySQL for storage.

## Required Environment Variables

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `HUGINN_DB_ROOT_PASSWORD` | MySQL root password | Generate: `openssl rand -hex 16` |
| `HUGINN_DB_PASSWORD` | MySQL user password | Generate: `openssl rand -hex 16` |
| `HUGINN_APP_SECRET_TOKEN` | App secret token | Generate: `openssl rand -hex 64` |

## First-Time Setup

1. Add credentials to `.env`
2. Start with automation profile: `docker compose --profile automation up -d`
3. Open `http://automate.homelab`
4. Log in with default credentials: `admin` / `password`
5. **Change the default password immediately**

## Configuration

**Data:** MySQL data in Docker volume `huginn_db`
**Timezone:** Mountain Time (US & Canada) — change in `docker-compose.yml` if needed

## Troubleshooting

**Can't log in:** Default credentials are `admin` / `password`. If you've forgotten your password, check the Huginn docs for reset instructions.

**Database connection error:** Make sure `huginn-db` is running:
```bash
docker compose --profile automation logs huginn-db
```
