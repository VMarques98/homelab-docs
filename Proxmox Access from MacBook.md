---
date: 2026-07-13
tags:
  - homelab
  - proxmox
  - ssh
  - runbook
  - agent
parent: "[[Homelab 3.0]]"
status: active
---

# Proxmox Access from MacBook

How to connect to and operate the Proxmox host (`pve`) and its guests from this
MacBook Pro. Written so a **future agent** can pick this up cold and drive the
homelab correctly. See also [[Infrastructure Overview]], [[Arr Stack]].

> **Golden rule:** the MacBook talks to the host over SSH (`ssh proxmox`); the host
> talks to guests via `pct`; guests talk to their Docker services via `docker exec`.
> Don't try to reach guest service ports directly from the Mac — the host firewall
> default-denies them (see [Reaching service APIs](#reaching-service-apis)).

---

## 1. Connection

SSH is already configured. The alias `proxmox` is defined in `~/.ssh/config`:

```
Host proxmox
    HostName 192.168.3.10      # PVE host on the service LAN (hostname: pve)
    User root
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Connect / verify (key-based, no password):

```bash
ssh proxmox 'hostname; pveversion | head -1'
# -> pve
# -> pve-manager/9.1.1/... (running kernel 6.17.2-1-pve)
```

### Recommended flags for scripted / agent use

```bash
# Fast fail if the host is unreachable; never hang waiting for a password prompt:
ssh -o ConnectTimeout=8 -o BatchMode=yes proxmox '<cmd>'

# If a previous run killed connections and left a stale multiplexed socket that
# now hangs, bypass the control master:
ssh -o ControlPath=none -o ControlMaster=no proxmox '<cmd>'
```

If `192.168.3.10` is unreachable (off-LAN), the host is also on the ZeroTier overlay
(`192.168.191.0/24`, node id `5c163abe7f`) and reachable there once the Mac has joined.

---

## 2. Topology cheat-sheet

Single Proxmox node, unprivileged LXCs + one GPU-passthrough VM. Full map in
[[Infrastructure Overview]] / the repo's `IP_ADDRESS_REFERENCE.md`.

| Guest | ID | IP | What |
|---|---|---|---|
| **pve** host | — | 192.168.3.10 | Web UI :8006 |
| Pi-hole | CT 100 | 192.168.3.50 | DNS |
| NPM | CT 104 | 192.168.3.20 | reverse proxy :81 |
| Monitoring | CT 105 | 192.168.3.21 | Grafana :3000 |
| PBS | CT 106 | 192.168.3.31 | :8007 — see [[Proxmox Backup Server]] |
| **Arr sandbox** | CT 110 | 192.168.7.10 / 192.168.3.25 | Docker + gluetun VPN — see [[Arr Stack]] |
| Media server | VM 101 | 192.168.3.22 | Jellyfin/Plex/Tunarr, Arc A310 passthrough |
| NAS (QNAP) | — | 192.168.0.204 | SMB media, CIFS-mounted on host |

---

## 3. Core operations

### Run a command on the host
```bash
ssh proxmox 'cat /proc/loadavg; head -1 /proc/pressure/io'
```

### Run a command inside a container (LXC)
```bash
ssh proxmox 'pct exec 110 -- docker ps'
ssh proxmox 'pct exec 110 -- free -m'
```

### Run a command inside a Docker container (on CT 110)
```bash
ssh proxmox 'pct exec 110 -- docker exec sonarr curl -s http://localhost:8989/ping'
```

### Push a file to a container  (avoids ssh→pct→docker quoting hell)
Write the file locally, then **scp to the host, then `pct push`**:
```bash
scp ./myscript.sh proxmox:/tmp/myscript.sh
ssh proxmox 'pct push 110 /tmp/myscript.sh /opt/arr/myscript.sh && \
             pct exec 110 -- bash /opt/arr/myscript.sh'
```
For anything non-trivial, prefer writing a script and pushing it over inlining a
giant quoted one-liner.

### Pull / read a file from a container
```bash
ssh proxmox 'pct exec 110 -- cat /opt/arr/docker-compose.yml' > ./compose.yml
```

### SSH straight into the media VM (it's a full VM, not an LXC)
```bash
ssh root@192.168.3.22
```

---

## 4. Reaching service APIs

The hardening firewall **default-denies host→guest service ports**, and the arr
apps run inside gluetun's network namespace (`network_mode: service:gluetun`), so
their ports are only bound on the gluetun container. **Do not** curl
`192.168.3.25:8989` from the Mac or the host — it will time out (`000`). Instead
exec into the service container and hit `localhost`:

```bash
# Sonarr / Radarr / Prowlarr etc. — from inside their own container:
ssh proxmox 'pct exec 110 -- docker exec sonarr curl -s http://localhost:8989/ping'
```

### Using an API key without leaking it
The credential classifier blocks output that materializes secrets, so **keep keys
in a shell var, never `echo` them.** The arr apps store their key in
`/config/config.xml`:

```bash
ssh proxmox 'pct exec 110 -- docker exec sonarr sh -c '\''
  K=$(sed -n "s#.*<ApiKey>\(.*\)</ApiKey>.*#\1#p" /config/config.xml)
  curl -s -H "X-Api-Key: $K" "http://localhost:8989/api/v3/series"
'\'''  > series.json
# The JSON response contains no secret -> safe to bring back and parse on the Mac.
```
Parse the returned JSON **locally** (Mac has `python3`/`jq`) rather than installing
tooling in the container.

---

## 5. Health check & troubleshooting

### Ready-made health check
A read-only stack health script lives on the host at **`/root/arr-healthcheck.sh`**
(host load, io-pressure, `pct exec` latency, every container's state/restart count,
Kavita memory vs cap, gluetun health + VPN egress IP, Sonarr/Radarr ping):
```bash
ssh proxmox 'bash /root/arr-healthcheck.sh'
```

### When `pct exec 110` HANGS
This is the classic symptom of an I/O / memory overload inside CT 110 (a runaway
scanner, an OOM cascade). **Host SSH still works even when `pct exec` doesn't** —
diagnose from the host namespace:
```bash
ssh proxmox 'cat /proc/loadavg; head -1 /proc/pressure/io; \
             for p in $(pgrep -f "Readarr|Kavita"); do awk "/read_bytes/" /proc/$p/io; done'
```
- Load high but CPU mostly idle + `/proc/pressure/io` avg10 high (>50) = **I/O
  stall**, not CPU. Usually a NAS (CIFS) scan thrashing page cache.
- Recovery that works when the container is un-enterable: `pct stop 110` (clean
  cgroup kill in ~3s even under load — graceful `pct shutdown`/reboot may stall on
  D-state), then `pct start 110`.
- Milder: `pkill -STOP -x <Proc>` freezes a runaway (reversible with `-CONT`,
  doesn't trip Docker's restart policy), then `docker stop <container>`.

### gluetun / VPN
```bash
ssh proxmox 'pct exec 110 -- docker inspect gluetun --format "{{.State.Health.Status}}"'
ssh proxmox 'pct exec 110 -- curl -s http://localhost:8000/v1/publicip/ip'  # must be a PIA IP, not home
```
If the VPN drops, gluetun's kill switch blocks all arr egress. Restart gluetun,
then restart **every** `network_mode: service:gluetun` dependent so they re-attach.

---

## 6. Safety rules for agents

- **Never run a bare `docker compose up -d` in `/opt/arr`.** It starts `readarr`
  (intentionally stopped/retired) and can recreate `gluetun` on config drift, which
  **orphans every dependent's netns** (qbit:8080 goes dead until a full stack
  recreate). To change one non-gluetun service, use
  `docker compose up -d --no-deps <service>`. Full gotcha in [[Arr Stack]].
- **Back up before editing** live config: `cp -a docker-compose.yml docker-compose.yml.bak-<reason>`.
- `readarr` is **intentionally stopped** — its `Exited 137 / OOMKilled` state is
  stale from an incident, not a fault. Don't restart it without being asked.
- Confirm before destructive / irreversible host ops (`pct stop`, `pct destroy`,
  wiping volumes, firewall changes). Read-only diagnostics are always safe.
- The NAS at `/mnt/nas` inside CT 110 is **CIFS (a network filesystem)** — block-I/O
  throttles (`blkio`, `ionice`, `io.max`) are no-ops on it; use `mem_limit` + `cpus`
  + app-level scan limits instead.

---

## 7. Copy-paste quickstart

```bash
# 1. Am I connected? What version?
ssh -o ConnectTimeout=8 proxmox 'hostname; pveversion | head -1'

# 2. List guests
ssh proxmox 'pct list; qm list'

# 3. Arr stack health in one shot
ssh proxmox 'bash /root/arr-healthcheck.sh'

# 4. Poke a service API (Sonarr) from inside its container
ssh proxmox 'pct exec 110 -- docker exec sonarr curl -s http://localhost:8989/ping'
```
