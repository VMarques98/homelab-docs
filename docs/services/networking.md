# Networking

## Pi-hole

Network-wide DNS ad blocker running on a Raspberry Pi Zero W2.

Configured as the primary DNS server for all VLANs via UniFi DHCP settings.

- **Upstream resolver:** Cloudflare (1.1.1.1)
- **Local DNS records:** wildcard record for the homelab domain pointing to Nginx Proxy Manager
- **Block lists:** default lists + custom tracking/telemetry lists

---

## Nginx Proxy Manager (NPM)

Handles all inbound HTTP(S) traffic for the homelab domain. Runs in a dedicated LXC.

SSL certificates auto-renew via Let's Encrypt DNS challenge using a Cloudflare API token configured in NPM.

**Adding a new service:**

1. Create a new Proxy Host in NPM
2. Forward hostname to the container/VM and its port
3. Enable SSL → Request Let's Encrypt certificate

---

## WatchYourLAN

Network device discovery tool. Scans the LAN and lists all connected devices with MAC addresses, IPs, and hostnames. Useful for spotting unknown devices on the network.

---

## UniFi Network

The homelab runs on UniFi hardware (router + managed switch).

Key configuration:
- Homelab VLAN tagged on Proxmox-facing switch ports
- Media/Torrent VLAN tagged for Arr sandbox VPN egress
- DHCP servers on each VLAN point to Pi-hole as DNS
- WifiMan Teleport enabled for remote LAN access without a separate VPN client
