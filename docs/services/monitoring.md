# Monitoring

All monitoring services run in a dedicated LXC via Docker Compose.

## Stack Overview

```
All services expose metrics
     │  (Prometheus scrapes every 15s)
  Prometheus       ← time-series metrics database
     │  (query)
  Grafana          ← dashboards and visualization
     
  Uptime Kuma      ← uptime checks and alerting (Discord)
  Homarr           ← unified service dashboard
  Netdata          ← real-time per-process monitoring
```

---

## Services

### Grafana

Dashboards for all homelab metrics. Pre-configured data source points to the local Prometheus instance.

Useful community dashboards:
- Node Exporter Full (grafana.com ID: 1860)
- cAdvisor (grafana.com ID: 14282)
- Proxmox VE (grafana.com ID: 10347)

### Prometheus

Scrapes metrics from all exporters. Configured targets:
- **Node Exporter** — host-level CPU, RAM, disk, network
- **cAdvisor** — Docker container resource metrics
- **PVE Exporter** — Proxmox VM/LXC resource usage via the Proxmox API

### Uptime Kuma

HTTP and TCP uptime checks for all services. Sends alerts to Discord via webhook when a service goes down or recovers.

### Homarr

Unified dashboard with tiles for every service. Integrates with Sonarr, Radarr, and other *arr services to surface active downloads and library stats.

### Netdata

Real-time system monitoring with granular per-process metrics. Useful for diagnosing CPU spikes or memory pressure.

### Node Exporter

Exposes host system metrics (CPU, memory, disk I/O, network) for Prometheus to scrape.

### cAdvisor

Exposes per-container resource metrics for all Docker containers.

### PVE Exporter

Connects to the Proxmox API and exposes VM and LXC resource metrics for Prometheus.
