---
date: 2026-04-01
tags:
  - project
  - homelab
  - infrastructure
status: active
---

# Homelab 3.0

Self-hosted infrastructure running on Proxmox, serving media, monitoring, backups, and emulation sync across all devices.

## Quick Links

| Service | URL |
|---------|-----|
| Proxmox | https://192.168.3.10:8006 |
| Grafana | grafana.lab.valm25.com |
| Uptime Kuma | uptime.lab.valm25.com |
| Homarr | home.lab.valm25.com |
| Tdarr | tdarr.lab.valm25.com |
| PBS | https://192.168.3.31:8007 |
| Sonarr | sonarr.lab.valm25.com |
| Radarr | radarr.lab.valm25.com |
| Jellyfin | http://192.168.3.22:8096 |
| UniFi Toolkit | http://192.168.3.21:8000 |

## Subsystems

- [[Infrastructure Overview]] — Network, hardware, VMs/LXCs
- [[Tdarr AV1 Transcoding]] — Multi-node AV1 encoding with Arc A310 + RTX 5090
- [[Proxmox Backup Server]] — Automated backups to NAS
- [[Syncthing Emulation Sync]] — Cross-device save sync (Steam Deck, iPhone, Mac Mini)
- [[Arr Stack]] — Sonarr, Radarr, Prowlarr, qBittorrent behind VPN
- [[Arr Import & I/O Overload]] — Jul 2026 incident: Sonarr import fix (path mapping + anime absolute numbering), Readarr I/O overload
- [[Monitoring Stack]] — Prometheus, Grafana, Uptime Kuma (24 monitors)
- [[Jellyfin]] — Media server with QSV hardware transcoding
- [[UniFi Toolkit]] — Network monitoring, Threat Watch, WiFi Stalker
- [[Firewall Implementation Log]] — Zone-based VLAN isolation via UniFi API
- [[Firewall Audit]] — Zone reference, policy guide, security recommendations
- [[Home Assistant]] — NFC unlock automation, UniFi Protect cameras, August lock
- [[Requestrr]] — Discord bot for media requests (/movie, /tv)
- [[PVE Boot Recovery]] — April 2026 incident: GPU blacklist, NIC naming, firewall fixes

## Recovery and documentation source of truth

- **PBS:** backup system for recoverable homelab data and service state.
- **GitHub:** `VMarques98/homelab-docs` stores architecture, runbooks, configuration intent, and this Obsidian documentation snapshot. It does not store secrets.
- **Credentials:** local macOS Keychain items are applied with `scripts/bootstrap-credentials.sh`; the script is dry-run by default and sends values over SSH through stdin.
- **After every verified homelab change:** update the relevant note, run `scripts/publish-update.sh "docs: describe the verified change"`, and verify that the remote SHA matches before considering the documentation backed up.
