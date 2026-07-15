# Homelab documentation repository

This directory is both the Obsidian `Projects/Homelab 3.0` note collection and the tracked documentation source for `VMarques98/homelab-docs`.

## Required workflow

- Read the relevant Obsidian note before changing a homelab service.
- Keep credentials, API keys, tokens, private keys, and recovery passwords out of notes, scripts, Git history, Discord, and GitHub.
- Store bootstrap credentials on the operator Mac in the macOS Keychain. Use `scripts/bootstrap-credentials.sh` to apply them to the live topology over SSH; it is dry-run by default.
- After every verified homelab change, update the relevant note and run `scripts/publish-update.sh "docs: describe the verified change"`.
- The publish script runs `scripts/scan-secrets.py`, commits the documentation, pushes `main`, and verifies the remote commit. Do not report a change as backed up until the remote SHA matches.
- PBS is the backup system for recoverable homelab data. GitHub is the source of truth for architecture, configuration intent, runbooks, and documentation—not live secret material or bulk service data.
- If a live change cannot be verified, document it as pending or failed; do not claim success.

## Repository safety

- Never modify `.obsidian/` from this repository.
- Avoid broad restarts and destructive Proxmox operations.
- Preserve frontmatter and Obsidian wikilinks when editing notes.
- Review `git diff --check` and the secret scanner output before every push.
