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
