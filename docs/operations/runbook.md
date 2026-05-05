# Runbook

Common tasks, known issues, and their solutions.

---

## Verify VPN is Active

After starting the Arr Sandbox, confirm all download traffic is using the VPN and not the home IP before enabling any *arr service.

Check from the Proxmox host:
```bash
# Enter the Arr Sandbox container
sudo pct enter <arr-sandbox-ct-id>

# Check the IP seen by qBittorrent
docker exec qbittorrent curl -s https://ifconfig.me
```

The returned IP must be a PIA IP — not your home IP.

---

## Restart a Docker Stack

```bash
# Enter the relevant LXC
sudo pct enter <ct-id>

# Restart all containers in the stack
cd /opt/<stack-name>
docker compose down && docker compose up -d
```

---

## Check Container Logs

```bash
docker compose logs -f <service-name>
```

---

## Proxmox Backup

Manual backup via the Proxmox Backup Server:

1. Open the Proxmox web UI
2. Select the VM or LXC → Backup → Backup Now
3. Target: PBS datastore
4. Mode: Snapshot (preferred for running containers)

Scheduled backups are configured in Datacenter → Backup.

---

## GPU Hardware Transcoding Not Working (Jellyfin / Plex)

1. Confirm the Intel Arc A310 is visible in the VM: `ls /dev/dri/`
2. In Jellyfin: Dashboard → Playback → Transcoding → set to Intel QuickSync (VA-API)
3. Device path: `/dev/dri/renderD128`
4. Restart Jellyfin after changing the setting

---

## Pi-hole Not Resolving

1. Check Pi-hole is running: `systemctl status pihole-FTL`
2. Verify UniFi DHCP is pointing to the Pi-hole IP as DNS
3. Check `/etc/pihole/pihole.conf` for upstream resolver configuration
4. Flush DNS cache: `pihole restartdns`

---

## NPM Certificate Renewal Failed

Let's Encrypt DNS challenge uses a Cloudflare API token. If renewal fails:

1. Open NPM → SSL Certificates → check the cert for errors
2. Verify the Cloudflare API token in NPM settings is still valid
3. Force renewal from the NPM SSL cert page

---

## Boot Issues (Proxmox Host)

See `PVE_BOOT_ISSUE.md` in the repository for the documented boot issue and resolution.

---

## Syncthing Conflict Files

If Syncthing creates `.sync-conflict` files:

1. Compare both versions
2. Keep the correct one and delete the conflict file
3. Check that both nodes are online and the folder is in sync before editing shared files

---

## Adding a New Service

1. Create or modify the relevant Docker Compose file
2. Add a Proxy Host in NPM pointing to the new container
3. Add a DNS record in Pi-hole if needed
4. Add a tile in Homarr
5. Add an uptime check in Uptime Kuma
