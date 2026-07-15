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

## Component breakdown

| Component | Signal | Used for | Failure symptom |
|---|---|---|---|
| Prometheus | Time-series scrapes | Historical metrics and alert queries | Dashboards age and scrape targets turn down. |
| Grafana | Queries and dashboards | Human investigation and trends | Metrics may exist but are hard to visualize. |
| Uptime Kuma | HTTP/TCP checks | Availability alerts and recovery notifications | Service outage may not generate an alert. |
| Homarr | Service links and integrations | Operator landing page | Navigation/status tiles become stale. |
| Netdata | Host/process telemetry | Short-lived CPU, memory, and I/O diagnosis | Detailed process context is unavailable. |
| Node Exporter | Host metrics | CPU, RAM, disk, network | Host-level dashboards lose detail. |
| cAdvisor | Container metrics | Docker resource attribution | Per-container usage disappears. |
| PVE Exporter | Proxmox API metrics | VM/LXC health and capacity | Guest metrics stop updating. |

## Alerting contract

A monitor is useful only if it identifies the service, failure boundary, and recovery action. When adding a service, add its uptime check, required scrape target/dashboard, and an owner/runbook link. Discord notifications are an alert channel, not proof that a service is healthy.

## Verification and retention

Check Prometheus target health, recent samples, Grafana dashboard freshness, Uptime Kuma notification delivery, and disk usage for metric retention after monitoring changes. Keep credentials for the Proxmox exporter outside the repository.
