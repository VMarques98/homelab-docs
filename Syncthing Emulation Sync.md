---
date: 2026-04-01
tags:
  - homelab
  - syncthing
  - emulation
  - steamdeck
  - delta
parent: "[[Homelab 3.0]]"
status: active
---

# Syncthing Emulation Sync

Cross-device emulator save sync between Steam Deck, iPhone (Delta), Mac Mini, and NAS — with automated bidirectional bridge.

## Architecture

```
Delta (iPhone) → Dropbox → Mac Mini → Bridge Script → Syncthing → PVE Hub → Steam Deck
                                                                              ↕ (reverse)
```

Both Proxmox and Mac Mini are always-on. Steam Deck syncs when powered on.

## Syncthing Nodes

| Device | IP | Port | Install | Auto-start |
|--------|-----|------|---------|------------|
| Proxmox Hub | 192.168.3.10 | 8384 | `/usr/local/bin/syncthing` | systemd |
| Mac Mini | 192.168.3.30 | 8384 | `~/bin/syncthing` | launchd |
| Steam Deck | 192.168.0.161 | 8384 | `~/bin/syncthing` | systemd user + linger |

## Syncthing Folders (10 total)

### Save Folders (Send & Receive — Deck ↔ PVE)

| Folder ID | Contents | Size |
|-----------|----------|------|
| `saves-retroarch` | Pokemon Black (.srm/.sav/.dsv) | 1.5MB |
| `saves-retroarch-states` | Crazy Taxi, Pokemon Black save states | 11MB |
| `saves-dolphin` | Smash Bros, Pokemon XD, Hit & Run (.gci) | 458KB |
| `saves-pcsx2` | PS2 memory cards (Mcd001 + Mcd002) | 16.6MB |
| `saves-yuzu` | Switch saves (Mario 64/Sunshine/Galaxy, RDR2) | 12MB |
| `saves-xemu` | Xbox EEPROM | <1KB |
| `saves-cemu` | Wii U saves | varies |

### Delta Bridge Folder (Send & Receive — Deck ↔ PVE ↔ Mac Mini)

| Folder ID | Contents | Size |
|-----------|----------|------|
| `saves-delta-bridge` | Delta ↔ RetroArch converted saves | ~1MB |

### Backup Folders (Send Only → Receive Only — Deck → NAS via PVE)

| Folder ID | Contents | Size |
|-----------|----------|------|
| `roms` | 181 system dirs, all game files | 105GB |
| `bios` | BIOS/firmware for 35+ platforms | 342MB |

## Delta ↔ RetroArch Save Bridge

The key challenge: Delta (iPhone) uses SHA-1 hashed filenames for saves (`GameSave-<hash>-gameSave`), while RetroArch names saves after the ROM file. A bridge script translates between the two.

### How it works

1. **Delta** saves to Dropbox at `Dropbox/Delta Emulator/`
2. **Mac Mini** has Dropbox installed, files sync to `~/Dropbox/Delta Emulator/`
3. **Bridge script** (`~/bin/delta-bridge.py`, launchd every 2 min):
   - Reads Delta `Game-<hash>` metadata files for game name → hash mapping
   - Copies `GameSave-<hash>-gameSave` to `~/delta-bridge/retroarch-saves/<Game Name>.srm`
   - Reverse: copies RetroArch-named saves back with hashed Delta filenames
4. **Syncthing** syncs `delta-bridge/retroarch-saves/` to PVE and Steam Deck
5. **Deck sync script** (`~/bin/delta-deck-sync.py`, systemd timer every 2 min):
   - Copies between `/home/deck/delta-bridge-saves/` and RetroArch's actual save dir

### Current Delta Games with Saves

| Game | System | Hash (first 8) |
|------|--------|----------------|
| Pokemon HeartGold | NDS | `4fcded0e` |
| Pokemon Mystery Dungeon: Explorers of Sky | NDS | `5fa96ca8` |
| Super Mario 64 | N64 | `9bef1128` |
| Zelda: Majora's Mask | N64 | `d6133ace` |
| Pokemon Emerald | GBA | `f3ae0881` |

### Critical: Save File Extensions

melonDS DS core (used on Steam Deck for NDS) creates `.srm` files, NOT `.dsv` or `.sav`. The bridge scripts output `.srm` for NDS saves. This was discovered when HeartGold saves initially didn't load — RetroArch was creating `.srm` while we were placing `.dsv`.

## NAS Storage Layout

```
Games/
├── ROM Library/           (106GB) — Organized by platform name
│   ├── Nintendo DS/
│   ├── Nintendo Game Boy Advance/
│   ├── Nintendo GameCube/
│   ├── Nintendo Switch/
│   ├── Nintendo Wii U/
│   ├── Nintendo Wii/
│   ├── Sega Dreamcast/
│   ├── Sony PlayStation 2/
│   └── Sony PlayStation Portable/
├── Emulators/             (621MB) — BIOS, keys, tools, launchers
├── SteamDeck-Backup/      (113GB) — Full rsync backup (safety net)
├── emulation-backup/      (104GB) — Syncthing live mirror
└── Windows-PC-Saves/              — Unique old Windows PC saves
```

## EmuDeck Save Architecture

EmuDeck splits saves across **two locations**:
- **`Emulation/saves/`** on SD card — AppImage emulators (PCSX2, mGBA, melonDS)
- **`~/.var/app/`** on internal SSD — Flatpak emulators (RetroArch, Dolphin, PPSSPP)

The `Emulation/saves/` entries for Flatpak emulators are **symlinks** to `~/.var/app/` paths. Additionally:
- **Yuzu saves** live in `Emulation/storage/yuzu/nand/user/save/` (not saves/yuzu/)
- **Cemu saves** live in `Emulation/roms/wiiu/mlc01/usr/save/` (inside ROMs dir)
