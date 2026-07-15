---
date: 2026-04-02
tags:
  - homelab
  - discord
  - media
  - arr
parent: "[[Homelab 3.0]]"
status: active
---

# Requestrr

Discord bot for media requests — users type `/movie` or `/tv` to search and request content, which gets sent to [[Arr Stack]] (Sonarr/Radarr).

## Configuration

| Setting | Value |
|---------|-------|
| Container | `thomst08/requestrr:latest` |
| Host | LXC 105 (monitoring), port 4545 |
| Web UI | http://192.168.3.21:4545 |
| Admin | admin / Changeme123 |

## Discord Bot

| Setting | Value |
|---------|-------|
| Application ID | 1489236705704935524 |
| Notification Channel | `#media-requests` (ID: 1489236212249137254) |
| Required Intents | Presence, Server Members, Message Content |
| Scopes | bot, applications.commands |
| Permissions | Send Messages, Read Messages, Embed Links, Use Slash Commands, Read Message History |

## Connected Services

| Service | Hostname | Port | API Key |
|---------|----------|------|---------|
| Radarr (Movies) | 192.168.3.25 | 7878 | `aceddf6cd9a943cfb2aa6d95bee69c87` |
| Sonarr (TV) | 192.168.3.25 | 8989 | `1341f7db6b1d41908e9357253f3f15e6` |

## Discord Commands

| Command | Description |
|---------|------------|
| `/movie <search>` | Search and request a movie (sends to Radarr) |
| `/tv <search>` | Search and request a TV show (sends to Sonarr) |

## Setup Notes

- Bot must be invited to the Discord server with the OAuth2 URL containing bot + applications.commands scopes
- All three Privileged Gateway Intents must be enabled in the Discord Developer Portal
- Slash commands take ~1 minute to propagate globally after saving in the Requestrr UI
- Regenerating the bot token invalidates the previous one — update in Requestrr immediately
