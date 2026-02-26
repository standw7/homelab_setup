# DNS & Ad-Blocking

Your homelab uses CoreDNS to resolve `*.homelab` domains. You can extend this with network-wide ad-blocking.

## Option A: NextDNS (Recommended)

NextDNS is a cloud-based DNS service with ad-blocking, tracker blocking, and analytics. Free tier includes 300,000 queries/month.

### Setup

1. Sign up at [https://nextdns.io](https://nextdns.io)
2. Create a configuration and note your NextDNS ID
3. In the [Tailscale Admin Console](https://login.tailscale.com/admin/dns):
   - Go to **DNS** → **Nameservers**
   - Add NextDNS as a global nameserver
   - Keep your homelab's CoreDNS as a restricted nameserver for the `homelab` domain

This way:
- `*.homelab` queries → CoreDNS (your homelab)
- All other queries → NextDNS (with ad-blocking)

## Option B: Pi-hole (Self-Hosted)

Run Pi-hole as a Docker container alongside your homelab for self-hosted ad-blocking.

### Add Pi-hole to Docker Compose

Add this to your `docker-compose.yml`:

```yaml
  # --- Pi-hole: Network-wide ad blocker ---
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    profiles:
      - adblock
    ports:
      - "8053:80"    # Web UI (avoid conflict with Caddy on 80)
    environment:
      - TZ=${TZ:-America/Denver}
      - WEBPASSWORD=changeme
    volumes:
      - pihole_data:/etc/pihole
      - pihole_dnsmasq:/etc/dnsmasq.d
```

Add to the `volumes:` section:
```yaml
  pihole_data:
  pihole_dnsmasq:
```

### Configure CoreDNS to Forward to Pi-hole

Update `coredns/Corefile` to forward non-homelab queries to Pi-hole:

```
homelab:53 {
    template IN A {
        answer "{{ .Name }} 60 IN A YOUR_TAILSCALE_IP"
    }
    log
}

.:53 {
    forward . pihole:53
    log
}
```

### Add Caddy Route

Add to `caddy/Caddyfile`:
```
http://pihole.homelab {
    reverse_proxy pihole:80
}
```

### Start Pi-hole

```bash
docker compose --profile adblock up -d
```

Access the Pi-hole admin panel at `http://pihole.homelab` (default password: `changeme`).

## Option C: Tailscale + NextDNS (Simplest)

The simplest approach is to use Tailscale's built-in NextDNS integration:

1. In the [Tailscale Admin Console](https://login.tailscale.com/admin/dns)
2. Under **DNS** → **Nameservers**, select **NextDNS**
3. Follow the prompts to connect your NextDNS account

This applies ad-blocking to all Tailscale-connected devices automatically, with no containers to manage.
