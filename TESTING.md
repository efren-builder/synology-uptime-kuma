# Testing Checklist for Uptime Kuma SPK

Use this checklist to verify the Uptime Kuma SPK package before release or PR submission.

## 1. Pre-Build Checks

- [ ] `cross/uptime-kuma/digests` contains the correct SHA256 hash for the source tarball
- [ ] `SPK_VERS` in `spk/uptime-kuma/Makefile` matches `PKG_VERS` in `cross/uptime-kuma/Makefile`
- [ ] `SPK_VERS` in `spk/uptime-kuma/Makefile` matches `version` in `spk/uptime-kuma/INFO.sh`
- [ ] All JSON files are valid (`install_uifile`, `upgrade_uifile`, `conf/privilege`, `conf/resource`)
- [ ] Icon file `src/uptime-kuma.png` exists and is a valid PNG (256x256)
- [ ] All `DESCRIPTION_*` files exist and contain non-empty text
- [ ] `service-setup.sh` has no syntax errors: `bash -n src/service-setup.sh`

## 2. Build Verification

### Architecture Builds

- [ ] `make arch-x64-7.1` completes without errors (x86_64)
- [ ] `make arch-aarch64-7.1` completes without errors (ARM64)
- [ ] `make arch-armv7-7.1` completes without errors (ARMv7)
- [ ] `make all-supported` completes without errors (all architectures)

### Build Output

- [ ] `.spk` files are generated in `packages/` directory
- [ ] SPK file is a valid tar archive: `tar -tf <file>.spk`
- [ ] SPK contains: `INFO`, `package.tgz`, `scripts/`, `conf/`, `PACKAGE_ICON.PNG`, `PACKAGE_ICON_256.PNG`
- [ ] `package.tgz` contains: `uptime-kuma/server/`, `uptime-kuma/dist/`, `uptime-kuma/node_modules/`, `uptime-kuma/package.json`
- [ ] `scripts/` contains: `start-stop-status`, `installer`, `service-setup`
- [ ] `INFO` file contains correct `package`, `version`, `os_min_ver`, `adminport` values

## 3. Installation Testing

### Fresh Install

Perform on each available architecture:

- [ ] **x86_64 NAS** (e.g., DS220+, DS920+)
- [ ] **aarch64 NAS** (e.g., DS223, DS224+)
- [ ] **armv7 NAS** (e.g., DS218, DS118) [lower priority]

For each architecture:

- [ ] Upload `.spk` via Package Center > Manual Install
- [ ] Installation wizard displays correctly with port field
- [ ] Default port value is 3001
- [ ] Port validation rejects invalid values (0, 99999, abc)
- [ ] Node.js_v22 installs automatically as a dependency (if not already installed)
- [ ] Installation completes without errors
- [ ] Package appears in Package Center with correct name and icon
- [ ] Service starts automatically after installation
- [ ] Package status shows "Running" in Package Center
- [ ] Web UI is accessible at `http://<NAS_IP>:<port>`
- [ ] Admin account creation screen appears on first visit
- [ ] Data directory `/var/packages/uptime-kuma/var/` exists with correct permissions
- [ ] Log file is created at expected location
- [ ] Service user `sc-uptime-kuma` exists: `id sc-uptime-kuma`

### Upgrade Install

- [ ] Install the previous version (or current version for testing the mechanism)
- [ ] Create test monitors and configure at least one notification
- [ ] Perform upgrade via Package Center > Manual Install with new `.spk`
- [ ] Upgrade wizard displays with data preservation notice
- [ ] Upgrade completes without errors
- [ ] Service restarts after upgrade
- [ ] All monitors are preserved and functioning
- [ ] Notification configurations are preserved
- [ ] Status page configurations are preserved
- [ ] SQLite database is intact: `sqlite3 /var/packages/uptime-kuma/var/kuma.db "PRAGMA integrity_check;"`

