# Homelab Overview

## Full Architecture Diagram

```mermaid
graph TD
    Internet(("🌐 Internet"))
    Router["UniFi Router / Switch<br/><i>VLAN-aware, WifiMan Teleport</i>"]

    Internet --> Router

    subgraph Proxmox["🖥️  Proxmox Host — Ryzen 9 5900X · 32GB · Intel Arc A310"]
        NPM["Nginx Proxy Manager<br/><i>*.lab.valm25.com · SSL</i>"]
        Pihole["Pi-hole<br/><i>DNS · ad blocking</i>"]
        PBS["Proxmox Backup Server"]

        subgraph Monitoring["📊 Monitoring Stack (LXC)"]
            Prometheus["Prometheus"]
            Grafana["Grafana"]
            UptimeKuma["Uptime Kuma"]
            Homarr["Homarr<br/><i>dashboard</i>"]
            Netdata["Netdata"]
        end

        subgraph ArrSandbox["📥 Arr Sandbox (LXC — dual-homed VPN)"]
            Gluetun["Gluetun<br/><i>PIA VPN · kill switch</i>"]
            Sonarr["Sonarr"]
            Radarr["Radarr"]
            Prowlarr["Prowlarr"]
            qBit["qBittorrent"]
            Bazarr["Bazarr"]
            FlareSolverr["FlareSolverr"]
        end

        subgraph MediaVM["🎬 Media Server (VM — GPU passthrough)"]
            Jellyfin["Jellyfin"]
            Plex["Plex"]
            TdarrServer["Tdarr Server"]
        end
    end

    subgraph ExternalNodes["External Nodes"]
        MacMini["Mac Mini M2 Pro<br/><i>mac-llm</i>"]
        Pi400["Raspberry Pi 400<br/><i>pi-home</i>"]
        PiZero["Raspberry Pi Zero W2<br/><i>pi-dns</i>"]
        WindowsPC["Windows PC<br/><i>RTX 5090</i>"]
        NAS["NAS<br/><i>SMB/NFS storage</i>"]
    end

    subgraph MacMiniServices["Mac Mini Services"]
        Ollama["Ollama<br/><i>LLM inference</i>"]
        OpenWebUI["Open-WebUI"]
        Syncthing1["Syncthing"]
    end

    subgraph Pi400Services["Pi 400 Services"]
        HA["Home Assistant"]
        HB["Homebridge<br/><i>HomeKit bridge</i>"]
    end

    Router --> Proxmox
    Router --> MacMini
    Router --> Pi400
    Router --> PiZero
    Router --> WindowsPC
    Router --> NAS

    MacMini --> MacMiniServices
    Pi400 --> Pi400Services

    Sonarr & Radarr --> Prowlarr
    Sonarr & Radarr --> qBit
    qBit --> Gluetun
    Gluetun --> Internet

    qBit --> NAS
    NAS --> Jellyfin & Plex

    WindowsPC -- "Tdarr worker<br/>NVENC AV1" --> TdarrServer

    Prometheus --> Grafana
    Pihole -- "DNS" --> Router

    NPM -- "reverse proxy" --> Jellyfin & Plex & Sonarr & Radarr & Prowlarr & qBit
    NPM -- "reverse proxy" --> Grafana & UptimeKuma & Homarr
    NPM -- "reverse proxy" --> OpenWebUI & HA & HB
```

---

## Service Breakdown

### Proxmox Host

The single Proxmox node is the core of the lab. All LXC containers and VMs run here. The Intel Arc A310 GPU is passed through to the Media Server VM for hardware-accelerated transcoding.

