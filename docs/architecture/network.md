# Network

## VLAN Design

VLANs are managed by a UniFi router and switch. Each VLAN isolates a group of services with its own firewall policy.

| VLAN | Name | Purpose |
|------|------|---------|
| Homelab | Management VLAN | Proxmox host, all LXCs and VMs, monitoring, reverse proxy, Pi-hole |
| Media/Torrent | Egress VLAN | Arr sandbox external-facing interface — VPN traffic only |
| Default LAN | Legacy | NAS, Mac Mini, workstation |

## LXC and VM Topology

```
[UniFi Router / Switch]
       │
[Proxmox Host]
       │
       ├── Homelab VLAN
       │     ├── Pi-hole (DNS)
       │     ├── Nginx Proxy Manager
       │     ├── Monitoring Stack (Prometheus, Grafana, Uptime Kuma)
       │     ├── Proxmox Backup Server
       │     └── Media Server VM (Jellyfin, Plex)
       │
       └── Arr Sandbox (dual-homed)
             ├── eth0 → Homelab VLAN (management, reverse proxy)
             └── eth1 → Media/Torrent VLAN (VPN egress only)
```

## VPN Sandbox Design

The Arr Sandbox LXC has two network interfaces. The second interface connects exclusively to the Media/Torrent VLAN, which is the egress path for the Gluetun VPN tunnel. All download traffic from the *arr stack and qBittorrent is forced through Gluetun. If the VPN drops, the kill switch blocks all outbound traffic from the container — no traffic leaks to the home IP.

```
Sonarr / Radarr / Prowlarr / qBittorrent / Bazarr
     └── all traffic → Gluetun (kill switch enabled)
                           └── PIA VPN tunnel → Internet
```

## DNS

- **Primary resolver:** Pi-hole (filters ads/trackers for all VLANs)
- **Local domain:** wildcard domain pointing to Nginx Proxy Manager
- **Upstream:** Cloudflare or configured public resolver

## Reverse Proxy

Nginx Proxy Manager handles all inbound HTTP(S) traffic. SSL certificates auto-renew via Let's Encrypt DNS challenge through Cloudflare.

## Remote Access

UniFi WifiMan **Teleport** provides secure remote access to the LAN. No separate VPN client software is required.

## NAS Connectivity

The NAS lives on the default LAN. Proxmox mounts its SMB shares and bind-mounts storage volumes into the LXCs and VMs that need media access.

## Traffic-path breakdown

| Path | Expected route | Verification |
|---|---|---|
| Client → published service | Client → Pi-hole DNS → NPM → target service | Resolve the hostname locally and test the proxy endpoint. |
| Arr download → Internet | Arr service → Gluetun → PIA tunnel → Internet | Check the public egress IP from inside qBittorrent/Gluetun. |
| Media service → library | Jellyfin/Plex/Tdarr → mounted NAS share | Check the mount and sample-read the exact media path. |
| Remote operator → homelab | MacBook → UniFi Teleport → internal DNS/services | Verify Teleport session, DNS resolution, and least-privilege access. |
| Metrics → dashboards | Exporters → Prometheus → Grafana/Uptime Kuma | Check scrape targets, dashboard freshness, and alerts. |

## Firewall and dependency notes

The current VLAN model is the intended isolation boundary, but the exact policy set must be verified in UniFi before changes. Do not assume a VLAN is secure because it exists: test allowed management, DNS, proxy, NAS, monitoring, and VPN paths and confirm denied direct torrent egress.

A network change is complete only when DNS, proxy access, VPN egress, NAS access, monitoring, and remote access are each tested. Record exceptions and accepted risks in the firewall notes.
