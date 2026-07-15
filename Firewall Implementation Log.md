---
date: 2026-04-07
tags:
  - homelab
  - security
  - networking
  - unifi
parent: "[[Homelab 3.0]]"
status: accepted-risk
---

# Firewall Implementation Log

## Current State: Accept Risk — No VLAN Isolation

After multiple attempts, **VLAN isolation is not implementable** on the current UDMSE firmware (Network 9.4+). All VLANs can communicate freely. This is an accepted risk for a home network.

### What's In Place

- **10 ALLOW policies** via UniFi API — document intended access but don't enforce (no block rules)
- **PVE built-in firewall: DISABLED** — caused lockout during April 2026 incident
- **Gluetun VPN kill switch** — torrent traffic is secure regardless of VLAN isolation
- **Service authentication** — Syncthing, Tdarr, UniFi Toolkit all have passwords set

### What's NOT Enforced

- No inter-VLAN blocking between Default LAN, Homelab, IOT, Media/Torrent
- Any device on any VLAN can reach any service on any other VLAN
- Management interfaces (PVE 8006, PBS 8007, Grafana 3000) accessible from all VLANs

### Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Torrent IP leaking | **None** | Gluetun VPN + Docker kill switch, verified working |
| DNS leaking | **None** | Gluetun DOT (DNS over TLS), doesn't use local DNS |
| Compromised LAN device → PVE | **Low** | WiFi password protected, service auth enabled |
| Guest on WiFi → admin interfaces | **Low** | Guest WiFi is separate SSID (though not isolated) |
| Internet-facing exposure | **None** | No port forwarding, all services LAN-only |

## Approaches Attempted and Why They Failed

### Attempt 1: Internal→Internal Block Rules (April 2)
Created network-to-network BLOCK rules within the Internal zone with IP-specific ALLOW rules above them.

**Result:** ALLOW rules with IP_ADDRESS source type do not override BLOCK rules with NETWORK type, even when the ALLOW has a lower index (higher priority). UniFi appears to evaluate NETWORK-match blocks before IP-match allows.

**Additional issue:** "Block Homelab→Default" also blocked return traffic for allowed connections, breaking everything.

### Attempt 2: Custom Zones (April 2 & April 7)
Created "Homelab Services" and "Media Torrent" custom zones. Moving a network to a custom zone automatically creates system-defined "Block All Traffic" rules between the custom zone and Internal.

**Result:** Custom user-defined ALLOW policies (index 10000) placed above system Block All (index 2147483647) are **ignored**. The zone-level block overrides IP-specific allows regardless of ordering. Tested with propagation delays up to 75 seconds — the allow never takes effect.

### Attempt 3: Catch-All Empty Block (April 2)
Created a BLOCK rule with no source/destination traffic filter (empty = match everything in Internal zone).

**Result:** Blocked ALL traffic including internet-bound traffic. Too broad — caused complete network outage.

### Not Attempted
- **Network isolation toggle** (`isolationEnabled: true` per network) — uses a different mechanism (switch-level ACLs) that may work but requires ACL-capable switches
- **PVE built-in firewall** — works but caused lockout when PVE became unreachable (April 5 incident)

## 10 Allow Policies (Documentation Only)

These exist in UniFi but don't enforce anything without corresponding block rules.

| # | Name | Source | Destination | Ports |
|---|------|--------|-------------|-------|
| 1 | MacBook admin all homelab | 192.168.0.203 | Homelab VLAN | All |
| 2 | LAN streams Plex Jellyfin | Default LAN | 192.168.3.22 | 8096, 32400 |
| 3 | Apple TV streams media only | 192.168.0.171 | 192.168.3.22 | 8096, 32400 |
| 4 | Admin access PVE PBS | .244, .30 | .10, .31 | 8006, 8007, 22 |
| 5 | Admin access monitoring | .244, .30 | .21 | 3000, 3001, 8000 |
| 6 | Syncthing save sync | .161, .244, .30 | .10 | 8384, 22000 |
| 7 | Tdarr Windows node | .244 | .22 | 8265, 8266 |
| 8 | Deck streams media | .161 | .22 | 8096, 32400 |
| 9 | Homelab mounts NAS | Homelab VLAN | .204 | 445 |
| 10 | Arr stack mounts NAS | Media/Torrent VLAN | .204 | 445 |

## Torrent Security Verification (April 7)

Verified independently of VLAN isolation:

```
qBittorrent public IP: 212.56.54.46 (PIA VPN — NOT real IP)
DNS: 127.0.0.1 (Gluetun internal DOT resolver)
Kill switch: Docker network_mode:service:gluetun (container has zero network if VPN drops)
Gluetun firewall: FIREWALL=on
Gluetun DNS: DOT=on
```

**Conclusion:** Torrent privacy is fully protected by the Docker/Gluetun stack. VLAN isolation would add defense-in-depth for LAN security but is not required for torrent privacy.

## UniFi API Reference

| Item | Value |
|------|-------|
| Base URL | `https://192.168.0.1/proxy/network/integration/v1/sites/{siteId}/` |
| Auth | `X-API-Key` header |
| Site ID | `88f7af54-98f8-306a-a1c7-c9349722b1f6` |
| Internal Zone | `e9324f72-ffd8-4cc2-9a47-08c4e1f9878d` |

## Future Options

1. **Wait for firmware update** — UniFi may fix zone policy precedence in a future release
2. **Add ACL-capable switches** — enables Object Manager's "Secure → Local" feature and switch-level isolation
3. **Use VLANs as logical separation only** — current state, VLANs exist for organization but don't enforce access control
4. **Separate physical networks** — nuclear option, not practical for homelab
