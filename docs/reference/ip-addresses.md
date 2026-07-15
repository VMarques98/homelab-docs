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

## Address ownership and verification

| Record type | Source of truth | Check when |
|---|---|---|
| DHCP/static assignment | UniFi controller | A host moves, is replaced, or cannot be reached. |
| Local hostname | Pi-hole local DNS | A proxy URL fails or a new service is added. |
| Guest interface/bridge | Proxmox network inventory | A VM/LXC loses connectivity or VLAN placement changes. |
| NAS mount endpoint | Proxmox mount configuration and NAS | Media import, playback, or backup access fails. |

Never copy a private address map into this public documentation page. Record only the zone, purpose, and verification source.
