# Uptime Kuma - Complete Architecture & Feature Analysis

**Research Date:** 2026-02-08
**Latest Stable Version:** 2.1.0 (Released February 7, 2026)
**Repository:** https://github.com/louislam/uptime-kuma
**License:** MIT
**Stars:** 82.6k | **Forks:** 7.4k | **Contributors:** 907

---

## 1. Architecture & Technical Details

### Tech Stack
- **Frontend:** Vue 3, Vite.js, Bootstrap 5
- **Backend:** Node.js (Express)
- **Communication:** WebSocket via Socket.io (primary), REST API (secondary)
- **Database:** SQLite (default) or MariaDB (v2.0.0+, optional)
- **Languages:** JavaScript (55.5%), Vue (42.5%), TypeScript (1%)
- **Process Init:** dumb-init (in Docker)

### Node.js Requirements
- **Minimum:** Node.js >= 20.4 (package.json `engines` field)
- **Docker base image:** Node.js 22 on Debian Bookworm Slim
- **Dropped support:** Node.js 14, 16, and 18 are no longer supported in v2

### Key Dependencies

#### Native Modules (Critical for SPK packaging)
- **`@louislam/sqlite3`** - Custom fork of node-sqlite3 by the Uptime Kuma author
  - Fork repo: https://github.com/louislam/node-sqlite3
  - Provides prebuilt binaries for: AMD64 (glibc/musl), ARM64 (glibc/musl), ARMv7 (glibc/musl)
  - ARMv7 requires glibc >= 2.18
  - Falls back to node-gyp source compilation when prebuilts unavailable
  - Published as `@louislam/sqlite3` on npm
  - **This is the primary native compilation challenge for SPK packaging**

#### Core Dependencies
| Package | Purpose |
|---------|---------|
| express | HTTP server framework |
| socket.io | WebSocket real-time communication |
| knex | SQL query builder (supports SQLite + MariaDB) |
| @louislam/sqlite3 | SQLite database driver (native module) |
| axios | HTTP client for monitor checks |
| bcryptjs | Password hashing |
| jsonwebtoken | JWT authentication |
| nodemailer | Email notifications (SMTP) |
| cheerio | HTML parsing for keyword monitoring |
| mqtt | MQTT protocol monitoring |
| net-snmp | SNMP monitoring |
| @grpc/grpc-js | gRPC monitoring |
| web-push | Web push notifications |
| cloudflared | Cloudflare tunnel integration |
| apprise | 78+ notification service integration |
| dayjs | Date/time handling |
| vue (v3) | Frontend framework |
| vite | Frontend build tool |

#### Dev Dependencies (NOT needed for production)
| Package | Purpose |
|---------|---------|
| playwright | E2E testing |
| eslint | Code linting |
| prettier | Code formatting |
| concurrently | Parallel dev processes |

### Default Port
- **Port 3001** (configurable via environment variable or CLI argument)
- Access: `http://localhost:3001`

### Data Directory Structure
- Default location: `./data/` (relative to app root)
- Configurable via `DATA_DIR` env var or `--data-dir=` argument
- Contains:
  - SQLite database file
  - Upload files
  - Configuration data
- **CRITICAL:** NFS is NOT supported (causes SQLite corruption). Local filesystem or Docker volumes only.

### Process Management
- **Standalone:** `node server/server.js` (foreground)
- **PM2 (recommended for non-Docker):**
  ```bash
  npm install pm2 -g
  pm2 install pm2-logrotate
  pm2 start server/server.js --name uptime-kuma
  pm2 save && pm2 startup
  ```
- **Docker:** Uses `dumb-init` as entrypoint, `node server/server.js` as CMD
- **Graceful Shutdown:** 30-second timeout, stops monitors, closes DB, terminates embedded MariaDB
- **Signals:** SIGINT, SIGTERM
- **Error Handling:** Catches unhandledRejection and uncaughtException

### Memory & CPU Usage
- **Lightweight for small setups:** ~100-200MB RAM with a few monitors
- **Scales with monitors:** 20+ monitors can use 40%+ CPU at 60s intervals (older versions)
- **Known issue:** High virtual memory usage (reported up to 21GB virtual with ~99 ping monitors)
- **Docker default limit:** 1GB RAM (can be slow with many monitors)
- **Recommendation for NAS:** 256MB-512MB RAM is comfortable for 20-50 monitors

