---
date: 2026-04-01
tags:
  - homelab
  - security
  - networking
parent: "[[Homelab 3.0]]"
---

# Firewall Audit (2026-04-01)

## Network Zones

| Zone | Subnet | Purpose |
|------|--------|---------|
| Homelab VLAN | 192.168.3.0/24 | Proxmox, LXCs, VMs, monitoring |
| Media VLAN | 192.168.7.0/24 | Arr stack external (isolated bridge) |
| Default LAN | 192.168.0.0/24 | NAS, Steam Deck, Mac Mini, Windows PC |

## PVE Firewall Status

**iptables: ALL ACCEPT** — no rules on PVE host. All firewall enforcement is on the **UniFi gateway** (Dream Machine SE).

## Cross-VLAN Connectivity (from PVE → Default LAN)

| Target | Port | Status | Expected |
|--------|------|--------|----------|
| NAS (192.168.0.204) | 445 SMB | OPEN | Needed for media, backups |
| Windows PC (192.168.0.244) | 22 SSH | CLOSED | OK — Tdarr uses 8266 not SSH from PVE |
| Steam Deck (192.168.0.161) | 22 SSH | CLOSED | Deck was offline during test |
| Mac Mini (192.168.3.30) | 22 SSH | OPEN | On homelab VLAN, expected |

## Homelab VLAN Internal Services

| Service | IP:Port | Status | Notes |
|---------|---------|--------|-------|
| PVE Web | 192.168.3.10:8006 | OPEN | Admin UI |
| Syncthing UI | 192.168.3.10:8384 | OPEN | No auth (local mode) |
| Syncthing Sync | 192.168.3.10:22000 | OPEN | Data transfer |
| NPM Admin | 192.168.3.20:81 | OPEN | Behind auth |
| Grafana | 192.168.3.21:3000 | OPEN | Behind auth |
| Uptime Kuma | 192.168.3.21:3001 | OPEN | Behind auth |
| UniFi Toolkit | 192.168.3.21:8000 | OPEN | No auth (local mode) |
| Jellyfin | 192.168.3.22:8096 | OPEN | Behind auth |
| Tdarr | 192.168.3.22:8265 | OPEN | No auth |
| Tdarr Node | 192.168.3.22:8266 | OPEN | Node comm |
| Sonarr | 192.168.3.25:8989 | OPEN | Behind auth |
| PBS | 192.168.3.31:8007 | OPEN | Behind auth |

## Findings & Recommendations

### Good

- NAS SMB is reachable from homelab VLAN (needed for media + backups)
- All homelab services accessible within the VLAN
- Arr stack uses Gluetun VPN with kill switch — traffic isolated
- Media VLAN (vmbr1) is an isolated bridge with no external routing

### Concerns

1. **No PVE firewall rules** — iptables is completely open. If a device on the homelab VLAN is compromised, it has unrestricted access to all other services. Consider enabling PVE's built-in firewall for LXC/VM level isolation.

2. **Syncthing UI (8384) has no auth** — anyone on the VLAN can reconfigure sync folders. Consider:
   - Set a GUI password in Syncthing settings
   - Or restrict to localhost and use SSH tunnel

3. **Tdarr UI (8265) has no auth** — accessible to anyone on the VLAN. Lower risk since it only manages transcoding.

4. **UniFi Toolkit (8000) has no auth** — local mode, shows network details. Consider switching to production mode with auth if concerned.

5. **Cross-VLAN rules on UniFi** — currently allows broad access between 192.168.3.0/24 ↔ 192.168.0.0/24 (set up for Tdarr Windows node). Consider tightening to specific IP:port pairs only.

### Action Items

- [x] Set Syncthing GUI passwords on all nodes (admin/Changeme123)
- [ ] Review UniFi firewall rules — tighten cross-VLAN to specific ports
- [ ] Consider enabling PVE firewall for LXC/VM isolation
- [ ] Verify default LAN → homelab VLAN access is limited (test from Deck when online)

---

## UniFi Zone-Based Firewall (Network 9.0+)

UniFi 9.0+ uses **zone-based firewalling**. The old LAN In/LAN Out/LAN Local terminology is replaced by **zones** and **policies** between them.

### Built-in Zones

