# Changelog

All notable changes to OpenWatchParty will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Improved sync when joining room during playback
- Play button on Watch Party cards to start playback and auto-join

## [0.3.0] - 2026-01-15

### Added
- Auto-cleanup when leaving video player
- Sync status indicator (synced/syncing/pending_play)
- Watch Parties section on Jellyfin homepage with native styling

### Changed
- Optimized UX latency with reduced state update intervals
- Room name now shows username instead of "Anonymous"

### Fixed
- Room name display issue

## [0.2.0] - 2026-01-14

### Added
- JWT caching for better performance
- Video element caching
- Event listener cleanup for memory leak prevention
- Arc for origins to avoid Vec cloning
- Pending timer cleanup

### Changed
- Optimized room list serialization (single pass)
- Improved escapeHtml function performance

### Fixed
- Critical lock contention issues
- Unbounded channels causing memory issues
- Memory leaks in event listeners

## [0.1.0] - 2026-01-13

### Added
- Initial release
- Jellyfin plugin for Watch Party functionality
- Rust WebSocket session server
- Real-time playback synchronization
- Room creation and management
- Host/participant model
- Clock synchronization (NTP-like)
- Drift correction with sqrt curve
- HLS streaming support with feedback loop prevention
- Ready/pending play mechanism
- JWT authentication support
- Rate limiting (30 msg/sec per client)
- Home page Watch Parties section

### Fixed
- Seek position mismatch
- Seek delay by including play_state in seek event
- Play delay by optimizing server-side ready waiting
- Seek loop during buffering
- Sync latency and drift catch-up
- Drift chase after buffering
- Token rate limiting on WebSocket reconnects
- Input field keyboard capture
- Docker file ownership for host user access

### Security
- Fixed 9 low priority issues from security audit
- Fixed 12 medium priority issues from security audit

[Unreleased]: https://github.com/username/OpenWatchParty/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/username/OpenWatchParty/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/username/OpenWatchParty/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/username/OpenWatchParty/releases/tag/v0.1.0
