---
date: 2026-04-06
tags:
  - homelab
  - proxmox
  - incident
  - recovery
parent: "[[Homelab 3.0]]"
status: resolved
---

# PVE Boot Recovery (April 5-6, 2026)

## Incident Summary

PVE became unreachable on April 5. Power cycling the system caused a boot loop with black screen and no networking. Root cause was a combination of GPU driver issues, incorrect network interface naming, and a previously-enabled PVE firewall with restrictive DROP policy.

## Timeline

- **March 26 - April 5**: System running perfectly (uptime 10 days, boot -14)
- **April 5 ~18:30**: Found system unresponsive, pressed power button
- **April 5 18:31:57**: Journal shows `systemd-logind: Power key pressed short. Powering off...`
- **April 5 - April 6**: Multiple failed boot attempts — black screen, no network
- **April 6 18:12**: System fully recovered after applying fixes

## Root Causes

### 1. Intel Arc A310 GPU Driver (Black Screen)
The `i915` and `xe` kernel drivers claimed the only GPU, evicting `simpledrm` (the UEFI framebuffer console driver). Standard `blacklist i915` was silently ignored.

**Fix (triple-layer blacklist):**
- `/etc/modprobe.d/blacklist-intel-gpu.conf`: `install i915 /bin/false` + `install xe /bin/false`
- GRUB: `module_blacklist=i915,xe i915.force_probe=!56a6 xe.force_probe=!56a6`
- Rebuilt initramfs + ran `update-grub`

### 2. Network Interface Name Mismatch
In `init=/bin/bash` mode, the NIC was `enp5s0`. During a real systemd boot, Proxmox udev rules rename it to `nic1`. The bridge config had `bridge-ports enp5s0` — wrong for real boots.

**Fix:** Changed to `bridge-ports nic1` and `bridge-waitport 30 nic1` in `/etc/network/interfaces`

### 3. ifupdown2 /run/network Directory Missing
ifupdown2 reported "Another instance already running" because `/run/network/` didn't exist.

**Fix:** Created `/etc/tmpfiles.d/ifupdown2.conf` with `d /run/network 0755 root root -`

### 4. PVE Firewall with DROP Policy
We enabled the PVE built-in firewall on April 1 with `policy_in: DROP`. This blocked the MacBook (192.168.0.203) from reaching port 8006 since only homelab VLAN sources were allowed.

**Fix:** Disabled PVE firewall entirely (`enable: 0` in cluster.fw and host.fw). UniFi handles all firewall enforcement.

## All Changes Made

| File | Change |
|------|--------|
| `/etc/modprobe.d/blacklist-intel-gpu.conf` | `install i915 /bin/false` + `install xe /bin/false` |
| `/etc/modprobe.d/vfio.conf` | Commented out all VFIO passthrough |
| `/etc/default/grub` | Added `nomodeset module_blacklist=i915,xe i915.force_probe=!56a6 xe.force_probe=!56a6` |
| `/etc/network/interfaces` | vmbr0: `bridge-ports nic1`, `bridge-waitport 30 nic1` (VLAN 6 homelab). vmbr1: `bridge-ports nic1.7` (VLAN 7 media/torrent, added April 11). |
| `/etc/tmpfiles.d/ifupdown2.conf` | `d /run/network 0755 root root -` |
| `/etc/systemd/system/networking-retry.service` | Fallback: restarts networking after 15s if bridge failed |
| `/etc/pve/firewall/cluster.fw` | `enable: 0` |
| `/etc/pve/firewall/host.fw` | `enable: 0` |
| `/etc/pve/jobs.cfg` | Fixed schedule from cron `0 */12 * * *` to systemd `*-*-* 00,12:00` |
| Root password | Changed to `pve` for emergency console access |

## Post-Recovery Fixes

| Issue | Fix |
|-------|-----|
| Grafana alert flood (every 4h) | Increased repeat_interval to 24h |
| CPU/RAM/Disk alerts fire on NoData | Changed noDataState to OK |
| PBS "401 Unauthorized" | Reset PBS password, re-added storage |
| Backup schedule (cron syntax) | Changed to systemd calendar format |
| Missing backups | Full backup of all 6 containers completed |

## Lessons Learned

1. **Never enable PVE firewall with DROP policy** when managing from a different VLAN — use UniFi as the single firewall enforcement point
2. **Interface names differ between rescue mode and real boot** — always check with `ip link show` during a real systemd boot
3. **Standard `blacklist` doesn't work for GPU drivers** — need `install /bin/false` + `module_blacklist=` on kernel cmdline
4. **Set a short root password** for emergency console access — typing long passwords blind on a black screen is painful
5. **Always run a full backup after setup** — we only had pihole backed up when this happened
6. **PVE uses systemd calendar format**, not cron — `*-*-* 00,12:00` not `0 */12 * * *`

---

## Emergency Recovery Procedure (init=/bin/bash)

If PVE ever becomes unreachable again, use this procedure to get SSH access from the console.

### Step 1: Boot into rescue shell

At the GRUB menu, press `e` to edit the boot entry. Find the line starting with `linux`. At the end of the line, add:

```
init=/bin/bash
```

Press `Ctrl+X` to boot.

### Step 2: Mount filesystem read-write

```bash
mount -o remount,rw /
```

### Step 3: Bring up networking

The interface name in rescue mode is `enp5s0` (NOT `nic1` — udev hasn't renamed it):

```bash
ip link set enp5s0 up
sleep 3
ip link add vmbr0 type bridge
ip link set enp5s0 master vmbr0
ip addr add 192.168.3.10/24 dev vmbr0
ip link set vmbr0 up
ip route add default via 192.168.3.1
```

### Step 4: Start SSH

```bash
mkdir -p /run/sshd
read -rsp 'Temporary root recovery password: ' RECOVERY_PASSWORD; echo
printf 'root:%s\n' "$RECOVERY_PASSWORD" | chpasswd
unset RECOVERY_PASSWORD
/usr/sbin/sshd -o UsePAM=no -o PermitRootLogin=yes -o PasswordAuthentication=yes
```

**Note:** PAM doesn't work in `init=/bin/bash` mode. Password auth requires `-o UsePAM=no`. Alternatively, set up key auth:

```bash
mkdir -p /root/.ssh
rm -f /root/.ssh/authorized_keys
echo 'YOUR_SSH_PUBLIC_KEY_HERE' > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
/usr/sbin/sshd -o UsePAM=no
```

### Step 5: Connect from MacBook

```bash
sshpass -p 'pve' ssh -o StrictHostKeyChecking=no root@192.168.3.10
```

Install `sshpass` first if needed: `brew install hudochenkov/sshpass/sshpass`

### Step 6: Make fixes, then reboot properly

After making changes, reboot into a real systemd boot:

```bash
reboot -f
```

**Do NOT add `init=/bin/bash` to GRUB this time** — let it boot normally.

### Important Notes

- **Interface names differ**: rescue mode uses `enp5s0`, real boot uses `nic1` (Proxmox udev rules)
- **systemd is NOT PID 1** in `init=/bin/bash` — `systemctl`, `pct`, `qm` commands won't work
- **`exec /sbin/init`** can start systemd from bash, but may cause issues — prefer `reboot -f`
- **Root password**: set to `pve` for quick console access
- **PVE firewall is disabled** — if re-enabled, make sure to allow your management IP
