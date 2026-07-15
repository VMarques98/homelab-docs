---
date: 2026-04-01
tags:
  - homelab
  - arr
  - vpn
  - media
parent: "[[Homelab 3.0]]"
status: active
---

# Arr Stack

All media management services running in LXC 110 (arr-sandbox) behind Gluetun VPN.

## Services

| Service | Port | URL |
|---------|------|-----|
| Sonarr | 8989 | sonarr.lab.valm25.com |
| Radarr | 7878 | radarr.lab.valm25.com |
| Prowlarr | 9696 | prowlarr.lab.valm25.com |
| qBittorrent | 8080 | qbit.lab.valm25.com |
| Bazarr | 6767 | bazarr.lab.valm25.com |
| FlareSolverr | 8191 | (direct only) |
| Whisparr | 6969 | (direct only, no NPM/monitoring) |

## VPN Isolation

All traffic routes through **Gluetun (PIA VPN, US East)**. Containers use `network_mode: service:gluetun` — if VPN drops, no network at all (inherent kill switch).

### Isolation Layers

1. **Network namespace** — `network_mode: service:gluetun`
2. **DNS-over-TLS** — `DOT=on`
3. **Firewall** — `FIREWALL=on`
4. **Separate bridge** — vmbr1 (VLAN 7 tagged via nic1.7, 192.168.7.0/24) for external-facing traffic
5. **NAS-only LAN access** — `FIREWALL_OUTBOUND_SUBNETS=192.168.0.204/32,192.168.3.0/24,192.168.7.0/24`

### Verification

```bash
docker exec gluetun curl ifconfig.io          # VPN IP
docker exec qbittorrent curl ifconfig.io      # Same VPN IP
docker stop gluetun && docker exec qbittorrent curl ifconfig.io  # Should FAIL
```

## qBittorrent Config

No-seeding setup: `max_ratio=0.01`, `max_seeding_time=1`, `max_ratio_act=0` (pause), upload limit 1 KB/s.

## New File Processing

When Sonarr/Radarr download and import new media files, [[Tdarr AV1 Transcoding]] automatically detects them via folder watching and queues them for AV1 transcode.

> [!warning] Import is not automatic for every release — see gotchas below.

## Automated Download Recovery

Hermes job **Arr download import and recovery** runs every 6 hours. It checks
qBittorrent for completed downloads that Sonarr or Radarr have not imported and
uses the relevant Arr application's import/rescan workflow. A qBittorrent job
and its downloaded data are removed only after the Arr import succeeds and the
media file is verified in the configured library root.

Downloads that have made no progress for at least 12 hours are reviewed. If
they are confirmed stalled/failed and still wanted, the Arr application is
asked to handle the failed release and search for an alternate source through
the existing indexer/Prowlarr workflow. Incomplete, active, intentionally
paused, seeding, ambiguous, or failed-import items are left untouched.

The automation accesses services from inside CT 110 using Docker-local
endpoints, keeps API credentials in shell variables, and never uses a bare
`docker compose up -d`.

qBittorrent credentials are stored outside the notes in the protected Hermes
file `~/.hermes/qbit.credentials` (mode `600`) on each staged Hermes node. The
file contains the qBittorrent username on line 1 and password on line 2; never
copy its contents into documentation or cron prompts.

## Import Path Mapping (atomic moves)

Inside CT 110 the NAS is mounted into Sonarr twice — the whole share at `/media` (library `/media/TV`) **and** the download folder again at `/downloads`. Docker sees these as two separate mounts, so Sonarr can't hardlink/atomic-move between them and falls back to a slow CIFS copy → downloads stick in the queue as **"Importing."**

Fix (applied live): a **Remote Path Mapping** in Sonarr — Settings → Download Clients → Remote Path Mappings:

| Host | Remote Path | Local Path |
|------|-------------|------------|
| `127.0.0.1` | `/downloads/` | `/media/Downloads/` |

Now `/media/Downloads` and `/media/TV` share one mount → imports hardlink instantly (no extra disk, torrent keeps seeding). Root folder = `/media/TV`.

## "Invalid season or episode" (anime absolute numbering)

Long-running anime like **One Piece** arrive as `ONE.PIECE.S08E196…` where `196` is the **absolute** episode number, not S8E196. Sonarr can't parse the hybrid `SxxEyyy` → rejects with **"Invalid season or episode"** → downloaded but never on the show. Fix = manual import mapping each file by its absolute number (abs 196 = One Piece **S10E01**). Full playbook + script: [[Arr Import & I/O Overload]].