| Zone | Purpose | Default Behavior |
|------|---------|-----------------|
| **Internal** | Trusted LAN traffic (VLANs, wired clients) | Allow All to Internal, Gateway, VPN, Hotspot, DMZ |
| **External** | Internet (WAN) traffic | Policies control in/out |
| **Gateway** | Traffic TO the UDM itself (DHCP, DNS, management UI) | Allowed from Internal and VPN |
| **VPN** | Remote VPN users, site-to-site tunnels | Allow All to Internal, Gateway |
| **Hotspot** | Guest WiFi networks | Allow Return Traffic only to Internal/VPN; Block All to Hotspot/DMZ |
| **DMZ** | Public-facing servers | Allow Return Traffic only; Block All to Hotspot/DMZ |

### Default Zone Matrix

| Source → Dest | Internal | External | Gateway | VPN | Hotspot | DMZ |
|---|---|---|---|---|---|---|
| **Internal** | Allow All | Policies | Allow All | Allow All | Allow All | Allow All |
| **External** | Policies | Policies | Policies | Policies | Policies | Policies |
| **Gateway** | Allow All | Allow All | — | Allow All | Allow All | Allow All |
| **VPN** | Allow All | Policies | Allow All | Allow All | Allow All | Allow All |
| **Hotspot** | Return Only | Policies | Policies | Return Only | Block All | Block All |
| **DMZ** | Return Only | Policies | Policies | Return Only | Block All | Block All |

**Key insight:** Internal → Internal is "Allow All" by default. This means **all your VLANs can talk to each other freely**. To isolate them, you need to add policies to the **Internal → Internal** cell.

### How Policies Work

- Policies are created between **source zone** and **destination zone**
- Custom policies take precedence over built-in policies
- Custom policies are processed **top to bottom, first match wins**
- Use **Reorder** in the Policy Table to adjust priority
- When you create an Allow policy, you can check **"Auto Allow Return Traffic"** — this creates a companion policy for the response packets so you don't need bidirectional rules
- **Within the same zone** (Internal → Internal) is where inter-VLAN rules go

---

## Implementation Guide

### Step 1: Create Objects

**Settings → Policy Engine → Objects → Create**

The Object Manager UI has 4 panels:
1. **Left panel** — Name the object, choose **Devices** or **Networks** tab, select which networks/devices it applies to
2. **Secure panel** — Internet access (Blocklist/Allowlist/No Internet) + Local access (Inherit/Blocklist/Allowlist/Quarantine)
3. **Route panel** — Policy-based routing (send through specific WAN/VPN)
4. **QoS panel** — Bandwidth Limit/Prioritize

**You must check at least one of Secure/Route/QoS.** For our firewall setup, check **Secure** on every object.

---