---

## 2. Environment Variables (Complete List)

### Server Configuration
| Variable | CLI Argument | Default | Description |
|----------|-------------|---------|-------------|
| `DATA_DIR` | `--data-dir=` | `./data/` | Data storage directory |
| `UPTIME_KUMA_HOST` / `HOST` | `--host=` | `::` | Bind address |
| `UPTIME_KUMA_PORT` / `PORT` | `--port=` | `3001` | Listen port |
| `UPTIME_KUMA_SSL_KEY` / `SSL_KEY` | `--ssl-key=` | - | SSL private key path |
| `UPTIME_KUMA_SSL_CERT` / `SSL_CERT` | `--ssl-cert=` | - | SSL certificate path |
| `UPTIME_KUMA_SSL_KEY_PASSPHRASE` | `--ssl-key-passphrase=` | - | SSL key passphrase (v1.21.1+) |
| `UPTIME_KUMA_CLOUDFLARED_TOKEN` | `--cloudflared-token=` | - | Cloudflare Tunnel token (v1.14.0+) |
| `UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN` | `--disable-frame-sameorigin=` | `false` | Disable X-Frame-Options |
| `UPTIME_KUMA_WS_ORIGIN_CHECK` | - | `cors-like` | WebSocket origin validation |
| `UPTIME_KUMA_ALLOW_ALL_CHROME_EXEC` | `--allow-all-chrome-exec=` | `0` | Custom Chromium path (v1.23.0+) |
| `NODE_EXTRA_CA_CERTS` | - | - | Custom CA certificates |
| `NODE_TLS_REJECT_UNAUTHORIZED` | - | - | Disable TLS validation |
| `NODE_OPTIONS` | - | - | Node.js options (e.g., `--insecure-http-parser`) |
| `UPTIME_KUMA_IS_CONTAINER` | - | - | Container detection flag |

### Database Configuration (v2.0.0+)
| Variable | Default | Description |
|----------|---------|-------------|
| `UPTIME_KUMA_DB_TYPE` | `sqlite` | Database type: `sqlite` or `mariadb` |
| `UPTIME_KUMA_DB_HOSTNAME` | - | MariaDB hostname |
| `UPTIME_KUMA_DB_PORT` | `3306` | MariaDB port |
| `UPTIME_KUMA_DB_SOCKET` | - | Unix socket (overrides host/port, v2.1.0+) |
| `UPTIME_KUMA_DB_NAME` | - | Database name |
| `UPTIME_KUMA_DB_USERNAME` | - | Database username |
| `UPTIME_KUMA_DB_PASSWORD` | - | Database password |
| `UPTIME_KUMA_DB_SSL` | `false` | Enable SSL for DB (v2.1.0+) |
| `UPTIME_KUMA_DB_CA` | - | CA cert PEM for SSL (v2.1.0+) |
| `UPTIME_KUMA_DB_POOL_MAX_CONNECTIONS` | `10` | Max concurrent connections (v2.1.0+) |
| `UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB` | - | Enable embedded MariaDB |

### Docker Secret Variants
- `UPTIME_KUMA_DB_PASSWORD_FILE`
- `UPTIME_KUMA_DB_USERNAME_FILE`
- `UPTIME_KUMA_DB_CA_FILE`

### Development/Debug
| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `production` | Environment mode |
| `UPTIME_KUMA_HIDE_LOG` | - | Filter logs (e.g., `debug_monitor,info_monitor`) |
| `SQL_LOG` | - | Set `1` to enable SQL logging |
| `UPTIME_KUMA_LOG_RESPONSE_BODY_MONITOR_ID` | - | Monitor ID for response logging |

---

## 3. Complete Feature List

