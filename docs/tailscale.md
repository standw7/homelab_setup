# Tailscale Setup

Tailscale is a zero-config VPN that lets you securely access your homelab from anywhere — your phone, laptop, or another computer — without exposing any ports to the internet.

## Why Tailscale?

- **Secure**: All traffic is encrypted end-to-end
- **No port forwarding**: No need to open router ports
- **Works anywhere**: Access your homelab from coffee shops, work, or on mobile data
- **Free tier**: Generous free plan for personal use

## Installing Tailscale

The setup script installs Tailscale automatically. For manual installation:

### Linux

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Windows

```powershell
winget install Tailscale.Tailscale
```
Then open Tailscale from the Start menu and sign in.

### macOS

Download from the [Mac App Store](https://apps.apple.com/app/tailscale/id1475387142) or:
```bash
brew install tailscale
```

### iOS / Android

Install from the App Store or Google Play Store, then sign in with the same account.

## DNS Configuration (Critical Step)

After starting the homelab, you need to tell Tailscale to route `*.homelab` domains through your CoreDNS server.

1. Open the [Tailscale Admin Console](https://login.tailscale.com/admin/dns)
2. Go to **DNS** → **Nameservers**
3. Click **Add nameserver** → **Custom**
4. Enter your homelab machine's Tailscale IP (run `tailscale ip -4` on the machine)
5. Check **Restrict to domain**
6. Enter `homelab` as the domain
7. Click **Save**

This tells all your Tailscale-connected devices to resolve `*.homelab` domains using your CoreDNS container.

## Verifying DNS

From any Tailscale-connected device:

```bash
# Check DNS resolution
dig @<tailscale-ip> home.homelab

# Or simply ping
ping home.homelab

# Or open in a browser
open http://home.homelab
```

If DNS isn't resolving:
1. Verify CoreDNS is running: `docker ps | grep coredns`
2. Verify the Corefile has your Tailscale IP (not the placeholder)
3. Check Tailscale DNS settings in the admin console
4. Try disconnecting and reconnecting Tailscale on the client device

## Auth Keys (Optional)

For automated setups (e.g., deploying on a headless server), create an auth key:

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Choose **Reusable** if you want to use it multiple times
4. Use the key: `sudo tailscale up --authkey=tskey-auth-...`

## Subnet Routing (Optional)

If you want to access other devices on your local network through Tailscale:

1. On the homelab machine:
   ```bash
   sudo tailscale up --advertise-routes=192.168.1.0/24
   ```
2. In the Tailscale admin console, approve the subnet route
3. On client devices, accept the route:
   ```bash
   sudo tailscale up --accept-routes
   ```

## Multiple Devices

Install Tailscale on all devices you want to access the homelab from:
- Laptop (macOS/Windows/Linux)
- Phone (iOS/Android)
- Work computer
- Tablet

All devices on the same Tailscale account can reach `*.homelab` URLs once DNS is configured.