#### Object 1: `RFC1918`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `RFC1918` |
| **Left panel** | Tab: Networks | Check: `Default`, `Homelab`, `Media/Torrent` (all your networks) |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything (don't restrict internet) |
| | Local | **Inherit** (we'll control this via manual policies in Step 3) |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> This object represents all private networks. It's used as source AND destination in the block-all catch-all policy.

---

#### Object 2: `Trusted Admins`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `Trusted Admins` |
| **Left panel** | Tab: Devices | Search and select: Windows PC (192.168.0.244) + Mac Mini (192.168.3.30) |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything |
| | Local | **Allowlist** → Check **IP Address** → Enter: `192.168.3.10`, `192.168.3.31`, `192.168.3.21`, `192.168.3.22` |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> These are your admin machines. Local allowlist limits them to PVE (.10), PBS (.31), Monitoring (.21), and Media Server (.22). They can reach all management ports on those IPs.

---

#### Object 3: `Steam Deck`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `Steam Deck` |
| **Left panel** | Tab: Devices | Search and select: Steam Deck (192.168.0.161) |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything |
| | Local | **Allowlist** → Check **IP Address** → Enter: `192.168.3.22`, `192.168.3.10` |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> Steam Deck can reach Media Server (.22) for streaming and PVE (.10) for Syncthing. Nothing else on homelab VLAN.

---

#### Object 4: `Homelab Net`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `Homelab Net` |
| **Left panel** | Tab: Networks | Check: `Homelab` only |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything |
| | Local | **Allowlist** → Check **IP Address** → Enter: `192.168.0.204` |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> Homelab VLAN can reach NAS (.204) for SMB mounts. Internal homelab-to-homelab traffic is same-VLAN and doesn't go through the gateway, so it's not affected.

---

#### Object 5: `Media Torrent Net`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `Media Torrent Net` |
| **Left panel** | Tab: Networks | Check: `Media/Torrent` only |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything |
| | Local | **Allowlist** → Check **IP Address** → Enter: `192.168.0.204` |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> Media/Torrent VLAN can only reach NAS (.204) on the local network. VPN traffic goes out to the internet, which is allowed.

---

#### Object 6: `Default LAN Clients`

| Panel | Setting | Value |
|---|---|---|
| **Name** | | `Default LAN Clients` |
| **Left panel** | Tab: Networks | Check: `Default` only |
| **Secure** ✓ | Internet | Allowlist → ✓ Everything |
| | Local | **Allowlist** → Check **IP Address** → Enter: `192.168.3.22` |
| **Route** | | Unchecked |
| **QoS** | | Unchecked |

> Default LAN devices can only reach Media Server (.22) for Plex/Jellyfin streaming. No access to PVE, PBS, or monitoring unless they're also in the Trusted Admins object (which takes precedence).

---

> **How Object Manager precedence works:**
> - Device-level objects (Trusted Admins, Steam Deck) override Network-level objects (Default LAN Clients)
> - So your Windows PC and Mac Mini are in both `Trusted Admins` (device) AND `Default LAN Clients` (network) — the device-level `Trusted Admins` allowlist wins, giving them access to management IPs
> - A random phone on Default LAN only matches `Default LAN Clients` and can only reach the media server
>
> **What about ports?** The Object Manager's Local allowlist works at the IP level, not port level. For port-level control, you still need manual policies in Step 3. The objects create a first layer of IP-based access control, then the manual policies in Step 3 refine it with specific ports.

---

> **Action types reference:**
>
> | Panel | Option | What it does |
> |-------|--------|-------------|
> | **Secure → Internet** | Blocklist | Block specific apps/domains/IPs from internet |
> | | Allowlist | Only allow specific apps/domains/IPs to internet |
> | | No Internet | Completely block internet access |
> | **Secure → Local** | Inherit | Use parent/default behavior (Allow All for Internal zone) |
> | | Blocklist | Block specific local destinations (Device/Network/MAC/IP) |
> | | Allowlist | Only allow specific local destinations |
> | | Quarantine | Block ALL local and internet access |
> | **Route** | — | Send traffic through specific WAN or VPN tunnel. Kill Switch option drops traffic if the tunnel goes down. |
> | **QoS** | Limit | Cap download/upload speed |
> | | Prioritize | Higher priority queue for this traffic |
> | | Prioritize and Limit | Both — priority queue with speed cap |
>
> Schedule options (Always/Daily/Weekly/One Time/Custom) apply to all actions.

### Step 2: Delete Existing Broad Rules

**Settings → Zones** (or **Settings → Policy Table**)

Find and delete any existing "Allow All" rules you created between Default LAN and Homelab VLAN. Leave built-in (locked) rules alone.

### Step 3: Create Policies

**Settings → Zones → Click the Internal→Internal cell → Create Policy**

Or: **Settings → Policy Table → Create New Policy**

Create in this order. For each policy:
- Source Zone: **Internal**
- Destination Zone: **Internal**
- Check **"Auto Allow Return Traffic"** on all Allow rules

**Policy 1: LAN → Media Streaming**

| Field | Value |
|---|---|
| Name | `LAN streams Plex Jellyfin` |
| Source Zone | Internal |
| Destination Zone | Internal |
| Source | Network: Default (or IP: `Default LAN`) |
| Destination | IP: `Media Servers` object |
| Destination Port | Port: `Media Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 2: Trusted Admins → PVE/PBS**

| Field | Value |
|---|---|
| Name | `Admin access PVE PBS` |
| Source | IP: `Trusted Admins` object |
| Destination | IP: `Proxmox Mgmt` object |
| Destination Port | Port: `Mgmt Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 3: Trusted Admins → Monitoring**

| Field | Value |
|---|---|
| Name | `Admin access monitoring` |
| Source | IP: `Trusted Admins` object |
| Destination | IP: `Monitoring` object |
| Destination Port | Port: `Monitoring Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 4: Homelab → NAS**

| Field | Value |
|---|---|
| Name | `Homelab mounts NAS` |
| Source | IP: `Homelab Net` object |
| Destination | IP: `NAS` object |
| Destination Port | Port: `NAS SMB` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 5: Syncthing Sync**

| Field | Value |
|---|---|
| Name | `Syncthing save sync` |
| Source | IP: `Steam Deck` object AND `Trusted Admins` object |
| Destination | IP: `Homelab Net` object |
| Destination Port | Port: `Syncthing Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

Note: If the UI doesn't support multiple IP objects in one source, create two separate policies — one for Steam Deck, one for Trusted Admins.

**Policy 6: Tdarr Windows Node**

| Field | Value |
|---|---|
| Name | `Tdarr Windows node` |
| Source | IP: `Windows Tdarr` object |
| Destination | IP: `Media Servers` object |
| Destination Port | Port: `Tdarr Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 7: Steam Deck → Media**

| Field | Value |
|---|---|
| Name | `Deck streams media` |
| Source | IP: `Steam Deck` object |
| Destination | IP: `Media Servers` object |
| Destination Port | Port: `Media Ports` object |
| Protocol | TCP |
| Action | **Allow** ✓ Auto Allow Return Traffic |

**Policy 8: Block All Inter-VLAN (MUST BE LAST)**

| Field | Value |
|---|---|
| Name | `Block all cross-VLAN` |
| Source | IP: `RFC1918` object |
| Destination | IP: `RFC1918` object |
| Protocol | All |
| Action | **Block** |

### Step 4: Verify Rule Order

**Settings → Policy Table**

Confirm your custom policies appear in the order above (1-8). Use **Reorder** to drag them if needed. The Block All rule **must be at the bottom** of your custom rules.

Built-in (locked) policies will also appear — they cannot be moved or deleted but your custom rules take precedence over them.

### Step 5: Test

**From your Mac (trusted admin on default LAN):**
- `jellyfin.lab.valm25.com` → should work (Policy 1)
- `https://192.168.3.10:8006` → should work (Policy 2)
- `grafana.lab.valm25.com` → should work (Policy 3)

**From a phone or untrusted device on default LAN:**
- `jellyfin.lab.valm25.com` → should work (Policy 1)
- `https://192.168.3.10:8006` → should be **blocked** (Policy 8)

**If something breaks:** Temporarily disable Policy 8 (the block-all) while you debug.

---

## Important Notes

- **DNS and DHCP** — The default Gateway zone policies already allow DNS (53) and DHCP (67/68) from Internal. No custom policy needed.
- **Same-VLAN traffic** — Devices on the same /24 subnet communicate directly through the switch, NOT through the gateway. The block rule does not affect them.
- **Return traffic** — Checking "Auto Allow Return Traffic" on Allow policies handles response packets automatically. No need for a separate established/related rule.
- **Blocking Gateway traffic** — Be careful blocking traffic to the Gateway zone. It can break DHCP and DNS. The Internal→Gateway default is "Allow All" and should generally stay that way.
- **Internal→Internal default is "Allow All"** — Your block-all policy (Policy 8) overrides this for cross-VLAN traffic specifically.

---

## Future Improvements

### IoT VLAN (recommended)
Create VLAN 4 (192.168.4.0/24) for smart devices:
- Smart TVs, plugs, bulbs, robot vacuums, voice assistants
- Assign to a **custom zone** called "IoT" (or keep in Internal and use policies)
- Block IoT → all RFC1918 (total isolation)
- Allow IoT → External (internet access)
- Exception: Allow Home Assistant IP to reach IoT VLAN for device control
- Enable **mDNS reflector** if needed for AirPlay/Chromecast discovery across VLANs

### Guest Network
- Create VLAN 99, WiFi SSID "Home-Guest"
- Assign to the **Hotspot** zone — automatically isolates from Internal
- Built-in Hotspot zone defaults: Block All to Hotspot/DMZ, Allow Return Traffic to Internal
- Set bandwidth limits via QoS (Settings → Policy Table → Create New Policy → QoS)
- Enable client isolation (guests can't see each other)

### Additional UniFi Security
- **Threat Management (IPS):** Already enabled on UDMSE. Monitor via [[UniFi Toolkit]] Threat Watch.
- **Honeypot:** Settings → Security → Enable honeypot (creates fake service, alerts on access — detects lateral movement)
- **Application Filtering:** Settings → CyberSecure → Protection → Simple App Blocking (block apps by category)
- **Content Filtering:** Settings → CyberSecure → Protection → Content & Domain Filtering
- **2FA on Ubiquiti account** — essential if using unifi.ui.com remote access
- **Disable remote access** entirely if using Teleport VPN instead
