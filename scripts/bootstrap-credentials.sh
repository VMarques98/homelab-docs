#!/usr/bin/env bash
# Apply macOS-Keychain credentials to the known VALM homelab destinations.
# Dry-run is the default. Run --apply manually after reviewing the plan.
set -euo pipefail

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then APPLY=1; elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage:
  bootstrap-credentials.sh          Show destinations and missing Keychain items
  bootstrap-credentials.sh --apply  Apply present items over SSH (manual only)

Values come from macOS Keychain generic-password items. Secret values are never
printed, committed, or passed as command-line arguments to SSH.
USAGE
  exit 0
elif [[ $# -ne 0 ]]; then echo 'unknown argument; use --help' >&2; exit 2; fi

command -v security >/dev/null || { echo 'macOS security command is required' >&2; exit 1; }
command -v ssh >/dev/null || { echo 'ssh is required' >&2; exit 1; }

get_secret() {
  security find-generic-password -a "$2" -s "$1" -w 2>/dev/null || return 1
}

has_secret() { get_secret "$1" "$2" >/dev/null; }

required=(
  'valm25.homelab.pbs.password|pbs-nas|PVE /etc/pve/priv/storage/pbs-nas.pw'
  'valm25.homelab.vpn.user|arr-sandbox|CT 110 /opt/arr/.env OPENVPN_USER'
  'valm25.homelab.vpn.password|arr-sandbox|CT 110 /opt/arr/.env OPENVPN_PASSWORD'
  'valm25.homelab.unifi.username|unifi-toolkit|CT 105 /opt/unifi-toolkit/.env UNIFI_USERNAME'
  'valm25.homelab.unifi.password|unifi-toolkit|CT 105 /opt/unifi-toolkit/.env UNIFI_PASSWORD'
  'valm25.homelab.unifi.api-key|unifi-toolkit|CT 105 /opt/unifi-toolkit/.env UNIFI_API_KEY'
  'valm25.homelab.grafana.password|grafana|CT 105 /opt/monitoring/.env GF_SECURITY_ADMIN_PASSWORD'
  'valm25.homelab.pihole.password|pihole|CT 100 Pi-hole password reset'
)

missing=0
for item in "${required[@]}"; do
  IFS='|' read -r service account destination <<<"$item"
  if has_secret "$service" "$account"; then
    printf 'present  %s -> %s\n' "$service" "$destination"
  else
    printf 'missing  %s -> %s\n' "$service" "$destination"
    missing=$((missing + 1))
  fi
done

(( APPLY == 1 )) || { echo 'dry run only; use --apply to write present credentials'; exit 0; }
if ! ssh -o ConnectTimeout=8 -o BatchMode=yes proxmox 'hostname >/dev/null'; then
  echo 'cannot reach proxmox using the configured SSH alias' >&2
  exit 1
fi

# PBS storage password is a single secret file on the PVE host.
if has_secret 'valm25.homelab.pbs.password' 'pbs-nas'; then
  get_secret 'valm25.homelab.pbs.password' 'pbs-nas' | ssh proxmox 'umask 077; cat > /etc/pve/priv/storage/pbs-nas.pw; chmod 600 /etc/pve/priv/storage/pbs-nas.pw'
  echo 'applied PBS storage credential'
fi

# Merge key/value pairs into service env files without replacing unrelated settings.
merge_env() {
  local ctid=$1 path=$2
  shift 2
  local payload
  payload=$(mktemp)
  trap 'rm -f "$payload"' RETURN
  for pair in "$@"; do
    IFS='|' read -r service account key <<<"$pair"
    if has_secret "$service" "$account"; then
      printf '%s=' "$key" >>"$payload"
      get_secret "$service" "$account" >>"$payload"
      printf '\n' >>"$payload"
    fi
  done
  [[ -s "$payload" ]] || return 0
  ssh proxmox "pct exec '$ctid' -- sh -s -- '$path'" < <({ cat <<'REMOTE'
set -eu
path=$1
mkdir -p "$(dirname "$path")"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
[ -f "$path" ] && cat "$path" >"$tmp" || :
while IFS= read -r line; do
  key=${line%%=*}
  value=${line#*=}
  if grep -qE "^${key}=" "$tmp"; then
    # Values arrive on stdin, never in the ssh command line.
    awk -v key="$key" -v value="$value" 'BEGIN{done=0} $0 ~ "^" key "=" && !done {print key "=" value; done=1; next} {print} END{if(!done) print key "=" value}' "$tmp" >"$tmp.new"
    mv "$tmp.new" "$tmp"
  else
    printf '%s=%s\n' "$key" "$value" >>"$tmp"
  fi
done
chmod 600 "$tmp"
mv "$tmp" "$path"
REMOTE
cat "$payload"; })
  rm -f "$payload"
}

merge_env 110 /opt/arr/.env \
  'valm25.homelab.vpn.user|arr-sandbox|OPENVPN_USER' \
  'valm25.homelab.vpn.password|arr-sandbox|OPENVPN_PASSWORD'
merge_env 105 /opt/unifi-toolkit/.env \
  'valm25.homelab.unifi.username|unifi-toolkit|UNIFI_USERNAME' \
  'valm25.homelab.unifi.password|unifi-toolkit|UNIFI_PASSWORD' \
  'valm25.homelab.unifi.api-key|unifi-toolkit|UNIFI_API_KEY'
merge_env 105 /opt/monitoring/.env \
  'valm25.homelab.grafana.password|grafana|GF_SECURITY_ADMIN_PASSWORD'

echo 'applied available environment credentials; services were not restarted'
echo 'Pi-hole password is intentionally left as a manual post-restore step'
