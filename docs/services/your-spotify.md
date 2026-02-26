# Your Spotify

**URL:** `http://spotify.homelab`
**Profile:** `media`
**Image:** `yooooomi/your_spotify_client` (frontend), `yooooomi/your_spotify_server` (API), `mongo:6` (database)

## What It Does

A self-hosted Spotify listening analytics dashboard. Tracks your listening history and generates statistics, top artists, top songs, and listening patterns.

## Required Environment Variables

| Variable | Description | How to Get |
|----------|-------------|-----------|
| `YOUR_SPOTIFY_PUBLIC` | Spotify App Client ID | [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) |
| `YOUR_SPOTIFY_SECRET` | Spotify App Client Secret | Same as above |

## First-Time Setup

1. Create a Spotify app:
   - Go to [https://developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
   - Create a new app
   - Add redirect URI: `http://spotify-api.homelab/oauth/spotify/callback`
   - Copy Client ID and Client Secret
2. Add credentials to `.env`:
   ```
   YOUR_SPOTIFY_PUBLIC=your-client-id
   YOUR_SPOTIFY_SECRET=your-client-secret
   ```
3. Start with media profile: `docker compose --profile media up -d`
4. Open `http://spotify.homelab`
5. Log in with your Spotify account

## Configuration

**Data:** MongoDB stored in Docker volume `your_spotify_db`
**Cookie validity:** 1 year (365 days)

## Troubleshooting

**OAuth error:** Verify the redirect URI in your Spotify app settings matches exactly: `http://spotify-api.homelab/oauth/spotify/callback`

**No listening data:** Your Spotify starts tracking from the moment you connect. Historical data import is limited by the Spotify API.
