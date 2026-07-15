---
date: 2026-04-01
tags:
  - homelab
  - infrastructure
  - networking
parent: "[[Homelab 3.0]]"
---

# Infrastructure Overview

## Network Architecture

| VLAN | Subnet | Purpose |
|------|--------|---------|
| VLAN 6 (Homelab) | 192.168.3.0/24 | Proxmox, LXCs, VMs, monitoring, NPM, Pi-hole |
| VLAN 7 (Media/Torrent) | 192.168.7.0/24 | Arr sandbox external-facing interface |
| Default LAN | 192.168.0.0/24 | NAS, Steam Deck, legacy devices |

### PVE Bridge Configuration

| Bridge | VLAN | Ports | Purpose |
|--------|------|-------|---------|
| vmbr0 | 6 (native/untagged) | nic1, LXC/VM veths | Homelab 192.168.3.0/24 |
| vmbr1 | 7 (tagged via nic1.7) | nic1.7, LXC/VM veths | Media/Torrent 192.168.7.0/24 |

Persisted in `/etc/network/interfaces`. vmbr0 carries untagged VLAN 6 traffic on nic1. vmbr1 uses the VLAN 7 subinterface (nic1.7) for tagged media/torrent traffic.

### Firewall Status

**VLAN isolation is NOT enforced.** All 7 networks are in the Internal zone with Allow All. Multiple approaches to implement inter-VLAN blocking failed due to UniFi firmware limitations (IP-specific allows don't override network/zone-level blocks). See [[Firewall Implementation Log]].

**What IS protected:**
- Torrent traffic: Gluetun VPN + Docker kill switch (independent of firewall)
- Service auth: Syncthing, Tdarr, UniFi Toolkit have passwords
- PVE firewall: Disabled (caused lockout — see [[PVE Boot Recovery]])
- 10 allow policies exist as documentation of intended access

**Remote Access:** UniFi WifiMan Teleport (no Tailscale/WireGuard needed)

## Hardware

| Node | Role | IP | Specs |
|------|------|----|-------|
| pve (hurric4ne) | Proxmox host | 192.168.3.10 | Ryzen 9 5900X, 32GB, Arc A310 (GPU blacklisted for console — see [[PVE Boot Recovery]]) |
| Windows PC (storm) | Tdarr remote worker | 192.168.0.244 | RTX 5090, 32GB |
| Mac Mini (mac-llm) | Ollama, Syncthing, Delta bridge | 192.168.3.30 | Apple Silicon |
| Steam Deck | Emulation, Syncthing | 192.168.0.161 (DHCP reserved) | EmuDeck + RetroArch |
| NAS (UNAS) | SMB storage | 192.168.0.204 | Media, Games, Backups |
| Pi 400 | Home Assistant + Homebridge | 192.168.3.51 | |
| Pi Zero W2 | Pi-hole DNS | 192.168.3.50 | |

## Hermes Agent Main-Node Migration

The Mac mini (`mac-llm`, `192.168.3.30`, user `vicm2mini`) is the staged target
for the Hermes Agent main node. Hermes v0.18.2 is installed and the iCloud
Obsidian vault is available at the same `VALM25` path, with the homelab notes
kept in sync.

The non-secret Hermes state has been staged from the current Mac: configuration,
skills, memories, scheduled jobs, sessions, and supporting databases. The
current Mac's live gateway remains active during testing. OAuth/API credential
files, Discord/platform credentials, pairing state, and gateway runtime state
were intentionally not copied yet to avoid duplicate gateway sessions.

Final cutover requires an explicit gateway switch: authenticate the Mac mini,
install/enable its gateway service, verify Discord and cron operation, then
stop the current Mac gateway.

## VMs & LXCs

| ID | Type | Name | IP | Services |
|----|------|------|----|----------|
| 100 | LXC | pihole | 192.168.3.50 | Pi-hole DNS |
| 104 | LXC | npm | 192.168.3.20 | Nginx Proxy Manager |
| 105 | LXC | monitoring | 192.168.3.21 | Prometheus, Grafana, Uptime Kuma, Homarr |
| 106 | LXC | pbs | 192.168.3.31 | [[Proxmox Backup Server]] |
| 110 | LXC | arr-sandbox | 192.168.3.25 | [[Arr Stack]] (Gluetun VPN) |
| 101 | VM | media-server | 192.168.3.22 | Jellyfin, Plex, [[Tdarr AV1 Transcoding]] |

## DNS & Reverse Proxy

All services accessed via `*.valm25.com` through NPM (LXC 104). Pi-hole (LXC 100) has local DNS host records for all subdomains pointing to 192.168.3.20 (NPM). Added April 11 via Pi-hole v6 API (`/api/config/dns/hosts`). The Pi-hole admin credential is stored only in the local homelab credential store and is never committed to this repository.
