# Handoff — homelab_setup

**Date:** 2026-02-26
**Status:** Implementation plan approved, ready for execution via parallel session

## What's Done

- Design doc approved and committed: `docs/plans/2026-02-25-homelab-setup-design.md`
- Implementation plan written (13 tasks): `docs/plans/2026-02-25-homelab-setup-implementation.md`
- GitHub repo created: `standw7/homelab_setup` (public)
- 2 commits pushed to `origin/master`

## What Needs to Happen

Execute the 13-task implementation plan using `superpowers:executing-plans`. The plan is fully self-contained — read it and execute task by task.

**Task summary:**
1. Repository scaffolding (.gitignore, CLAUDE.md)
2. .env.example with all variables
3. Sanitized infra configs (CoreDNS, Caddy)
4. Sanitized service configs (Glance, SearXNG, Strava)
5. Docker Compose file with profiles (core + optional)
6. Linux setup script (full bootstrap)
7. Windows PowerShell setup script
8. README.md (master guide)
9. Service documentation (14 individual guides)
10. Tailscale & DNS ad-blocking docs
11. GHCR image publishing (GitHub Actions in source repos)
12. GitHub repo push & gitleaks audit
13. End-to-end validation (PII grep, compose syntax check)

## Key Context

- Source homelab: `~/homelab` — audit configs from here, NEVER copy secrets
- Custom apps use pre-built GHCR images (ghcr.io/standw7/*)
- Docker Compose profiles for modularity (core runs by default, optional via --profile)
- Core services: Glance, DoIt, MacroNotion, Telegram Bot, Beaver Habits, Fitness Dashboard + infra (CoreDNS, Caddy, Portainer)
- All secrets via .env, zero hardcoded values
- Support both Linux (bash) and Windows (PowerShell) setup
- Documentation written for non-technical users WITHOUT Claude Code

## Critical: PII to Sanitize from Source Homelab

The source `~/homelab/docker-compose.yml` has hardcoded secrets:
- Telegram token, Vikunja token, Beaver Habits email/password
- Strava client secret and refresh token
- Google Calendar iCal URLs
- Tailscale IP `100.111.132.107`
- Email `stanleywessman@gmail.com`
- Huginn APP_SECRET_TOKEN (hardcoded hash)
- Spotify token redirect in Caddyfile

ALL of these must become `${ENV_VAR}` references in the new repo.

## Execution Instructions

Open a new Claude Code session in `~/homelab_setup` and run:
```
Use superpowers:executing-plans to execute docs/plans/2026-02-25-homelab-setup-implementation.md
```
