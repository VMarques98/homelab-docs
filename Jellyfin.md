---
date: 2026-04-01
tags:
  - homelab
  - jellyfin
  - media
  - transcoding
parent: "[[Homelab 3.0]]"
status: active
---

# Jellyfin

Free, open-source media server with hardware transcoding — no subscription required (unlike Plex Pass).

## Configuration

| Setting | Value |
|---------|-------|
| Container | `jellyfin/jellyfin:latest` on media-server VM 101 |
| URL | http://192.168.3.22:8096 |
| GPU | Intel Arc A310 (`/dev/dri` passthrough) |
| Media | `/mnt/nas:/media:ro` (NAS via CIFS) |
| Config | Docker volume `jellyfin_config` |

## Libraries

| Library | Path | Size |
|---------|------|------|
| Movies | `/media/Movies` | 1.7TB |
| TV Shows | `/media/TV` | 778GB |

Most content is AV1 (transcoded by [[Tdarr AV1 Transcoding]]).

## Hardware Transcoding (QSV)

**Hardware acceleration:** Intel QuickSync (QSV) via `/dev/dri/renderD128`

**Hardware decoding enabled for:** H.264, HEVC, MPEG2, VC1, VP8, VP9, AV1

**Settings:**
- Hardware encoding: ON
- Prefer OS native VA-API: ON
- VPP tone mapping: ON (HDR → SDR)
- Allow HEVC encoding: ON
- Allow AV1 encoding: ON

The Arc A310 handles hardware decode of AV1 and transcode to H.264/HEVC for clients that don't support AV1 natively. Most modern browsers direct-play AV1 with no transcoding needed.

## Metadata Setup

**Providers:**
- Movies: TMDb (primary), OMDb (IMDb/RT ratings)
- TV Shows: TMDb (primary), TheTVDB (fallback)
- Image fetchers: TMDb + Fanart.tv

**Recommended plugins:**
- Fanart.tv — high-quality artwork
- TMDb Box Sets — auto movie collections
- Open Subtitles — auto subtitle downloads
- Intro Skipper — skip TV show intros

## Why Jellyfin Over Plex

Plex requires **Plex Pass** ($5/mo or $120 lifetime) for hardware transcoding. Jellyfin provides the same capability for free. Both are deployed on the same VM — Plex at `network_mode: host`, Jellyfin on port 8096.
