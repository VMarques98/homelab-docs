---
date: 2026-07-13
tags:
  - homelab
  - arr
  - sonarr
  - incident
parent: "[[Homelab 3.0]]"
status: resolved
---

# Arr Import & I/O Overload

July 2026 session — fixing Sonarr imports that downloaded but never landed on the show, and the host overload uncovered while clearing the backlog. See [[Arr Stack]].

## 1. Symptom

Downloads completed in qBittorrent but never attached to the show. Sonarr's **Activity → Queue** showed items stuck **Importing** (warning) or **importBlocked / "Invalid season or episode"** — ~140 blocked items, mostly **One Piece**.

## 2. Root causes (two separate ones)

### a. Separate mounts → no atomic move

The live Sonarr container mounts the NAS twice: `/mnt/nas → /media` (library `/media/TV`) **and** `/mnt/nas/Downloads → /downloads`. Docker exposes them as two mount points, so Sonarr treats `/downloads` and `/media/TV` as different filesystems, can't hardlink, and the cross-mount CIFS copy stalls.

**Fix:** Sonarr Remote Path Mapping `127.0.0.1` : `/downloads/` → `/media/Downloads/`. Imports now hardlink within `/media` (instant, keeps seeding). Applied live via API.

### b. Absolute-numbered anime

`ONE.PIECE.S08E196…` releases (group VARYG) use the **absolute** episode number (196), not S8E196. Sonarr can't parse the hybrid `SxxEyyy` → "Invalid season or episode". Absolute 196 = One Piece **S10E01** on TheTVDB.

**Fix:** manual import mapping each file's absolute number → episodeId, then import in `copy` mode (hardlinks). Proven on the `ONE.PIECE.S08` pack (11 files → S10E01–E11, verified `hasFile:true`, link count 2).

> Caveat: the `E<n> = absolute` assumption holds for VARYG "SxxEabs" packs and loose `One.Piece.E1162`, but **not** for Voyage/arc packs or true Netflix-season packs — check each release's numbering first.

## 3. Host I/O overload (found while clearing the backlog)

Bulk importing stalled because the Proxmox host was thrashing: load ~165 on 24 cores, but CPU ~78% idle — it was **I/O**. `/proc/pressure/io` avg10 ≈ 93 (stalled 93% of the time), only ~2 GiB RAM free, swapping. `pct exec 110` hung on every call; host SSH stayed fine.

Culprit: **Readarr** (retired/broken, can't log into qBit 5.1+) stuck scanning the CIFS NAS — **~3.9 TB** cumulative reads in a loop. Kavita's scan added to it.

**Remediate** (when `pct exec` is too stalled for `docker stop`): freeze from the host —
`pkill -STOP -x Readarr; pkill -STOP -x Kavita` (state → T, doesn't trip Docker restart, reversible with `-CONT`), then `docker stop` cleanly once load falls.

## 4. Follow-ups

- [ ] Clear the remaining ~130 blocked packs (pack-by-pack, verifying numbering per release)
- [ ] Decide Readarr's fate — it's retired and a repeat I/O offender; consider removing it
- [ ] Consider aligning qBittorrent + Sonarr on a single `/data` mount so no path mapping is needed
- [x] Docs synced: [[Arr Stack]], repo `docs/services/media.md`, repo `docs/operations/runbook.md`
