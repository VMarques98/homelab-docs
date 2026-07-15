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

## Node-by-node operating breakdown

| Node | Depends on | Primary data or workload | Failure impact | Recovery/check |
|---|---|---|---|---|
| `pve` | UniFi network, local storage, guest configuration | Proxmox guests and host networking | Core services unavailable | Verify boot, bridges, guest inventory, storage, and PBS connectivity. |
| `storm` | LAN reachability and Tdarr server | GPU transcoding jobs | Transcoding queue pauses; originals remain available | Verify worker registration and run a small test job. |
| `mac-llm` | LAN and local disk | Ollama models, Open-WebUI, Syncthing | Local AI and sync unavailable | Check model service, UI, and sync folder state. |
| `pi-home` | LAN and Home Assistant storage | Home automation and HomeKit bridge | Automations/accessories unavailable | Check Home Assistant health and Homebridge plugin status. |
| `pi-dns` | Network power and Pi-hole state | DNS and filtering | Name resolution degrades across VLANs | Check DNS resolution from each zone and UniFi DHCP assignments. |
| NAS | LAN, storage health, mounts | Media and shared data | Media imports/streaming and some backups fail | Check NAS health, share access, mount state, and recent PBS jobs. |

## Inventory gaps

The page intentionally omits credentials and volatile values. Confirm exact RAM, storage capacity, guest IDs, mount paths, switch ports, and backup schedules from live inventory before using this page as a change plan.
