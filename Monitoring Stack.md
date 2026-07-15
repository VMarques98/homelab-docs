---
date: 2026-04-01
tags:
  - homelab
  - monitoring
  - prometheus
  - grafana
parent: "[[Homelab 3.0]]"
status: active
---

# Monitoring Stack

All monitoring services run in LXC 105 (192.168.3.21).

## Services

| Service | Port | URL |
|---------|------|-----|
| Prometheus | 9090 | (internal) |
| Grafana | 3000 | grafana.lab.valm25.com |
| Uptime Kuma | 3001 | uptime.lab.valm25.com |
| Homarr | 7575 | home.lab.valm25.com |
| Node Exporter | 9100 | (internal) |
| cAdvisor | 8080 | (internal) |
| PVE Exporter | 9221 | (internal) |

## Prometheus Scrape Targets

| Job | Target | Metrics |
|-----|--------|---------|
| prometheus | localhost:9090 | Self-monitoring |
| proxmox-node | 192.168.3.10:9100 | PVE host node-exporter |
| monitoring-node | node-exporter:9100 | LXC 105 node-exporter |
| cadvisor-monitoring | cadvisor:8080 | Docker container metrics |
| pve | pve-exporter:9221 | Proxmox VE API metrics |

PVE API token: `root@pam!prometheus`

## Grafana Dashboards

- Node Exporter Full (ID 1860)
- Docker & System Monitoring (ID 893)
- Proxmox via Prometheus (ID 10347)

## Uptime Kuma (24 monitors)

All services monitored with 60s interval, 3 retries. Includes:
- All [[Arr Stack]] services
- [[Tdarr AV1 Transcoding]] server
- [[Proxmox Backup Server]] (TCP port 8007)
- [[Syncthing Emulation Sync]] nodes (PVE Hub, Mac Mini, Steam Deck)
- Proxmox, Pi-hole, NPM, Jellyfin, Plex, Home Assistant, Homebridge, Open-WebUI

## Discord Alerting

| Channel | Service | Webhook |
|---------|---------|---------|
| `#grafana-alerts` | Grafana (5 alert rules) | CPU >90%, RAM >90%, Disk >85%, Scrape down, Guest stopped |
| `#threat-alerts` | UniFi Toolkit Threat Watch | IDS/IPS events |
| `#service-status` | Uptime Kuma (24 monitors) | Service up/down notifications |
| `#media-requests` | [[Requestrr]] bot | Movie/TV request notifications |
| `#media-updates` | Jellyfin (future) | New media added |

### Grafana Alert Rules

| Rule | Condition | Duration |
|------|-----------|----------|
| High CPU Usage - PVE Host | CPU >90% | 5 min | NoData=OK |
| High RAM Usage - PVE Host | RAM >90% | 5 min | NoData=OK |
| Disk Space Low - PVE Host | Root disk >85% | 10 min | NoData=OK |
| Scrape Target Down | Any Prometheus target unreachable | 2 min | NoData=Alerting |
| PVE Guest Not Running | VM/LXC not in running state | 3 min | NoData=Alerting |

**Alert policy:** Repeat interval 24h (was 4h — caused alert flood during April 2026 outage). CPU/RAM/Disk alerts set to OK on NoData so they don't fire when host is offline for maintenance.

## Watchtower (Auto-Updates)

Deployed on all 4 Docker hosts. Checks daily at 4:00 AM ET, auto-updates containers with old image cleanup.

| Host | Container |
|------|-----------|
| LXC 104 (npm) | watchtower |
| LXC 105 (monitoring) | watchtower |
| LXC 110 (arr-sandbox) | watchtower |
| VM 101 (media-server) | watchtower |

## Homarr Dashboard

Board "default" with 4 sections: Arr Stack, Media, Infrastructure, Home & AI. 18 app tiles including UniFi Toolkit. Data stored in SQLite.
