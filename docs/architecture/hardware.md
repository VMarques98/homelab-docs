# Hardware

## Node Overview

| Hostname | Role |
|----------|------|
| `pve` (hurric4ne) | Primary Proxmox hypervisor |
| `storm` (Windows PC) | Tdarr GPU transcoding worker |
| `mac-llm` (Mac Mini) | LLM inference + Syncthing sync |
| `pi-home` (Pi 400) | Home Assistant + Homebridge |
| `pi-dns` (Pi Zero W2) | Pi-hole DNS |
| NAS | Centralized SMB/NFS media storage |
| Steam Deck | EmuDeck + Syncthing |

---

## Primary Proxmox Host (pve)

**Role:** Main hypervisor running all LXCs and VMs.

| Spec | Detail |
|------|--------|
| CPU | AMD Ryzen 9 5900X (12 cores / 24 threads) |
| RAM | 32 GB DDR4 |
| GPU | Intel Arc A310 (AV1 hardware transcoding via QSV) |
| OS | Proxmox VE 9.1.1 |

The Intel Arc A310 is passed through to the Media Server VM for hardware-accelerated transcoding in Plex and Jellyfin.

---

## Mac Mini M2 Pro (mac-llm)

**Role:** LLM inference, Syncthing sync node.

| Spec | Detail |
|------|--------|
| CPU | Apple M2 Pro |
| RAM | 16 GB unified memory |

Runs Ollama natively for local LLM inference. The unified memory architecture makes it significantly more efficient for inference than x86 alternatives.

---

## Windows PC (storm)

**Role:** GPU-accelerated Tdarr transcoding worker.

| Spec | Detail |
|------|--------|
| GPU | NVIDIA RTX 5090 (NVENC AV1) |
| RAM | 32 GB |

Receives transcoding jobs from the Tdarr server. Handles batch H.264 → H.265/AV1 conversions for the media library.

---

## Raspberry Pi 400 (pi-home)

**Role:** Home Assistant + Homebridge.

| Spec | Detail |
|------|--------|
| Board | Raspberry Pi 400 |
| OS | Home Assistant OS |

Runs Home Assistant as the primary home automation hub. Homebridge bridges non-HomeKit devices into Apple HomeKit.

---

## Raspberry Pi Zero W2 (pi-dns)

**Role:** Pi-hole network-wide DNS ad blocker.

| Spec | Detail |
|------|--------|
| Board | Raspberry Pi Zero W2 |

Configured as the primary DNS resolver for all VLANs via UniFi DHCP.

---

## NAS

**Role:** Centralized media storage.

| Spec | Detail |
|------|--------|
| Protocol | SMB and NFS |
| Shares | Movies, TV, music, books |

Hosts all media files. Volumes are mounted into the LXCs and VMs that need storage access.
