# Automation

## Home Assistant

Primary home automation hub running on a Raspberry Pi 400.

All automations run locally — no cloud dependency. Key integrations:

- Homebridge (HomeKit bridge)
- UniFi integration (presence detection, device tracking)
- Energy monitoring

---

## Homebridge

Bridges non-HomeKit devices and services into Apple HomeKit. Runs alongside Home Assistant on the Pi 400.

Key plugins:
- `homebridge-unifi` — expose UniFi devices to HomeKit

---

## Syncthing

Peer-to-peer file synchronization across homelab nodes. Used to keep config files, scripts, and working documents in sync without a cloud intermediary.

**Nodes:** Proxmox host, Mac Mini

---

## Tdarr

Batch media transcoding pipeline.

The Tdarr server manages the job queue; a dedicated Windows PC with an RTX 5090 connects as a remote worker node.

**Current pipeline:**
- Input: H.264 files in the media library
- Output: H.265 (HEVC) at equivalent visual quality — ~40–60% smaller file size
- Encoder: NVENC on RTX 5090 (hardware-accelerated)
