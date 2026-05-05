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
