# Actual Budget

**URL:** `http://budget.homelab` (HTTPS with internal TLS)
**Profile:** `budget`
**Image:** `actualbudget/actual-server:latest`

## What It Does

A self-hosted envelope-style budgeting app (similar to YNAB). Track income, expenses, and budget categories with a clean, fast interface.

## Required Environment Variables

None — Actual Budget works out of the box.

## First-Time Setup

1. Start with budget profile: `docker compose --profile budget up -d`
2. Open `http://budget.homelab`
3. Create a password on first visit
4. Start setting up your budget

## Configuration

**Data:** Stored in Docker volume `actual_data`

**Note:** Actual Budget uses internal TLS via Caddy, so it's accessed via HTTPS. Your browser may show a certificate warning — this is expected for self-signed certificates on a local network.

## Troubleshooting

**Certificate warning:** This is normal for internal TLS. Click "Advanced" → "Proceed" in your browser.

**Can't access:** Make sure the Caddy route is configured for `budget.homelab` in `caddy/Caddyfile`.
