# Deployment

## Deployment Order

Provision in this order to satisfy dependencies:

1. **init-secrets** — run interactively on the Proxmox node; sets up credentials in the secrets directory
2. **Pi-hole** — bring up DNS first so all subsequent containers resolve correctly
3. **Nginx Proxy Manager** — reverse proxy must be up before any service is exposed
4. **Monitoring Stack** — Prometheus, Grafana, Uptime Kuma, Homarr
5. **Arr Sandbox** — Gluetun, then *arr services and qBittorrent (VPN must be up before downloaders start)
6. **Media Server** — Jellyfin, Plex, Tdarr
7. **Proxmox Backup Server** — configure backup jobs after all VMs/LXCs are running
8. **Mac Mini services** — Ollama, Open-WebUI, Syncthing (run independently)
9. **Pi 400 services** — Home Assistant, Homebridge (run independently)

## Provisioning Script

The main deployment script (`homelab3.sh`) automates LXC/VM creation, package installation, and Docker Compose stack deployment on the Proxmox host.

**Usage:**
```bash
# On the Proxmox host
bash homelab3.sh <target>
```

Targets correspond to individual LXC/VM names. Run `bash homelab3.sh help` for a list.

## Secrets Management

Secrets are initialized once via `init-secrets` and stored in a protected directory on the Proxmox host. They are never embedded in compose files or documentation.

Services that need credentials receive them via environment variables sourced from the secrets directory at container start.

## Updates

The `upgrade.sh` script pulls the latest container images and recreates any containers with updated images:

```bash
bash upgrade.sh
```
