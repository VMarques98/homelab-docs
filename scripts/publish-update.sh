#!/usr/bin/env bash
# Commit and publish a verified homelab documentation update.
set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  printf 'Usage: %s "docs: describe the verified change"\n' "$0" >&2
  exit 2
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
message=$1

python3 scripts/scan-secrets.py
git diff --check
git add --all

if git diff --cached --quiet; then
  echo 'No changes to publish.'
  exit 0
fi

git commit -m "$message"
commit=$(git rev-parse HEAD)
remote=$(git config --get remote.origin.url)
branch=$(git branch --show-current)

# Repositories inside iCloud can occasionally stall while Git reads the object
# database during HTTPS push. Push through a temporary local clone when gh is
# available; this keeps the same commit and avoids copying any working files.
if command -v gh >/dev/null 2>&1 && [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
  owner_repo=${BASH_REMATCH[1]}
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/homelab-publish.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT
  gh repo clone "$owner_repo" "$tmp" >/dev/null
  git -C "$tmp" fetch "$repo_root" "$commit"
  git -C "$tmp" push origin "FETCH_HEAD:$branch"
else
  git push origin "HEAD:$branch"
fi

remote_commit=$(git ls-remote origin "refs/heads/$branch" | awk 'NR==1 {print $1}')
if [[ "$remote_commit" != "$commit" ]]; then
  printf 'remote verification failed: local=%s remote=%s\n' "$commit" "$remote_commit" >&2
  exit 1
fi
printf 'published and verified %s on %s\n' "$commit" "$branch"