### Monitor Types
1. **HTTP(s)** - URL monitoring with status code checks
2. **HTTP(s) Keyword** - Check for specific text on web pages
3. **HTTP(s) JSON Query** - Parse and validate JSON responses
4. **TCP** - Port connectivity checks
5. **Ping** - ICMP ping with latency graphs
6. **DNS Record** - DNS resolution verification
7. **Push** - Passive heartbeat monitoring (service pushes to Kuma)
8. **Steam Game Server** - Game server status monitoring
9. **Docker Container** - Container state monitoring (running/stopped/restarting)
10. **MQTT** - MQTT broker/topic monitoring
11. **WebSocket** - WebSocket endpoint monitoring
12. **Radius** - RADIUS authentication monitoring
13. **MySQL/MariaDB** - Database connectivity
14. **PostgreSQL** - Database connectivity
15. **MongoDB** - Database connectivity
16. **Microsoft SQL Server** - Database connectivity
17. **Redis** - Cache/database connectivity
18. **gRPC(s)** - gRPC service monitoring
19. **SNMP** - Network device monitoring
20. **Kafka** - Message broker monitoring
21. **GameDig** - Game server monitoring (multiple protocols)
22. **Real Browser** - Chromium-based monitoring (loads full page)

### Notification Integrations (87 native providers + Apprise)

**Native providers (from server/notification-providers/):**
46elks, Alerta, AlertNow, Aliyun SMS, Apprise, Bale, Bark, Bitrix24, Brevo, CallMeBot, Cellsynt, ClickSend SMS, DingDing, Discord, Evolution API, Feishu, FlashDuty, Free Mobile, GoAlert, Google Chat, Google Sheets, Gorush, Gotify, Grafana OnCall, GTX Messaging, HaloPSA, Heii OnCall, Home Assistant, Jira Service Management, Keep, Kook, LINE, LunaSea, Matrix, Mattermost, Nextcloud Talk, Nostr, Notifery, Ntfy, Octopush, OneBot, OneChat, OneSender, OpsGenie, PagerDuty, PagerTree, PromoSMS, Pumble, Pushbullet, PushDeer, Pushover, PushPlus, Pushy, Resend, Rocket.Chat, SendGrid, ServerChan, SerwerSMS, SevenIO, Signal, SIGNL4, Slack, SMS Planet, SMSC, SMSEagle, SMSIR, SMS Manager, SMS Partner, SMTP (Email), Splunk, SpugPush, Squadcast, Stackfield, Microsoft Teams, Techulus Push, Telegram, Threema, Twilio, WAHA, Webhook, WeCom, Whapi, Web Push, wPush, YZJ, Zoho Cliq

**Plus Apprise integration:** Supports 78+ additional services via the Apprise notification library

### Core Features
- **Status Pages:** Multiple public status pages with custom domain mapping
- **Multi-language:** Full internationalization support
- **Authentication:** Username/password with optional 2FA (TOTP)
- **Proxy Support:** HTTP, SOCKS4, SOCKS5 proxy configuration per monitor
- **API Access:** Socket.IO API (full CRUD) + REST API (badges, status pages, push monitors, Prometheus metrics)
- **API Keys:** Bearer token authentication for REST endpoints
- **Maintenance Windows:** Scheduled maintenance with affected monitor selection, Markdown description, status page display
- **Tags & Groups:** Categorize monitors by tags, drag-and-drop group organization
- **Certificate Monitoring:** SSL/TLS certificate expiry tracking and alerts
- **Response Time Graphs:** Historical ping/response time visualization
- **Uptime Percentage:** Tracks uptime over 24h, 30d, 1y periods
- **Badge Generation:** Dynamic SVG badges for uptime and response time (shields.io compatible)
- **Prometheus Metrics:** `/metrics` endpoint for Grafana integration
- **Cloudflare Tunnels:** Built-in Cloudflare tunnel support
- **Gamedig Integration:** Advanced game server monitoring
- **Real Browser Monitoring:** Chromium-based page load checks
- **Docker Socket Monitoring:** Direct Docker container status via socket
- **20-second intervals:** Minimum monitoring interval

---

## 4. Build & Compilation Details

### Production Setup from Source (Non-Docker)

```bash
# 1. Clone repository
git clone https://github.com/louislam/uptime-kuma.git
cd uptime-kuma

# 2. Run setup (checks out version tag, installs deps, downloads pre-built dist)
npm run setup
# This executes: git checkout 2.1.0 && npm ci --omit dev --no-audit && npm run download-dist

# 3. Start
node server/server.js
# OR with PM2:
pm2 start server/server.js --name uptime-kuma
```

