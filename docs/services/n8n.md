# n8n

**URL:** `http://flows.homelab`
**Profile:** `automation`
**Image:** `docker.n8n.io/n8nio/n8n:latest`

## What It Does

A workflow automation platform with a visual editor. Create automated workflows with triggers, conditions, and integrations. Used for scheduled tasks like morning briefings.

## Required Environment Variables

None — n8n works out of the box.

## First-Time Setup

1. Start with automation profile: `docker compose --profile automation up -d`
2. Open `http://flows.homelab`
3. Create an account on first visit
4. Start building workflows

## Configuration

**Data:** Stored in Docker volume `n8n_data`
**AI features:** Enabled by default (`N8N_AI_ENABLED=true`)
**Diagnostics:** Disabled (`N8N_DIAGNOSTICS_ENABLED=false`)

## Troubleshooting

**Workflows not triggering:** Check that the workflow is activated (toggle switch in the editor).

**Container restarting:** Check logs:
```bash
docker compose --profile automation logs n8n
```
