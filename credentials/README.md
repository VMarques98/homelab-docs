# Local homelab credentials

Credential values are intentionally **not stored in this repository**. Keep them in the macOS Keychain on the operator device and apply them with:

```bash
./scripts/bootstrap-credentials.sh --help
./scripts/bootstrap-credentials.sh                # dry run
./scripts/bootstrap-credentials.sh --apply        # apply over SSH
```

The bootstrap script reads generic-password items from Keychain, sends values over SSH through stdin, and writes only the service-local files/configuration that the current topology requires. It never prints secret values. `--apply` must be run manually by the operator; it is not safe to run unattended.

Suggested Keychain service names:

| Service | Account | Destination |
|---|---|---|
| `valm25.homelab.pbs.password` | `pbs-nas` | PVE `/etc/pve/priv/storage/pbs-nas.pw` |
| `valm25.homelab.vpn.user` | `arr-sandbox` | CT 110 `/opt/arr/.env` |
| `valm25.homelab.vpn.password` | `arr-sandbox` | CT 110 `/opt/arr/.env` |
| `valm25.homelab.unifi.username` | `unifi-toolkit` | CT 105 `/opt/unifi-toolkit/.env` |
| `valm25.homelab.unifi.password` | `unifi-toolkit` | CT 105 `/opt/unifi-toolkit/.env` |
| `valm25.homelab.unifi.api-key` | `unifi-toolkit` | CT 105 `/opt/unifi-toolkit/.env` |
| `valm25.homelab.grafana.password` | `grafana` | CT 105 `/opt/monitoring/.env` |
| `valm25.homelab.pihole.password` | `pihole` | CT 100 Pi-hole password reset during apply |

Store additional service credentials under the same naming convention and extend the script only after confirming the live service's supported configuration path. Do not put values in a `.env` file inside this repository; `.env` files are ignored as a second line of defense.

## Adding an item

Use Keychain's interactive prompt rather than putting a value in shell history:

```bash
security add-generic-password -a 'pbs-nas' -s 'valm25.homelab.pbs.password' -U
```

Confirm the item exists without printing it:

```bash
security find-generic-password -a 'pbs-nas' -s 'valm25.homelab.pbs.password' >/dev/null && echo 'present'
```
