# Services

All services running in the homelab, organized by function.

- [Media Stack](media.md) — Plex, Jellyfin, Sonarr, Radarr, Gluetun VPN
- [Monitoring](monitoring.md) — Prometheus, Grafana, Uptime Kuma, Netdata
- [Networking](networking.md) — Pi-hole, Nginx Proxy Manager, WatchYourLAN
- [AI](ai.md) — Ollama, Open-WebUI, LiteLLM
- [Automation](automation.md) — Home Assistant, Homebridge, Syncthing, Tdarr

## Service-page contract

Every service page identifies what each component owns, its dependencies, expected healthy result, verification path, failure boundary, and recovery caution. Live credentials, volatile addresses, and unverified deployment assumptions remain outside this public documentation.

Personal automation projects are tracked separately in the [Potential Projects](../potential-projects.md) catalog and [Personal Automation Roadmap](../roadmap.md); they are not deployed homelab services yet.
