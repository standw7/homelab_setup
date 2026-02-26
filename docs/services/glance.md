# Glance

**URL:** `http://home.homelab` / `http://glance.homelab`
**Profile:** core (always running)
**Image:** `glanceapp/glance`

## What It Does

A customizable dashboard that aggregates RSS feeds, Hacker News, Reddit, weather, and bookmarks into a single page. Serves as the homelab landing page.

## Required Environment Variables

None — Glance uses a YAML config file.

## First-Time Setup

1. Glance starts automatically with the core stack
2. Open `http://home.homelab` to view the dashboard
3. Customize the config at `glance/config/glance.yml`

## Configuration

**Config file:** `glance/config/glance.yml`

Customize:
- **Weather location:** Change `location:` under the weather widget
- **RSS feeds:** Add/remove feeds in the RSS widget sections
- **Bookmarks:** Edit the bookmarks widget to add your homelab links
- **Theme:** Adjust colors in the `theme:` section
- **Layout:** Add columns and widgets (see [Glance docs](https://github.com/glanceapp/glance))

After editing, restart:
```bash
docker compose restart glance
```

## Troubleshooting

**Dashboard is blank:** Check the config file for YAML syntax errors:
```bash
docker compose logs glance
```

**Weather not loading:** Glance uses a free weather API — no key required. Make sure the location format is correct: `City, State, Country`.