### What `npm run setup` Does (Breakdown)
1. `git checkout 2.1.0` - Checks out the release tag
2. `npm ci --omit dev --no-audit` - Clean install production dependencies only
3. `npm run download-dist` - Downloads pre-built frontend dist from GitHub Releases (avoids needing to build Vue/Vite frontend)

### Building Frontend from Source (Alternative)
```bash
npm ci           # Install ALL dependencies (including dev)
npm run build    # Vite build (produces dist/ directory)
```

### Native Module Compilation Requirements
For `@louislam/sqlite3` when prebuilts are unavailable:
- **node-gyp** (included with npm)
- **Python 3** (for node-gyp)
- **C/C++ compiler:** GCC or compatible
- **make** (build-essential on Debian/Ubuntu)
- **SQLite3 development headers** (optional, uses bundled SQLite by default)

### Prebuilt Binaries Available For @louislam/sqlite3
| Architecture | glibc | musl (Alpine) |
|-------------|-------|---------------|
| AMD64 (x86_64) | Yes | Yes |
| ARM64 (aarch64) | Yes | Yes |
| ARMv7 | Yes (glibc >= 2.18) | Yes |

### Cross-Compilation Considerations
- Docker buildx supports multi-arch: `linux/amd64`, `linux/arm64`, `linux/arm/v7`
- Synology NAS architectures:
  - **x86_64:** Intel Celeron (DS220+, DS920+, DS1621+, etc.)
  - **aarch64:** Realtek RTD1296 (DS220j, DS420j), Realtek RTD1619B (DS223, DS224+)
  - **armv7:** Marvell Armada (older models like DS218, DS118)
- For SPK packaging: compile native modules on target architecture OR use prebuilt binaries
- The @louislam/sqlite3 fork provides prebuilts for all three architectures

### npm vs yarn vs pnpm
- **Official:** npm only. `npm ci` for clean installs, `npm run setup` for production.
- No yarn.lock or pnpm-lock.yaml in repo.
- Must use npm.

### Installation Size
- **Minimum disk:** ~1GB recommended (application + data)
- **node_modules (production):** ~200-300MB (estimated, with 100+ production packages)
- **Frontend dist:** ~10-20MB (pre-built, downloaded)
- **Database growth:** Depends on monitor count and retention (heartbeat aggregation in v2 reduces size)

---

## 5. Version History & Release Info

### Current Version: 2.1.0 (February 7, 2026)
- **New:** Jira Service Management notification provider
- **New:** Google Sheets notification provider
- **Improved:** Discord custom message/format presets
- **Improved:** Ntfy custom title/message templates
- **Improved:** Slack monitor group name in notifications
- 250+ merged PRs across 3 beta versions
- 40+ contributors

### Version 2.0.0 (October 20, 2025)
**Major breaking release.** Key changes:
- **MariaDB support:** Optional external or embedded MariaDB database
- **Heartbeat aggregation:** Optimized storage format for better performance
- **Alpine Docker images dropped:** Debian-only going forward
- **Node.js 20.4+ required** (dropped 14, 16, 18)
- **JSON backup/restore removed** (data directory backups only)
- **DNS caching removed** for HTTP monitors
- **Default retries changed:** 0 instead of 1 for new monitors
- **Email templates:** Switched to LiquidJS (case-sensitive variables)
- **Badge API:** Only accepts `24`, `24h`, `30d`, or `1y` durations
- **Security:** Replaced proxy-agent due to vm2 vulnerability

### Release Cycle
- 121 total releases as of Feb 2026
- Active development with frequent beta releases
- Major versions (1.x -> 2.x) approximately every 2 years
- Minor versions every few months
- Patch releases as needed
- Beta channel available for testing

### Docker Image Architecture Support
- `linux/amd64` (x86_64)
- `linux/arm64` (aarch64)
- `linux/arm/v7` (armv7)

---

## 6. Synology-Specific Considerations

