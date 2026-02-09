# Changelog

All notable changes to the Uptime Kuma SPK package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1.0-1] - 2026-02-08

### Added
- Initial SPK package release for Synology NAS
- Uptime Kuma v2.1.0
- 22 monitor types: HTTP(s), HTTP(s) Keyword, HTTP(s) JSON Query, TCP, Ping, DNS, Push, Steam Game Server, Docker Container, MQTT, WebSocket, Radius, MySQL/MariaDB, PostgreSQL, MongoDB, Microsoft SQL Server, Redis, gRPC(s), SNMP, Kafka, GameDig, Real Browser
- 87+ native notification providers (Telegram, Discord, Slack, Email, Teams, Pushover, Gotify, PagerDuty, and many more)
- Apprise integration for additional notification services
- Public status pages with custom domain support
- Two-factor authentication (2FA/TOTP)
- SSL/TLS certificate expiry monitoring and alerts
- Response time graphs and uptime statistics (24h, 30d, 1y)
- Maintenance window scheduling
- Per-monitor proxy support (HTTP, SOCKS4, SOCKS5)
- REST API and Socket.IO API with API key authentication
- Prometheus metrics endpoint for Grafana integration
- Dynamic SVG badge generation (shields.io compatible)
- Cloudflare Tunnel integration
- DSM 7.0+ support with proper privilege separation (non-root execution)
- Multi-architecture support (x86_64, aarch64, armv7)
- Installation wizard with configurable port
- Upgrade wizard with data preservation notice
- Automatic service management (start/stop/status via Package Center)
- Data persistence across package upgrades (automatic backup and restore)
- Multi-language Package Center descriptions (English, French, German, Spanish, Japanese, Chinese Simplified)
- Localized installation wizards (English, French, German, Spanish)
- Node.js_v22 dependency (auto-installed via Package Center)
- Disk space validation during installation (500 MB minimum)
- Node.js availability checks at install and startup
- Structured logging with timestamps
- Port configuration via Synology firewall integration
- Service user `sc-uptime-kuma` with minimal privileges
