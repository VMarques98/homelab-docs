---
date: 2026-04-02
tags:
  - homelab
  - home-assistant
  - automation
  - smart-home
parent: "[[Homelab 3.0]]"
status: active
---

# Home Assistant

Running on Pi 400 (192.168.3.51) as a Docker container.

## Configuration

| Setting | Value |
|---------|-------|
| URL | http://192.168.3.51:8123 |
| Version | 2026.3.2 |
| Platform | Docker on Raspberry Pi 400 (aarch64) |
| Python | 3.14.2 |
| API Token | Long-lived token created for Claude automation |

## Integrations

| Integration | Purpose | Status |
|-------------|---------|--------|
| **UniFi Protect** | Cameras, doorbell, motion detection | Working |
| **August** | Yale front door lock (YRD410-BLE-619) | Working (cloud API) |
| **Apple TV** | Media player control | Working |
| **HomeKit** | Bridge HA entities to Apple Home | Working |
| **HomeKit Controller** | UniFi Protect cameras, Homebridge | Working |

## Devices

### Cameras (UniFi Protect)

| Camera | Model | Features |
|--------|-------|----------|
| G5 Pro | High-res outdoor | Person, vehicle, animal, license plate, smoke, CO, siren, baby cry, glass break detection |
| G5 Turret Ultra (x2) | Indoor/outdoor | Person, vehicle, animal, smoke, CO, baby cry, speaking detection |
| G6 Entry | Doorbell + NFC reader | Package detection, NFC access, speaker, chime |
| G4 Instant | Compact indoor | Person, vehicle, animal, license plate detection |

### Lock

| Device | Model | Connection | Status |
|--------|-------|------------|--------|
| Front Door | Yale YRD410-BLE-619 | August cloud via WiFi bridge (Apple TV) | Online, battery 54% |

- Bridge: Apple TV on Default LAN (192.168.0.171)
- Lock bridge WiFi: "As You Wish" network, 5GHz, signal -36 dBm
- HomeKit enabled but not paired to HA HomeKit Controller (cross-VLAN mDNS issue)
- Cloud API adds ~2-3s latency to lock/unlock commands

### Media

| Device | Entity |
|--------|--------|
| Victor's Apple TV | `media_player.victor_s_appletv` |

## Automations

### NFC Tap Unlocks Front Door

**Trigger:** Webhook `unifi-access-nfc-unlock` (fired by UniFi Protect Alarm Manager when NFC card tapped on G6 Entry)

**Action:** Unlock `lock.front_door` via August cloud API + send notification

**Flow:**
```
NFC card tap on G6 Entry
  → UniFi Protect Alarm Manager detects door unlock event
  → Fires webhook to http://192.168.3.51:8123/api/webhook/unifi-access-nfc-unlock
  → HA automation unlocks August lock
  → Notification sent
```

**Setup required in UniFi Protect:**
1. Settings → Alarm Manager → Create rule
2. Trigger: G6 Entry → Door Unlock event
3. Action: Webhook → Custom Webhook → `http://192.168.3.51:8123/api/webhook/unifi-access-nfc-unlock`

## Entity Summary

| Domain | Count | Key Entities |
|--------|-------|-------------|
| binary_sensor | 129 | Camera motion/detection sensors |
| switch | 111 | Camera detection toggles, overlay settings, privacy modes |
| sensor | 35 | Battery, operator, firmware sensors |
| camera | 10 | 5 cameras × 2 streams (standard + high-res) |
| light | 7 | Camera night vision, floodlight, chime volume |
| lock | 1 | `lock.front_door` (August/Yale) |
| media_player | 3 | Apple TV, doorbell speaker, G4 Instant speaker |

## Known Issues

### August Bridge Went Offline (March 19 - April 2)
- Bridge showed "offline" in August cloud for 2 weeks
- WiFi was connected (good signal on IOT VLAN)
- Fixed by reloading the integration in HA
- Root cause: likely cloud session expiry or PubNub subscription timeout

### Cross-VLAN mDNS for HomeKit
- HA (192.168.3.51, Homelab zone) can't discover HomeKit devices on Default LAN/IOT VLAN
- mDNS broadcasts don't cross VLANs by default
- Would need mDNS forwarding enabled in UniFi or manual HomeKit pairing
- Current workaround: use August cloud API (works but slower)

### Lock Speed
- NFC tap → unlock takes ~3-5 seconds due to cloud round-trip
- Could be improved by pairing lock to HA via HomeKit Controller (local, no cloud)
- Requires mDNS cross-VLAN fix or moving HA to same VLAN as lock bridge
