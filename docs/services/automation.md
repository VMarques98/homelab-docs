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

## Component breakdown

| Component | Role | Dependencies | Verification |
|---|---|---|---|
| Home Assistant | Local device state, automations, and integrations | Pi 400, device integrations, storage | Check core health and execute a safe test automation. |
| Homebridge | HomeKit bridge for unsupported devices | Homebridge host and plugins | Confirm accessories and plugin logs after updates. |
| Syncthing | Peer-to-peer sync for selected working data | Paired nodes, folder permissions, conflict handling | Confirm both nodes are connected and no unresolved conflicts exist. |
| Tdarr | Batch media transformation | NAS paths, server, worker GPU | Run a small test job and verify output before bulk changes. |

## Automation safety

Automations should be idempotent, observable, and reversible. Document trigger, action, dependency, rate limit, notification, and manual recovery. Do not sync secrets or financial data through a general-purpose folder without an explicit encrypted-storage design.

## Planned integrations

The [Potential Projects](../potential-projects.md) page records future Hermes, receipt, job-application, and workflow ideas. They remain separate from deployed services until their data boundaries, approval gates, and backup paths are implemented.