## 4. Service Lifecycle Testing

- [ ] **Stop** via Package Center: service stops, status shows "Stopped"
- [ ] **Start** via Package Center: service starts, status shows "Running"
- [ ] **Stop then Start** via command line:
  ```bash
  synopkg stop uptime-kuma
  synopkg start uptime-kuma
  ```
- [ ] **Status check** returns correct state:
  ```bash
  synopkg status uptime-kuma
  ```
- [ ] **NAS reboot**: Service starts automatically after reboot
- [ ] **Node.js_v22 stop**: Uptime Kuma fails gracefully with a clear error
- [ ] **Node.js_v22 restart**: Uptime Kuma can be restarted after Node.js returns

## 5. Feature Testing

### Core Monitoring

- [ ] Create an HTTP(s) monitor -- verify heartbeat checks run
- [ ] Create a TCP port monitor -- verify connection checks
- [ ] Create a Ping monitor -- verify ICMP checks
- [ ] Create a DNS monitor -- verify DNS resolution checks
- [ ] Monitor status updates in real-time (WebSocket)
- [ ] Response time graph displays data points
- [ ] Uptime percentage calculates correctly

### Notifications

- [ ] Configure at least one notification provider (e.g., Email/SMTP, Telegram, or webhook)
- [ ] Test notification button sends a test alert
- [ ] Trigger a real down alert by monitoring a non-existent host
- [ ] Verify notification is received

### Status Pages

- [ ] Create a public status page
- [ ] Add monitors to the status page
- [ ] Access the status page URL from a browser
- [ ] Status page displays correct monitor states

### Authentication

- [ ] Log out and log back in
- [ ] Enable 2FA (TOTP) in Settings > Security
- [ ] Log out and log back in with 2FA code
- [ ] Disable 2FA

### API

- [ ] Create an API key in Settings
- [ ] Access `/metrics` endpoint (Prometheus format)
- [ ] Access status badge endpoints

## 6. DSM Version Testing

Test on each available DSM version:

- [ ] **DSM 7.0** -- Package installs and runs
- [ ] **DSM 7.1** -- Package installs and runs
- [ ] **DSM 7.2** -- Package installs and runs

## 7. Uninstall Testing

- [ ] Stop the service from Package Center
- [ ] Uninstall the package from Package Center
- [ ] Uninstallation completes without errors
- [ ] Package no longer appears in Package Center
- [ ] Service user is removed (or handled per DSM conventions)
- [ ] Verify data directory state (should be handled per SynoCommunity conventions)

## 8. Edge Cases

### Port Conflicts

- [ ] Install with port 3001 when another service uses 3001 -- expect a clear error or warning
- [ ] Install with a custom port (e.g., 3456) -- verify service binds to the custom port

### Disk Space

- [ ] Attempt install on a volume with less than 500 MB free -- expect installation to abort with a clear message

### Network

- [ ] Access the web UI from a different subnet/VLAN
- [ ] Access through DSM reverse proxy with WebSocket headers
- [ ] Access via HTTPS (if SSL configured in Uptime Kuma settings)

### Data Integrity

- [ ] Simulate unexpected NAS shutdown (pull power) -- verify database recovers on restart
- [ ] Create 50+ monitors -- verify performance is acceptable
- [ ] Run for 24+ hours -- verify no memory leaks or crashes

### Permissions

- [ ] Verify service runs as `sc-uptime-kuma`, not root: `ps aux | grep uptime`
- [ ] Verify data directory is owned by `sc-uptime-kuma`
- [ ] Verify `/var/packages/uptime-kuma/target/` is not writable by the service user

## Test Environment Record

Document your test environment for each test run:

| Field | Value |
|-------|-------|
| NAS Model | |
| Architecture | |
| DSM Version | |
| RAM | |
| SPK Version | |
| Date Tested | |
| Tester | |
| Result | Pass / Fail |
| Notes | |
