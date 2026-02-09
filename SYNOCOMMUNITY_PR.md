# SynoCommunity Pull Request: Uptime Kuma SPK

Use this as a template when submitting the Uptime Kuma package to [SynoCommunity/spksrc](https://github.com/SynoCommunity/spksrc).

---

## PR Title

`[new package] uptime-kuma: Add Uptime Kuma monitoring tool v2.1.0`

---

## PR Description

### New Package: uptime-kuma

**Software:** [Uptime Kuma](https://github.com/louislam/uptime-kuma)
**Version:** 2.1.0
**License:** MIT
**Homepage:** https://uptime.kuma.pet
**Author:** [Louis Lam](https://github.com/louislam) (82.6k GitHub stars, 907 contributors)

### Description

Uptime Kuma is a self-hosted monitoring tool with a clean, modern interface. It supports 22 monitor types (HTTP, TCP, Ping, DNS, Docker, MQTT, WebSocket, gRPC, databases, and more) with 87+ native notification providers (Telegram, Discord, Slack, Email, Teams, PagerDuty, etc.). Features include public status pages, 2FA authentication, SSL certificate monitoring, response time graphs, maintenance windows, and Prometheus metrics.

This is the most-requested self-hosted monitoring tool that currently lacks a native Synology package -- all existing Synology installations rely on Docker.

### Package Design

- **Runtime dependency:** `Node.js_v22` (Synology's official package)
- **Build strategy:** Downloads source from GitHub, runs `npm ci --omit dev`, downloads pre-built frontend dist
- **Service management:** Uses spksrc service framework (`SERVICE_USER = auto`, `SVC_BACKGROUND=y`)
- **Data persistence:** Data stored in `/var/packages/uptime-kuma/var/`, preserved across upgrades
- **Port:** 3001 (configurable via installation wizard)

### Files Added

```
cross/uptime-kuma/
  Makefile              # Download, npm install, frontend dist download, staging
  digests               # SHA256 checksum for source tarball

spk/uptime-kuma/
  Makefile              # Package metadata, service config, build targets
  INFO.sh               # Package Center metadata (standalone builds)
  src/
    service-setup.sh    # Lifecycle hooks (install, upgrade, start, stop)
    uptime-kuma.png     # Package icon (256x256)
    conf/privilege       # DSM 7 privilege config (run-as: package)
    conf/resource        # Port config + data-share
    app/uptime-kuma.sc  # Firewall port registration
    wizard/
      install_uifile         # Installation wizard (EN)
      install_uifile_fre     # Installation wizard (FR)
      install_uifile_ger     # Installation wizard (DE)
      install_uifile_spn     # Installation wizard (ES)
      upgrade_uifile         # Upgrade wizard (EN)
    DESCRIPTION_enu      # Package description (EN)
    DESCRIPTION_fre      # Package description (FR)
    DESCRIPTION_ger      # Package description (DE)
    DESCRIPTION_spn      # Package description (ES)
    DESCRIPTION_jpn      # Package description (JA)
    DESCRIPTION_chs      # Package description (ZH-CN)
```

### Key Technical Decisions

1. **Node.js_v22 dependency** -- Uses Synology's official Node.js package rather than bundling Node.js. Reduces package size and benefits from Synology's Node.js updates.

2. **Pre-built frontend** -- Downloads the pre-built dist from GitHub Releases instead of building the Vue/Vite frontend during package build. This avoids requiring dev dependencies in the build environment.

3. **Native module handling** -- The `@louislam/sqlite3` fork provides prebuilt binaries for x86_64, aarch64, and armv7 (glibc). These are included via `npm ci` and work without cross-compilation.

4. **Data directory** -- Uses `SYNOPKG_PKGVAR` (`/var/packages/uptime-kuma/var/`) for the SQLite database and uploads, set via the `DATA_DIR` environment variable.

5. **Upgrade safety** -- The `service_preupgrade()` and `service_postupgrade()` hooks back up and restore the entire data directory during upgrades.

### Links

- Uptime Kuma repository: https://github.com/louislam/uptime-kuma
- Uptime Kuma wiki: https://github.com/louislam/uptime-kuma/wiki
- Uptime Kuma demo: https://demo.kuma.pet
- Live demo credentials: Listed on demo page

---

## Build Verification Checklist

- [ ] `make all-supported` completes successfully
- [ ] No build warnings or errors
- [ ] Source tarball SHA256 matches digests file
- [ ] Pre-built frontend dist downloads correctly
- [ ] `npm ci` installs all production dependencies

## Installation Testing Checklist

- [ ] Fresh install on x86_64 NAS (DSM 7.x)
- [ ] Fresh install on aarch64 NAS (DSM 7.x)
- [ ] Fresh install on armv7 NAS (DSM 7.x) [if available]
- [ ] Installation wizard displays correctly
- [ ] Node.js_v22 auto-installs as dependency
- [ ] Service starts automatically after install
- [ ] Web UI accessible at configured port
- [ ] Admin account creation works
- [ ] Monitor creation and heartbeat checks work

## Upgrade Testing Checklist

- [ ] Upgrade from previous version preserves data
- [ ] Upgrade wizard displays data preservation notice
- [ ] Service restarts after upgrade
- [ ] Monitors continue working after upgrade
- [ ] SQLite database intact after upgrade

## Uninstall Testing Checklist

- [ ] Service stops cleanly
- [ ] Package removes without errors
- [ ] Data directory handling follows DSM conventions

## Feature Testing

- [ ] HTTP(s) monitor works
- [ ] Ping monitor works
- [ ] TCP monitor works
- [ ] Notifications send correctly (tested with at least one provider)
- [ ] Status page renders correctly
- [ ] 2FA setup and login works
- [ ] Prometheus metrics endpoint accessible

---

## Notes for Reviewers

- This package follows the same patterns as existing SynoCommunity Node.js packages (similar to Homebridge's dependency approach)
- The `@louislam/sqlite3` native module prebuilts cover all three target architectures
- Port 3001 was chosen as the default since it does not conflict with common DSM services
- Multi-language support includes 6 description languages and 4 wizard languages
