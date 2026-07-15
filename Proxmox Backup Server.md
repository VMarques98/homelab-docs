---
date: 2026-04-01
tags:
  - homelab
  - backups
  - pbs
parent: "[[Homelab 3.0]]"
status: active
---

# Proxmox Backup Server

Automated backups of all VMs and LXCs to NAS-backed storage.

## Configuration

| Setting | Value |
|---------|-------|
| LXC ID | 106 |
| IP | 192.168.3.31 |
| UI | https://192.168.3.31:8007 |
| Auth | `root@pam` (interactive/admin); Proxmox uses dedicated token `root@pam!proxmox-pbs` |
| Datastore | `backups` at `/mnt/nas-backups/pbs-store` |
| PVE storage name | `pbs-nas` |
| Cert fingerprint | `30:07:5c:cc:f5:e1:8d:0e:8d:b9:30:0a:42:9e:fc:98:c2:a5:a5:68` |

## NAS Mount

```
//192.168.0.204/Extra /mnt/nas-backups cifs credentials=/root/.smbcredentials,vers=3.0,uid=34,gid=34,nofail 0 0
```

## Backup Schedule

Every 12 hours (`*-*-* 00,12:00` systemd calendar format) — all VMs and LXCs, snapshot mode, zstd compression.

Configured in `/etc/pve/jobs.cfg` on PVE host. **Note:** PVE uses systemd calendar format, NOT cron syntax.

## Retention Policy (Prune Job)

| Setting | Value |
|---------|-------|
| keep-last | 3 |
| keep-daily | 7 |
| keep-weekly | 4 |
| keep-monthly | 2 |
| Schedule | Daily |

## Setup Notes

PBS `datastore create` command fails over CIFS/SMB due to EEXIST race conditions when creating 65,536 chunk directories. The SMB client-side caching causes `mkdir` to report "File exists" even on fresh directories.

**Workaround used:**
1. Pre-create all 65,536 chunk dirs with a parallel shell script (`xargs -P 16`)
2. Manually write `/etc/proxmox-backup/datastore.cfg`:
   ```
   datastore: backups
       path /mnt/nas-backups/pbs-store
   ```
3. Create `.lock` file in the datastore path
4. Restart PBS services to register the datastore

**IP conflict resolved:** PBS was originally at 192.168.3.30, conflicting with the Mac Mini. Moved to 192.168.3.31 via `pct set 106 -net0 ... ip=192.168.3.31/24`.

## PVE Storage Authentication Repair — 2026-07-14

The PVE storage entry `pbs-nas` was inactive because its stored `root@pam`
password returned `401 Unauthorized`. The PBS guest and `backups` datastore were
healthy.

**Repair:** created the dedicated PBS API token `root@pam!proxmox-pbs`, granted
the `DatastoreBackup` role only at `/datastore/backups`, and updated the PVE
storage entry to use it. The PBS root password was not changed.

Verified from PVE:

```text
pbs-nas  pbs  active
Total: 976.6 GiB; Used: 134.1 GiB; Available: 842.5 GiB; Usage: 13.73%
```

Do not store PBS passwords or token secrets in this note.
