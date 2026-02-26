# Install Tailscale for Windows
$ErrorActionPreference = "Stop"

if (Get-Command tailscale -ErrorAction SilentlyContinue) {
    Write-Host "Tailscale is already installed."
    try {
        $ip = tailscale ip -4 2>$null
        if ($ip) {
            Write-Host "Tailscale IP: $ip"
        } else {
            Write-Host "Tailscale is installed but not connected."
            Write-Host "Please open Tailscale and sign in."
        }
    } catch {
        Write-Host "Tailscale is installed but not connected."
    }
    return
}

Write-Host "Installing Tailscale..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install -e --id Tailscale.Tailscale --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "ERROR: winget not found."
    Write-Host "Please install Tailscale manually from:"
    Write-Host "  https://tailscale.com/download/windows"
    exit 1
}

Write-Host ""
Write-Host "Tailscale installed."
Write-Host "Please open Tailscale from the Start menu and sign in."
Write-Host "Then re-run this setup script."
