# Service URLs

All services are accessible via Nginx Proxy Manager using the homelab domain. DNS resolves through Pi-hole, which is required to be on the local network (or connected via UniFi Teleport for remote access).

!!! note
    Specific URLs and ports are not published here. Use Homarr (`home.lab.valm25.com`) as the central dashboard — it links to every service.

## Service Catalog

### Media

| Service | Purpose |
|---------|---------|
| Jellyfin | Primary media streaming |
| Plex | Secondary media streaming |
| Sonarr | TV show automation |
| Radarr | Movie automation |
| Prowlarr | Indexer aggregator |
| Bazarr | Subtitle downloader |
| qBittorrent | Download client (VPN-only) |
| Overseerr | Media request management |
| Tdarr | Batch transcoding |

### Monitoring

| Service | Purpose |
|---------|---------|
| Grafana | Metrics dashboards |
| Uptime Kuma | Uptime checks and alerting |
| Homarr | Service dashboard homepage |
| Netdata | Real-time system monitoring |
| Prometheus | Metrics database |

### Network

| Service | Purpose |
|---------|---------|
| Pi-hole | DNS ad blocking |
| NPM (admin) | Nginx Proxy Manager |
| WatchYourLAN | Device discovery |

### AI

| Service | Purpose |
|---------|---------|
| Open-WebUI | Local LLM chat interface |

### Automation & Infra

| Service | Purpose |
|---------|---------|
| Home Assistant | Home automation hub |
| Homebridge | HomeKit bridge |
| Syncthing | File sync (Proxmox + Mac Mini) |
| Proxmox UI | Hypervisor management |
| PBS | Proxmox Backup Server |
