# Uptime Kuma for Synology NAS

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Uptime Kuma](https://img.shields.io/badge/Uptime%20Kuma-v2.1.0-brightgreen)](https://github.com/louislam/uptime-kuma)
[![DSM](https://img.shields.io/badge/DSM-7.0%2B-blue)](https://www.synology.com/dsm)
[![SynoCommunity](https://img.shields.io/badge/SynoCommunity-spksrc-orange)](https://synocommunity.com)

A native Synology SPK package for [Uptime Kuma](https://github.com/louislam/uptime-kuma), the self-hosted monitoring tool. Install Uptime Kuma directly from Package Center -- no Docker required.

## Features

Uptime Kuma is a full-featured, self-hosted monitoring solution:

- **22 Monitor Types** -- HTTP(s), TCP, Ping, DNS, Docker, MQTT, WebSocket, gRPC, PostgreSQL, MySQL, Redis, MongoDB, SNMP, Kafka, Radius, Steam Game Server, GameDig, Real Browser, and more
- **87+ Notification Providers** -- Telegram, Discord, Slack, Email (SMTP), Microsoft Teams, Pushover, Gotify, Ntfy, PagerDuty, Opsgenie, and dozens more, plus Apprise integration
- **Status Pages** -- Public status pages with custom domains, branding, and service grouping
- **2FA Authentication** -- Secure your dashboard with two-factor authentication (TOTP)
- **Certificate Monitoring** -- Track SSL/TLS certificate expiry with alerts
- **Response Time Graphs** -- Historical performance visualization with sparklines
- **Uptime Statistics** -- 24-hour, 30-day, and 1-year uptime percentages
- **Maintenance Windows** -- Schedule downtime without triggering alerts
- **Proxy Support** -- Per-monitor HTTP, SOCKS4, and SOCKS5 proxy configuration
- **Multi-Language** -- Full internationalization with 30+ languages
- **API Access** -- REST API and Socket.IO API for automation
- **Prometheus Metrics** -- `/metrics` endpoint for Grafana integration
- **Dynamic Badges** -- SVG badges for README files and dashboards (shields.io compatible)

## Screenshots

<!-- Replace these placeholders with actual screenshots -->
| Dashboard | Status Page |
|:---------:|:-----------:|
| ![Dashboard](screenshots/dashboard.png) | ![Status Page](screenshots/status-page.png) |

| Monitor Config | Notifications |
|:--------------:|:-------------:|
| ![Monitor Config](screenshots/monitor-config.png) | ![Notifications](screenshots/notifications.png) |

See [screenshots/README.md](screenshots/README.md) for capture guidelines.

## Installation

### From SynoCommunity Package Center

1. Open **Package Center** in DSM
2. Go to **Settings** > **Package Sources**
3. Add a new source:
   - **Name:** `SynoCommunity`
   - **Location:** `https://packages.synocommunity.com`
4. Click **OK**, then browse the **Community** tab
5. Search for **Uptime Kuma** and click **Install**
6. Follow the installation wizard to configure the service port

### Manual Install

1. Download the `.spk` file for your architecture from the [Releases](https://github.com/SynoCommunity/spksrc/releases) page
2. Open **Package Center** in DSM
3. Click **Manual Install** (upper-right corner)
4. Browse to the downloaded `.spk` file and click **Next**
5. Follow the installation wizard
6. Click **Apply** to install

## Configuration

### First-Time Setup

After installation, the service starts automatically on port **3001** (or the port you chose during installation).

1. Open your browser and navigate to `http://<NAS_IP>:3001`
2. Create your admin account (username and password)
3. Optionally enable 2FA in **Settings > Security**
4. Start adding monitors

You can also access Uptime Kuma from DSM by clicking the package icon in **Package Center > Installed**.

### Port Configuration

The default port is **3001**. You can change it during installation via the setup wizard. To change it after installation:

1. Stop the package in Package Center
2. Edit the port configuration through DSM or update the service port setting
3. Restart the package

### Reverse Proxy with DSM

If you want to access Uptime Kuma through a domain name with HTTPS:

1. Open **Control Panel > Login Portal > Advanced > Reverse Proxy**
2. Create a new rule:
   - **Source:** HTTPS, your domain, port 443
   - **Destination:** HTTP, localhost, port 3001
3. Under **Custom Header**, add WebSocket support:
   - `Upgrade` : `$http_upgrade`
   - `Connection` : `$connection_upgrade`

WebSocket headers are required for Uptime Kuma's real-time updates.

## Requirements

| Requirement | Details |
|-------------|---------|
| **DSM Version** | 7.0 or later |
| **Node.js** | Node.js_v22 (auto-installed as a dependency) |
| **RAM** | 512 MB minimum available (1 GB recommended for 50+ monitors) |
| **Disk Space** | 500 MB minimum for installation |
| **Architecture** | x86_64 (Intel/AMD), aarch64 (ARM64), armv7 (ARMv7) |

### Supported NAS Models (Examples)

| Architecture | Example Models |
|-------------|----------------|
| x86_64 | DS220+, DS720+, DS920+, DS1621+, DS1821+ |
| aarch64 | DS220j, DS420j, DS223, DS224+ |
| armv7 | DS218, DS118 (older Marvell Armada models) |

## Building from Source

See [BUILD.md](BUILD.md) for detailed build instructions.

### Quick Start

```bash
# Clone the spksrc repository
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc

# Copy (or symlink) the Uptime Kuma package files
cp -r /path/to/this/repo/cross/uptime-kuma cross/
cp -r /path/to/this/repo/spk/uptime-kuma spk/

# Build for a specific architecture
cd spk/uptime-kuma
make arch-x64-7.1

# Build for all supported architectures
make all-supported
```

Built `.spk` files are placed in `spksrc/packages/`.

## Upgrading

### Via Package Center

1. When a new version is available, Package Center shows an **Update** notification
2. Click **Update** and follow the on-screen prompts
3. Your monitoring data (database, uploads, configuration) is preserved automatically

### Manual Upgrade

1. Download the new `.spk` file
2. Go to **Package Center > Manual Install**
3. Select the new `.spk` file
4. The upgrade wizard confirms data will be preserved
5. Click **Apply**

The upgrade process:
1. Stops the running service
2. Backs up the data directory (`/var/packages/uptime-kuma/var/`)
3. Replaces the application files
4. Restores the data directory
5. Restarts the service

## Backup and Restore

### Using Hyper Backup

Uptime Kuma stores all data in `/var/packages/uptime-kuma/var/`, which includes:
- SQLite database (all monitors, settings, heartbeat history)
- Uploaded assets (status page logos, etc.)

To back up with Hyper Backup:
1. Open **Hyper Backup** and create or edit a backup task
2. Under **Application**, select **Uptime Kuma** (if listed)
3. Alternatively, back up the shared folder `uptime-kuma`
4. Schedule regular backups

### Manual Backup

```bash
# Stop the service first to ensure database consistency
synopkg stop uptime-kuma

# Copy the data directory
cp -a /var/packages/uptime-kuma/var/ /volume1/backups/uptime-kuma-$(date +%Y%m%d)/

# Restart the service
synopkg start uptime-kuma
```

### Restore

1. Stop the Uptime Kuma service
2. Replace the contents of `/var/packages/uptime-kuma/var/` with your backup
3. Ensure correct ownership: `chown -R sc-uptime-kuma:synocommunity /var/packages/uptime-kuma/var/`
4. Start the service

## Troubleshooting

### Service fails to start

**Check logs:**
```bash
cat /var/log/packages/uptime-kuma.log
cat /var/packages/uptime-kuma/var/uptime-kuma.log
```

**Verify Node.js is installed:**
```bash
/var/packages/Node.js_v22/target/usr/local/bin/node --version
```
If this fails, reinstall the Node.js_v22 package from Package Center.

### Port conflict

If port 3001 is already in use by another service:
1. Check what is using the port: `netstat -tlnp | grep 3001`
2. Reinstall with a different port, or stop the conflicting service

### WebSocket issues behind reverse proxy

Uptime Kuma relies on WebSocket (Socket.IO) for real-time updates. If you see connection errors or the dashboard does not update in real-time:

1. Ensure your reverse proxy forwards WebSocket headers (see [Reverse Proxy with DSM](#reverse-proxy-with-dsm) above)
2. If using a third-party reverse proxy (nginx, Caddy, Traefik), add:
   ```nginx
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "upgrade";
   ```

### Permission errors

If you see permission-denied errors in logs:
```bash
# Fix ownership on the data directory
chown -R sc-uptime-kuma:synocommunity /var/packages/uptime-kuma/var/
chmod 750 /var/packages/uptime-kuma/var/
```

### Database corruption

SQLite databases can become corrupted if the NAS loses power unexpectedly. To recover:
1. Stop the service
2. Check the database: `sqlite3 /var/packages/uptime-kuma/var/kuma.db "PRAGMA integrity_check;"`
3. If corrupt, restore from your most recent backup

**Important:** Never store the Uptime Kuma data directory on an NFS mount. SQLite requires local filesystem locking (ext4 or Btrfs).

### High memory usage

If Uptime Kuma uses excessive memory:
- Reduce the number of active monitors
- Increase monitoring intervals (60s instead of 20s)
- Ensure you have at least 512 MB of available RAM

## Package Details

| Field | Value |
|-------|-------|
| Package Name | `uptime-kuma` |
| Display Name | Uptime Kuma |
| Version | 2.1.0-1 |
| Service Port | 3001 (configurable) |
| Service User | `sc-uptime-kuma` |
| Install Path | `/var/packages/uptime-kuma/target/` |
| Data Path | `/var/packages/uptime-kuma/var/` |
| Log Path | `/var/log/packages/uptime-kuma.log` |
| Dependencies | Node.js_v22 |
| DSM Minimum | 7.0-40000 |

## Credits

- **[Uptime Kuma](https://github.com/louislam/uptime-kuma)** by [Louis Lam](https://github.com/louislam) -- the monitoring application
- **[SynoCommunity](https://synocommunity.com)** -- community package repository and spksrc build system
- **Contributors** -- see [CONTRIBUTING.md](CONTRIBUTING.md)

## License

This SPK package is released under the [MIT License](LICENSE), matching the Uptime Kuma project license.

Uptime Kuma itself is copyright (c) Louis Lam and contributors, released under the MIT License.
