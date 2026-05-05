# IP Addresses

!!! note
    Internal IP addresses are not published in this documentation. Refer to the private IP reference document stored in the repository (not tracked in git) or the Pi-hole local DNS records for the current address map.

## Where to Find Internal IPs

- **Pi-hole admin** → Local DNS Records — lists all registered hostnames
- **Homarr dashboard** — links to all services (resolves via local DNS)
- **Proxmox web UI** → Nodes → Network — shows bridge and interface configuration
- **UniFi controller** → Clients list — shows DHCP leases and static assignments

## Network Zones

The homelab uses three network zones:

| Zone | Purpose |
|------|---------|
| Homelab VLAN | Proxmox, LXCs, VMs, monitoring, reverse proxy, Pi-hole |
| Media/Torrent VLAN | Arr sandbox VPN egress interface |
| Default LAN | NAS, Mac Mini, legacy devices |

## Reserved Addresses

The NAS has a permanently reserved static IP on the default LAN. Do not reassign it — all media mount points on the Proxmox host depend on it.
