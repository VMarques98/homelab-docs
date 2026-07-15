---
date: 2026-04-01
tags:
  - homelab
  - tdarr
  - transcoding
  - av1
parent: "[[Homelab 3.0]]"
status: completed
---

# Tdarr AV1 Transcoding

Multi-node AV1 hardware transcoding of all media to save NAS space.

## Results (completed 2026-03-31)

| Metric | Value |
|--------|-------|
| Total files | 2,808 |
| Successfully transcoded | 2,410 (86%) |
| Errors | 398 (14% — mostly missing bitrate metadata) |
| Space saved | 12.78 GB |
| Tdarr score | 85.83% |

## Architecture

- **Server:** Docker on media-server VM 101 (192.168.3.22), ports 8265 (UI) + 8266 (node comm)
- **Flow:** "AV1 Hardware Transcode (Optimized)" (ID: dHr2KDH5W)
- **Libraries:** Movies 2 (`/media/Movies`), TV (`/media/TV`)

### Nodes

| Node | GPU | Workers | Speed |
|------|-----|---------|-------|
| media-server | Intel Arc A310 (QSV) | 2 GPU, 2 CPU healthcheck | ~120 fps |
| windows-5090 | NVIDIA RTX 5090 (NVENC) | 6-8 GPU, 3 CPU healthcheck | 200-600 fps |

Windows node connects cross-VLAN (192.168.0.244 → 192.168.3.22:8266) with path translators `/media`→`M:/` and `/temp`→`C:/Temp/tdarr_cache`.

## Optimized Flow Pipeline

```
Input
  → Check if AV1 (skip if yes)
  → Check Bitrate > 3000 kbps (skip low-bitrate YIFY/XviD)
  → Check Node Hardware Encoder
    ├── NVENC path: CQ 30, preset p7, tune hq, spatial-aq, multipass fullres
    └── QSV path:   ICQ 26, preset veryslow, 10-bit, extbrc, look-ahead 100
  → Set Container MKV
  → Execute
  → Compare File Size Ratio (must be <100% of original)
  → Replace Original
```

### Key Design Decisions

- **Separate encoder settings** — QSV ICQ 26 and NVENC CQ 30 are calibrated independently (different quality scales)
- **Bitrate floor filter** — 3000 kbps minimum skips YIFY rips and already-compressed sources
- **Constrained VBR on NVENC** — `-rc vbr -cq 30 -b:v 0` prevents output bloat
- **10-bit on QSV** — `-vf format=p010le` reduces banding and improves compression
- **Custom Arguments over Set Video Encoder** — avoids known QSV AV1 quality bug (Tdarr Plugins Issue #677)
- **compareFileSizeRatio v2.0.0** — output 1 (within bounds) → replace, output 3 (too large) → discard

## Auto-Processing New Files

Tdarr automatically detects new files added by [[Arr Stack]] (Sonarr/Radarr) via `folderWatching` on both libraries. No manual intervention needed — new downloads are queued and transcoded automatically.

## Errors

398 errors were "Video bitrate not found" — files without bitrate metadata in their streams (old XviD, AVI containers). These are effectively filtered out as they're typically low-quality sources not worth transcoding.
