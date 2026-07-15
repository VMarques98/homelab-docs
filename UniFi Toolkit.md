---
date: 2026-04-01
tags:
  - homelab
  - unifi
  - networking
  - security
parent: "[[Homelab 3.0]]"
status: active
---

# UniFi Toolkit

Network monitoring and security dashboard for the UniFi Dream Machine SE.

## Configuration

| Setting | Value |
|---------|-------|
| Container | `ghcr.io/crosstalk-solutions/unifi-toolkit:latest` |
| Host | LXC 105 (monitoring) at 192.168.3.21 |
| URL | http://192.168.3.21:8000 |
| Mode | Local (no auth, LAN only) |
| Data | `/opt/unifi-toolkit/data/` |

## Tools

### Dashboard
Real-time gateway status — model, firmware, uptime, CPU/RAM, WAN status, connected clients.

### Threat Watch
IDS/IPS event monitoring from the Dream Machine SE.
- Real-time threat events
- Top attackers and targets
- Threat categorization
- Ignore rules for noise filtering
- Webhook alerts (Slack, Discord)

**Requires:** IPS enabled on the UDMSE (Settings → Security → Threat Management → ON, set to IPS mode).

### WiFi Stalker
Track specific devices across the network.
- Device tracking by MAC address
- Roaming detection between APs
- Signal strength, radio band, SSID
- Block/unblock devices
- Webhook alerts for connect/disconnect/roam events

### Network Pulse
Real-time network health dashboard.
- Device counts by type
- Clients by band/SSID charts
- Top bandwidth consumers
- Clickable AP detail views
- WebSocket live updates

## Setup Notes

- Deployed via Docker on the existing [[Monitoring Stack]] LXC
- Required `chown 1000:1000 ./data` for container write permissions
- Controller URL set to the UDMSE's local IP
- IPS was disabled by default on the UDMSE — enabled during setup
