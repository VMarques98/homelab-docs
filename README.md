# VALM Homelab

Documentation for the VALM self-hosted homelab: a Proxmox-based platform for media, monitoring, backups, local AI, home automation, and personal workflow automation.

> This repository documents architecture, configuration intent, runbooks, and planned systems. It is not a source of secrets or a replacement for Proxmox Backup Server (PBS).

## Current platform

- **Proxmox VE** — primary hypervisor for the core LXC containers and VMs.
- **Media automation** — Sonarr, Radarr, Prowlarr, qBittorrent, Bazarr, FlareSolverr, and Gluetun with VPN kill-switch protection.
- **Media serving** — Jellyfin and Plex, with Tdarr for batch transcoding.
- **Observability** — Prometheus, Grafana, Uptime Kuma, Homarr, Netdata, cAdvisor, and PVE Exporter.
- **Networking** — UniFi, Pi-hole, and Nginx Proxy Manager.
- **Local AI** — Ollama, Open-WebUI, and LiteLLM on the Mac Mini.
- **Home automation** — Home Assistant and Homebridge on the Raspberry Pi 400.
- **Backups and synchronization** — PBS to NAS plus Syncthing for selected working data.

## Planned personal automation

The roadmap includes two privacy-sensitive workflow systems:

1. **Job Hunter + Hermes** — extend the existing job-hunter workflow with Hermes-assisted discovery, tailoring, application tracking, and browser/API-assisted applications. Submission remains human-approved by default.
2. **Receipt Ingest** — accept daily receipt images uploaded from a phone, preserve the original image, extract receipt details and location, normalize the data, and write it to an Excel-compatible workbook and/or database for Quicken and budget management.

These are planned capabilities, not currently deployed services. See [Personal Automation Roadmap](docs/roadmap.md).

## Documentation

- [Homelab overview](docs/overview.md) — architecture and service relationships
- [Architecture](docs/architecture/index.md) — hardware, network, and security model
- [Services](docs/services/index.md) — service catalog
- [Operations](docs/operations/index.md) — deployment and runbooks
- [Reference](docs/reference/index.md) — addresses and service URLs
- [Potential projects](docs/potential-projects.md) — project catalog with blurbs and first milestones
- [Personal automation roadmap](docs/roadmap.md) — job hunter and receipt-ingest design

## Safe contribution workflow

1. Read the relevant note before changing a live service.
2. Keep passwords, API keys, tokens, private keys, and financial data out of Git and Obsidian.
3. Make the narrowest change possible and verify it from the live system.
4. Update the relevant Obsidian note and run the secret scanner.
5. Publish with `scripts/publish-update.sh "docs: describe the verified change"`.
6. Verify that the remote commit SHA matches the local commit before calling the documentation backed up.

PBS remains the recovery source of truth for recoverable homelab data and service state. GitHub is the source of truth for secret-free documentation and recovery intent.
