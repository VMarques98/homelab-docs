---
date: 2026-04-01
tags:
  - homelab
  - todo
parent: "[[Homelab 3.0]]"
---

# Homelab TODO

## Homelab Improvements

- [x] Add Jellyfin to NPM (`jellyfin.lab.valm25.com`) — already existed
- [x] Add UniFi Toolkit to NPM (`toolkit.lab.valm25.com`) — ID 17
- [x] Add Jellyfin + UniFi Toolkit to Homarr dashboard
- [x] Grafana alerts to Discord `#grafana-alerts` (CPU, RAM, disk, scrape down, guest stopped)
- [x] Watchtower — auto-update Docker containers daily at 4AM (LXC 104, 105, 110 + VM 101)

## Security & Networking

- [x] Configure UniFi Toolkit webhooks to Discord `#threat-alerts`
- [x] Uptime Kuma notifications to Discord `#service-status`
- [x] ~~Firewall~~ — VLAN isolation not possible on current UDMSE firmware. Accepted risk. 10 allow policies documented. Torrent security verified via Gluetun VPN. See [[Firewall Implementation Log]]

## Media

- [x] Requestrr — Discord bot for media requests (LXC 105, port 4545, `/movie` and `/tv` commands)

## Home Automation

- [x] Home Assistant — NFC tap unlock automation created (webhook: `unifi-access-nfc-unlock`). August bridge offline — automation will work when bridge reconnects to cloud.

## Workflow Automation

- [ ] n8n for homelab automation workflows
