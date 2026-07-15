# Media Stack

All *arr services run in a dedicated Docker Compose stack inside an LXC. The media servers run in a separate VM with GPU passthrough.

## Media Flow

```
User request
     │
  Overseerr      ← request management UI
     │
  Sonarr / Radarr   ← manage library, grab from indexers
     │
  Prowlarr       ← unified indexer proxy
     │
  qBittorrent    ← download client
     │
  Gluetun        ← VPN gateway (kill switch enabled)
     │
  PIA VPN ──── Internet
     │
  NAS            ← completed downloads moved here
     │
  Plex / Jellyfin   ← serve to clients
```

---

## Media Servers

### Jellyfin

Open-source media server — the primary streaming endpoint.

Hardware acceleration is enabled via Intel QuickSync (QSV) using the GPU passed through from the Proxmox host (Intel Arc A310).

### Plex

Secondary streaming endpoint, running on the same VM as Jellyfin and sharing the GPU.

### Tdarr

Batch transcoding pipeline. The Tdarr server manages the job queue; a Windows PC with an RTX 5090 connects as a remote worker node for GPU-accelerated H.264 → H.265/AV1 jobs.

---

## Arr Stack

All services below run inside the Arr Sandbox LXC with VPN egress.

### Sonarr

TV show automation. Monitors RSS feeds from Prowlarr, sends download jobs to qBittorrent, renames and moves completed files to the NAS.

### Radarr

Movie automation — same workflow as Sonarr.

### Prowlarr

Indexer aggregator. Syncs indexer configuration to Sonarr and Radarr automatically.

### Bazarr

Subtitle downloader. Monitors Sonarr and Radarr libraries and fetches matching subtitles.

### qBittorrent

Download client. All traffic is routed through Gluetun — if the VPN drops, qBit loses network connectivity (kill switch active).

### FlareSolverr

Cloudflare bypass proxy used by Prowlarr to access bot-protected indexers. Not proxied through NPM — internal access only.

---

## VPN Gateway

Gluetun runs as a Docker container in the Arr Sandbox LXC.

| | |
|--|--|
| **Provider** | Private Internet Access (PIA) |
| **Protocol** | OpenVPN (AES-256-CBC) |
| **Kill switch** | Enabled |

All *arr services and qBittorrent use Gluetun as their network gateway. No download traffic ever uses the home IP.

## Component breakdown

| Component | Owns | Depends on | Healthy result |
|---|---|---|---|
| Sonarr | TV wanted list, searches, imports, naming | Prowlarr, qBittorrent, NAS | Episodes import into the library root. |
| Radarr | Movie wanted list, searches, imports, naming | Prowlarr, qBittorrent, NAS | Movies import into the library root. |
| Prowlarr | Indexer configuration and sync | Indexer access, FlareSolverr where required | Sonarr/Radarr receive usable search results. |
| qBittorrent | Download jobs and temporary data | Gluetun, storage | Jobs transfer without direct non-VPN egress. |
| Gluetun | VPN tunnel and kill switch | PIA credentials/configuration | Public egress is the VPN address; tunnel loss blocks traffic. |
| Bazarr | Subtitle matching/downloads | Sonarr/Radarr libraries | Subtitles appear beside eligible media. |
| Jellyfin/Plex | Playback and library presentation | NAS mounts, media VM, GPU where transcoding | Clients can direct-play or transcode as expected. |
| Tdarr | Batch conversion | NAS, server, worker GPU | Test conversions complete and preserve originals until verified. |

## Import safety

A completed qBittorrent job is not an imported media item. Confirm the Arr application reports import success and the file exists in the configured library root before deleting download data. Leave active, incomplete, ambiguous, or failed-import jobs untouched.

## Recovery and verification

1. Verify the Arr Sandbox and Gluetun before starting download clients.
2. Check Sonarr/Radarr queues and application events before retrying imports.
3. Test a single service with `docker compose up -d --no-deps <service>`; do not use a broad compose restart casually.
4. Verify NAS mounts, library visibility, public VPN egress, and one representative import/playback path.
5. Back up guest/service configuration through PBS and record incidents in the relevant Obsidian note.
