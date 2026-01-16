---
title: Home
layout: home
nav_order: 1
---

# OpenWatchParty Documentation

OpenWatchParty is a Jellyfin plugin that enables synchronized media playback across multiple clients. Watch movies and shows together with friends, no matter where they are.

## Quick Links

| Getting Started | For Developers | Operations |
|-----------------|----------------|------------|
| [Overview](product/overview) | [Architecture](technical/architecture) | [Installation](operations/installation) |
| [Features](product/features) | [Protocol](technical/protocol) | [Configuration](operations/configuration) |
| [User Guide](product/user-guide) | [Server](technical/server) | [Deployment](operations/deployment) |
| [FAQ](product/faq) | [Client](technical/client) | [Security](operations/security) |
| | [Plugin](technical/plugin) | [Troubleshooting](operations/troubleshooting) |
| | [Sync Algorithms](technical/sync) | [Monitoring](operations/monitoring) |
| | [REST API](technical/api) | |

## Development

- [Development Setup](development/setup) - Get started contributing
- [Contributing Guide](development/contributing) - Code style and PR process
- [Testing](development/testing) - Running tests
- [Release Process](development/release) - How releases are made

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Jellyfin Web   │     │  Session Server │     │  Jellyfin Web   │
│    (Host)       │◄───►│     (Rust)      │◄───►│   (Clients)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                        │                       │
        └────────────────────────┴───────────────────────┘
                         WebSocket (ws://)
```

**Components:**
- **Jellyfin Plugin (C#)** - Serves client JavaScript, provides configuration UI
- **Session Server (Rust)** - Manages rooms and relays sync messages via WebSocket
- **Web Client (JavaScript)** - Injected into Jellyfin UI, handles playback synchronization

## Glossary

Technical terms used throughout this documentation:

| Term | Full Name | Description |
|------|-----------|-------------|
| **HLS** | HTTP Live Streaming | Adaptive streaming protocol that breaks video into small segments. Used by Jellyfin for transcoded content. |
| **RTT** | Round-Trip Time | Time for a message to travel from client to server and back. Displayed in the Watch Party panel as latency indicator. |
| **EMA** | Exponential Moving Average | Smoothing algorithm used for clock synchronization. Prevents sudden jumps in time offset. |
| **JWT** | JSON Web Token | Compact, URL-safe token format for authentication. Contains user identity claims signed with a secret key. |
| **CORS** | Cross-Origin Resource Sharing | Browser security mechanism controlling which websites can connect to the session server. |
| **WebSocket** | - | Full-duplex communication protocol over a single TCP connection. Used for real-time sync. |
| **Drift** | - | Difference between expected and actual playback position. Corrected by adjusting playback rate. |
| **Host** | - | The user who created the watch party room. Has exclusive control over playback. |
