# Overview

## Goals

1. **Self-hosted media** — automatically discover, download, and serve TV and movies with zero manual effort
2. **Privacy-first** — all download traffic routes through a VPN with a kill switch
3. **Observability** — full metrics and alerting across every service
4. **Local AI** — run open-source LLMs without sending data to cloud providers
5. **Home automation** — control smart devices locally via Home Assistant

## Design Principles

### VM vs LXC Strategy

Internet-facing services run in VMs for kernel-level isolation. Internal-only services run in LXC containers for efficiency.

| Factor | VM | LXC |
|--------|----|-----|
| Kernel isolation | Own kernel — a container escape does not compromise the host | Shared kernel with host |
| Overhead | Higher | Minimal |
| GPU passthrough | Full PCI passthrough | cgroup device rules |
| Use cases | Media server, VPN gateway | *arr stack, monitoring, Pi-hole |

### Network Segmentation

Services are grouped into isolated VLANs with firewall rules. Internet-facing and download services are separated from internal management traffic. The VPN-connected services run in a dedicated sandbox that prevents any direct traffic from leaving without tunneling through the VPN.

### Single Ingress Point

All HTTP(S) traffic enters through one reverse proxy (Nginx Proxy Manager). No services are directly exposed to the internet.

### Credential Isolation

No passwords or API keys appear in configuration files or documentation. Secrets are managed separately from deployable code.

## Deployment Platform

| Component | Technology |
|-----------|-----------|
| Hypervisor | Proxmox VE (single node) |
| Internal services | LXC containers with Docker Compose |
| Internet-facing services | KVM VMs |
| Reverse proxy | Nginx Proxy Manager |
| DNS | Pi-hole (local resolver + ad blocker) |
| Remote access | UniFi WifiMan Teleport |
| Backups | Proxmox Backup Server (local NAS target) |

## Operational breakdown

| Concern | Documented decision |
|---|---|
| Placement | Proxmox is the core platform; LXCs provide efficient internal services and VMs provide stronger isolation/GPU passthrough. |
| Ingress | Nginx Proxy Manager is the intended HTTP(S) entry point; services should not be directly exposed. |
| Egress | The Arr Sandbox has a dedicated torrent VLAN and Gluetun kill switch. |
| Data | Media lives on the NAS; service state belongs in guest backups and service-specific recovery notes. |
| Secrets | Values stay in protected local stores; documentation contains only destinations and procedures. |
| Verification | Confirm service health, network path, backup coverage, and monitoring after changes. |

## Change boundaries

- Treat VLAN/firewall changes, guest destruction, volume deletion, broad restarts, and credential changes as disruptive.
- Perform read-only discovery first, back up configuration, make the narrowest change, and update the relevant note and Git-backed documentation.
- Current capacity, IP assignments, and live service state must be verified from Proxmox/UniFi rather than inferred from this static page.
