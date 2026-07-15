# VALM Homelab

A self-hosted Proxmox platform for media, monitoring, backups, local AI, home automation, and privacy-sensitive personal workflow automation.

---

## What This Lab Runs

- **Automated media pipeline** — Sonarr/Radarr find and download content, Plex and Jellyfin serve it. All download traffic routes through a VPN kill switch (Gluetun + PIA).
- **Full observability** — Prometheus scrapes metrics from all services; Grafana dashboards surface them. Uptime Kuma alerts on outages.
- **Local AI** — Ollama on a Mac Mini M2 Pro runs open-source LLMs; Open-WebUI provides a chat frontend.
- **Home automation** — Home Assistant on a Pi 400 with Homebridge for HomeKit compatibility.
- **Network-level ad blocking** — Pi-hole as the primary DNS resolver for all VLANs.
- **Media transcoding** — Tdarr with a dedicated GPU worker handles batch transcoding jobs.

### Planned personal automation

- **Job Hunter + Hermes** — review-driven job discovery, tailored application preparation, tracking, and approved browser/API assistance.
- **Receipt Ingest** — private phone uploads, original-image preservation, OCR, location and merchant details, and Excel/Quicken-oriented exports.

These are roadmap items, not deployed services. See the [Personal Automation Roadmap](roadmap.md).

---

## Architecture at a Glance

```
Internet
   │
[UniFi Router]
   │
[Proxmox Host] ─── Primary hypervisor
   ├── Pi-hole (DNS)
   ├── Nginx Proxy Manager (reverse proxy)
   ├── Monitoring Stack (Prometheus, Grafana, Uptime Kuma)
   ├── Arr Sandbox (media management + VPN)
   ├── Proxmox Backup Server
   └── Media Server VM (Jellyfin, Plex, Tdarr)

[Mac Mini M2 Pro]  → Ollama / Open-WebUI / Syncthing
[Raspberry Pi 400] → Home Assistant / Homebridge
[Raspberry Pi Zero W2] → Pi-hole DNS
[Windows PC]       → Tdarr GPU transcoding worker
[NAS]              → Centralized media storage
```

---

## Navigation

- [Architecture](architecture/index.md) — hardware, network design, security model
- [Services](services/index.md) — every service explained
- [Operations](operations/index.md) — deployment and runbooks
- [Reference](reference/index.md) — service catalog and access guide
- [Personal Automation Roadmap](roadmap.md) — planned Job Hunter and Receipt Ingest systems
