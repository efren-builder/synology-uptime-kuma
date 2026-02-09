# Validation Report — Uptime Kuma SPK Package

**Date:** 2026-02-08
**Reviewer:** Team Lead
**Overall Status:** PASS (with notes)

---

## Checklist

### Makefiles
- [x] `spk/uptime-kuma/Makefile` — All required SPK_ variables present
- [x] `spk/uptime-kuma/Makefile` — Correct `include ../../mk/spksrc.spk.mk`
- [x] `spk/uptime-kuma/Makefile` — DEPENDS = cross/uptime-kuma
- [x] `spk/uptime-kuma/Makefile` — SPK_DEPENDS = "Node.js_v22"
- [x] `spk/uptime-kuma/Makefile` — SERVICE_ variables correct (PORT=3001, USER=auto, SETUP=src/service-setup.sh)
- [x] `spk/uptime-kuma/Makefile` — POST_STRIP_TARGET installs .sc file
- [x] `cross/uptime-kuma/Makefile` — PKG_NAME, PKG_VERS, PKG_DIST_SITE correct
- [x] `cross/uptime-kuma/Makefile` — npm ci --omit dev (production only)
- [x] `cross/uptime-kuma/Makefile` — Downloads pre-built frontend dist
- [x] `cross/uptime-kuma/Makefile` — Correct include ../../mk/spksrc.cross-cc.mk
- [x] `Makefile` (top-level) — Delegates correctly to spk/ and cross/

### Scripts
- [x] `service-setup.sh` — Bash syntax valid
- [x] `service-setup.sh` — NODE path correct: /var/packages/Node.js_v22/target/usr/local/bin/node
- [x] `service-setup.sh` — SERVICE_COMMAND points to correct server.js path
- [x] `service-setup.sh` — SVC_BACKGROUND=y, SVC_WRITE_PID=y
- [x] `service-setup.sh` — Exports UPTIME_KUMA_HOST, UPTIME_KUMA_PORT, DATA_DIR, NODE_ENV
- [x] `service-setup.sh` — validate_preinst() checks Node.js, disk space
- [x] `service-setup.sh` — service_postinst() creates data dir, sets permissions
- [x] `service-setup.sh` — service_prestart() verifies Node.js, server.js, data dir
- [x] `service-setup.sh` — service_preupgrade() backs up data to TMP_DIR
- [x] `service-setup.sh` — service_postupgrade() restores data from TMP_DIR
- [x] `service-setup.sh` — Robust error handling throughout

### JSON Configuration
- [x] `conf/privilege` — Valid JSON, has "run-as": "package" (DSM 7 mandatory)
- [x] `conf/resource` — Valid JSON, has port-config + data-share
- [x] `conf/resource` — port-config references "app/uptime-kuma.sc"
- [x] `conf/resource` — data-share grants rw to "sc-uptime-kuma"
- [x] `app/uptime-kuma.sc` — Correct format, port 3001/tcp

### Wizard Files
- [x] `install_uifile` — Valid JSON array with step
- [x] `install_uifile` — Port config field with regex validator (1024-65535)
- [x] `install_uifile` — Service user info (sc-uptime-kuma)
- [x] `install_uifile` — Data directory info
- [x] `install_uifile` — Wiki link
- [x] `upgrade_uifile` — Valid JSON, backup reminder
- [x] `install_uifile_fre` — French localization exists
- [x] `install_uifile_ger` — German localization exists
- [x] `install_uifile_spn` — Spanish localization exists

### INFO.sh
- [x] All required fields: package, version, os_min_ver, description, arch, maintainer
- [x] install_dep_packages includes Node.js_v22
- [x] adminport=3001 matches SERVICE_PORT
- [x] startable=yes
- [x] checkport=yes

### Icons & UI
- [x] `icons/uptime-kuma.svg` — Well-formed SVG, professional design
- [x] `scripts/generate-icons.sh` — Downloads and resizes icons
- [x] 6 language description files (enu, fre, ger, spn, jpn, chs)

### Documentation
- [x] README.md — Comprehensive with install, config, troubleshooting
- [x] CHANGELOG.md — Proper format
- [x] LICENSE — MIT
- [x] BUILD.md — spksrc build instructions
- [x] CONTRIBUTING.md — Contribution guide
- [x] SYNOCOMMUNITY_PR.md — Ready-to-use PR template
- [x] TESTING.md — Comprehensive test checklist
- [x] screenshots/README.md — Screenshot guide

### Consistency
- [x] Port 3001 consistent across: SPK Makefile, INFO.sh, service-setup.sh, uptime-kuma.sc, install_uifile, upgrade_uifile
- [x] Package name "uptime-kuma" consistent across all files
- [x] Version "2.1.0" consistent across SPK Makefile, cross Makefile, INFO.sh, digests
- [x] User "sc-uptime-kuma" consistent in conf/resource and wizard descriptions
- [x] Node.js path consistent in service-setup.sh and cross/Makefile

---

## Issues Found & Fixed

### Fixed: arch="noarch" in INFO.sh (CRITICAL)
- **Problem:** INFO.sh had `arch="noarch"` but the package uses cross-compilation (native @louislam/sqlite3 module needs per-arch builds)
- **Fix:** Changed to `arch="x86_64 aarch64 armv7"` to match the cross-compilation setup
- **Note:** The spksrc framework may override this from the Makefile, but having correct arch in INFO.sh is important for standalone builds

### Fixed: Missing SHA256 hash in digests (CRITICAL)
- **Problem:** digests file had a placeholder instead of actual hash
- **Fix:** Downloaded the v2.1.0 tarball and computed: `4514170107a914f79f7831d7b6fa76ca18e59b2da7185c8826d6faae6633203d`

---

## Notes (non-blocking)

### Manual Steps Required Before Build
1. **Generate PNG icons** — Run `scripts/generate-icons.sh` to create PACKAGE_ICON.PNG (64x64) and PACKAGE_ICON_256.PNG (256x256) from the SVG or official Uptime Kuma icon
2. **Replace placeholder icon** — Copy the 256x256 PNG to `spk/uptime-kuma/src/uptime-kuma.png`

### Manual Steps Required Before SynoCommunity Submission
1. **Build test** — Run `make all-supported` in a spksrc Docker environment
2. **Install test** — Test .spk on actual Synology NAS (x86_64 and ARM)
3. **Upgrade test** — Install older version, then upgrade to verify data preservation
4. **Port 3001 conflict test** — Verify no DSM services conflict
5. **Screenshot capture** — Take screenshots per screenshots/README.md guide

### Architecture Consideration
The cross/uptime-kuma/Makefile currently runs `npm ci` which will download architecture-appropriate prebuilt binaries for @louislam/sqlite3. This should work correctly for x86_64, aarch64, and armv7 as the npm package provides prebuilts for all three. If prebuilts are unavailable for a specific arch, node-gyp will attempt compilation (requires Python 3, GCC, make on the build host).

---

## File Count: 34 files
## Status: READY FOR BUILD TESTING