### Current State on Synology
- **No native SPK package exists** - all current Synology installations use Docker
- Multiple community guides for Docker installation (Marius Hosting, PatNotebook, NasDaddy)
- Users typically map port 3001 -> 3444 (or custom) to avoid conflicts

### Port Conflicts with DSM
- Port 3001 is not commonly used by DSM services (relatively safe default)
- Common Synology ports to avoid: 5000/5001 (DSM), 6690 (Synology Drive), 8080 (Web Station)
- Recommendation: Use configurable port via `UPTIME_KUMA_PORT`

### ARM Compatibility
- @louislam/sqlite3 provides prebuilt binaries for ARM64 and ARMv7
- ARMv7 requires glibc >= 2.18 (Synology DSM 7 should meet this)
- Synology ARM NAS models (RTD1296, RTD1619B) are ARM64
- Older Marvell Armada models are ARMv7

### SQLite & File System
- **CRITICAL:** NFS not supported (SQLite corruption)
- Synology's local ext4/btrfs filesystems are fully compatible
- SQLite needs proper POSIX file locking (local filesystem provides this)
- Some users have reported SQLite corruption during Docker migrations

### Backup Integration
- Data directory can be backed up with Hyper Backup
- Backup the entire `data/` directory (includes SQLite DB + uploads)
- **Important:** Stop Uptime Kuma before backing up SQLite to ensure consistency
- For SPK: Can integrate with Synology's scheduled task system for automated backups

### Reverse Proxy Considerations
- WebSocket support required (Upgrade + Connection headers)
- Synology's built-in reverse proxy (nginx) needs WebSocket configuration
- Common setup: DSM reverse proxy -> Uptime Kuma on internal port

### Resource Usage on NAS Hardware
- Lightweight enough for most Synology NAS units
- DS220j (ARM, 512MB RAM): May be tight with many monitors
- DS220+ (Intel, 2GB RAM): Comfortable for 50+ monitors
- DS920+ (Intel, 4GB RAM): Excellent performance
- Recommendation: Minimum 512MB available RAM, 1GB preferred

### User Community Requests
- Users want simpler installation (Docker is seen as complex by some NAS users)
- Native SPK would significantly reduce barrier to entry
- Integration with Synology notifications system would be valuable
- Automatic backup integration via Hyper Backup is desired
- WebSocket reverse proxy configuration is a common pain point

---

## 7. SPK Packaging Recommendations

### Bundling Strategy
1. **Bundle Node.js 22 LTS** with the SPK (Synology's system Node.js may be outdated)
2. **Use prebuilt @louislam/sqlite3 binaries** for each architecture (amd64, arm64, armv7)
3. **Download pre-built frontend dist** (avoid requiring Vite build on NAS)
4. **Production-only npm install** (`npm ci --omit dev`)

### Architecture-Specific Builds
Need separate SPK builds or multi-arch support for:
- `x86_64` (Intel Celeron NAS models)
- `aarch64` (Realtek ARM64 NAS models)
- `armv7` (older Marvell Armada models, lower priority)

### Data Directory
- Store in `/var/packages/uptime-kuma/var/` or `/volume1/@appdata/uptime-kuma/`
- Set `DATA_DIR` environment variable in start script
- Ensure proper ownership (package user)

### Service Management
- Use Synology's `synoservice`/`synopkg` for start/stop
- Create proper init scripts (SSS - Synology Service Script)
- PID file management for process tracking
- Graceful shutdown: SIGTERM to Node.js process (30s timeout built-in)

### Configuration
- Set port via `UPTIME_KUMA_PORT` (configurable in install wizard)
- Set `NODE_ENV=production`
- Set `DATA_DIR` to package data directory
- Optionally support SSL cert configuration

### Key Commands for SPK Scripts
```bash
# Start
DATA_DIR="/var/packages/uptime-kuma/var" \
UPTIME_KUMA_PORT=3001 \
NODE_ENV=production \
/var/packages/uptime-kuma/target/node/bin/node \
/var/packages/uptime-kuma/target/uptime-kuma/server/server.js

# Stop (graceful)
kill -SIGTERM $(cat /var/packages/uptime-kuma/var/uptime-kuma.pid)
```