| Container / VM | Type | Services |
|----------------|------|----------|
| Pi-hole | LXC | DNS resolver, network-wide ad blocking |
| Nginx Proxy Manager | LXC | Reverse proxy, SSL termination for all services |
| Monitoring Stack | LXC | Prometheus, Grafana, Uptime Kuma, Homarr, Netdata, cAdvisor, PVE Exporter |
| Arr Sandbox | LXC (dual-homed) | Gluetun VPN, Sonarr, Radarr, Prowlarr, qBittorrent, Bazarr, FlareSolverr |
| Proxmox Backup Server | LXC | Scheduled VM/LXC snapshots to NAS |
| Media Server | VM | Jellyfin, Plex, Tdarr server — GPU passthrough |

### External Nodes

| Node | Hardware | Services |
|------|----------|----------|
| Mac Mini (mac-llm) | Apple M2 Pro | Ollama (LLM inference), Open-WebUI, Syncthing |
| Pi 400 (pi-home) | Raspberry Pi 400 | Home Assistant, Homebridge (HomeKit) |
| Pi Zero W2 (pi-dns) | Raspberry Pi Zero W2 | Pi-hole (DNS) |
| Windows PC (storm) | RTX 5090 | Tdarr remote worker (NVENC AV1 transcoding) |
| NAS (UNAS) | — | SMB/NFS media storage (movies, TV, music) |

---

## Media Pipeline

How a media request goes from click to stream:

```mermaid
sequenceDiagram
    actor User
    participant Overseerr as Overseerr<br/>(request UI)
    participant Sonarr as Sonarr / Radarr
    participant Prowlarr as Prowlarr<br/>(indexers)
    participant qBit as qBittorrent
    participant Gluetun as Gluetun VPN
    participant NAS
    participant Player as Jellyfin / Plex

    User->>Overseerr: Request show or movie
    Overseerr->>Sonarr: Add to wanted list
    Sonarr->>Prowlarr: Search indexers
    Prowlarr-->>Sonarr: Return NZB/torrent
    Sonarr->>qBit: Add download job
    qBit->>Gluetun: All traffic through VPN
    Gluetun->>NAS: Write completed file
    Sonarr->>NAS: Rename and organize
    User->>Player: Stream
    Player->>NAS: Read media file
```

---

## VPN Isolation

The Arr Sandbox LXC is dual-homed. Download traffic can only exit through the VPN VLAN — it never touches the home IP. The kill switch blocks all internet traffic if the VPN tunnel drops.

```mermaid
graph LR
    Apps["Sonarr / Radarr<br/>Prowlarr / qBittorrent"] --> Gluetun
    Gluetun -->|"VPN tunnel<br/>PIA"| Internet(("🌐 Internet"))
    Gluetun -. "kill switch<br/>blocks if VPN down" .-> X["❌ Direct egress blocked"]
```

---

## Monitoring Stack

```mermaid
graph LR
    NE["Node Exporter<br/><i>host metrics</i>"]
    cAdvisor["cAdvisor<br/><i>container metrics</i>"]
    PVE["PVE Exporter<br/><i>Proxmox API</i>"]

    NE & cAdvisor & PVE -->|scrape 15s| Prometheus
    Prometheus --> Grafana["Grafana<br/><i>dashboards</i>"]
    Prometheus --> UptimeKuma["Uptime Kuma<br/><i>alerting → Discord</i>"]
```

---

## Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| Hypervisor | Proxmox VE 9.1.1 |
| Containers | LXC + Docker Compose |
| VMs | KVM |
| Reverse proxy | Nginx Proxy Manager |
| DNS / ad block | Pi-hole |
| VPN | Gluetun + PIA (OpenVPN) |
| Media servers | Jellyfin (primary), Plex |
| Media automation | Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent |
| Transcoding | Tdarr (Intel QSV + NVENC AV1) |
| Metrics | Prometheus + Grafana + Node Exporter |
| Alerting | Uptime Kuma → Discord |
| LLM inference | Ollama (Apple M2 Pro) |
| LLM frontend | Open-WebUI |
| Home automation | Home Assistant + Homebridge |
| Remote access | UniFi WifiMan Teleport |
| File sync | Syncthing |
| Backups | Proxmox Backup Server |
