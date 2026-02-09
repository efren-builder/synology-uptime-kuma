# SPK Packaging Format & SynoCommunity Guidelines — Complete Research

## Table of Contents
1. [SPK File Format](#1-spk-file-format)
2. [INFO File Format](#2-info-file-format)
3. [Scripts Directory](#3-scripts-directory)
4. [conf Directory (DSM 7+)](#4-conf-directory-dsm-7)
5. [WIZARD_UIFILES](#5-wizard_uifiles)
6. [spksrc Build System](#6-spksrc-build-system)
7. [spksrc Makefile Variables](#7-spksrc-makefile-variables)
8. [Service Support Framework](#8-service-support-framework)
9. [DSM 7 Breaking Changes & Requirements](#9-dsm-7-breaking-changes--requirements)
10. [Node.js Package Strategy](#10-nodejs-package-strategy)
11. [Reference Package: Gitea](#11-reference-package-gitea)
12. [Reference Package: Homebridge](#12-reference-package-homebridge)
13. [SynoCommunity Contribution Guidelines](#13-synocommunity-contribution-guidelines)
14. [Recommendations for Uptime Kuma SPK](#14-recommendations-for-uptime-kuma-spk)

---

## 1. SPK File Format

An `.spk` file is a standard tar archive. You can unpack with `tar -xvf filename.spk`.

### Structure
```
package.spk (tar)
├── INFO                    # Package metadata (required)
├── package.tgz             # Compressed archive of binaries/app files (required)
├── scripts/                # Lifecycle shell scripts (required)
│   ├── preinst
│   ├── postinst
│   ├── preuninst
│   ├── postuninst
│   ├── preupgrade
│   ├── postupgrade
│   ├── prereplace
│   ├── postreplace
│   └── start-stop-status
├── conf/                   # Configuration files (required DSM 4.2+)
│   ├── privilege           # JSON: run-as user, permissions
│   └── resource            # JSON: port-config, data-share, usr-local-linker
├── WIZARD_UIFILES/         # Installation wizard UI (optional, DSM 7.2.2+)
│   ├── install_uifile      # JSON wizard for install
│   ├── upgrade_uifile      # JSON wizard for upgrade
│   └── uninstall_uifile    # JSON wizard for uninstall
├── LICENSE                  # License text (optional, max 1MB)
├── PACKAGE_ICON.PNG         # 64x64 pixels (DSM 7+) or 72x72 (DSM 6)
└── PACKAGE_ICON_256.PNG     # 256x256 pixels
```

### package.tgz Contents
The package.tgz extracts to `/var/packages/<package_name>/target/`. It contains:
- Application binaries and libraries
- Configuration templates
- UI files (if using DSM UI integration)
- Any bundled runtime files

### Key Paths on the NAS
| Path | Description |
|------|-------------|
| `/var/packages/<pkg>/target/` | Package installation directory (read-only in DSM 7) |
| `/var/packages/<pkg>/var/` | Package variable data directory (writable, DSM 7) |
| `/var/packages/<pkg>/home/` | Package home directory (DSM 7, permissions 0700) |
| `/var/packages/<pkg>/etc/` | Package configuration (stores installer-variables) |
| `/var/packages/<pkg>/shares/` | Symlinks to shared folders (DSM 7.0-41201+) |
| `/var/packages/<pkg>/conf/` | Package conf (privilege, resource) |
| `/var/log/packages/<pkg>.log` | Package log file (DSM 6+) |

---

## 2. INFO File Format

The INFO file is a key-value properties file (shell-compatible). For the spksrc build system, it's generated from `INFO.sh`.

### Required Fields (DSM 7+)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `package` | String | Unique package identity. No `:`, `/`, `>`, `<`, `\|`, `=` | `package="uptime-kuma"` |
| `version` | String | Version (major.minor.micro-build) | `version="1.23.15-1"` |
| `os_min_ver` | X.Y-Z | Minimum DSM version. Must be >= `7.0-40000` for DSM 7 | `os_min_ver="7.0-40000"` |
| `description` | String | Package description for Package Center | `description="Self-hosted monitoring tool"` |
| `arch` | String | Space-separated architectures, or `noarch` | `arch="noarch"` |
| `maintainer` | String | Developer name (GitHub username for spksrc) | `maintainer="SynoCommunity"` |

### Important Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `displayname` | String | package value | Name shown in Package Center |
| `adminport` | 0-65536 | 80 | Port for the admin UI link |
| `adminurl` | String | "" | URL path after port |
| `adminprotocol` | http/https | http | Protocol for admin link |
| `startable` | yes/no | yes | Whether users can start/stop |
| `install_dep_packages` | String | "" | Colon-separated package dependencies |
| `start_dep_services` | String | "" | Space-separated service dependencies |
| `checkport` | yes/no | yes | Check for port conflicts |
| `dsmuidir` | String | "" | DSM UI directory |
| `dsmappname` | String | "" | DSM application name |
| `support_url` | String | "" | Support/help URL |
| `maintainer_url` | String | "" | Maintainer URL |
| `beta` | yes/no | no | Mark as beta |
| `silent_install` | yes/no | no | Allow silent install |
| `silent_upgrade` | yes/no | no | Allow silent upgrade |
| `support_conf_folder` | yes/no | no | Support conf folder backup |
| `install_on_cold_storage` | yes/no | no | Allow cold storage install |

### INFO.sh Example (Synology Toolkit Style)
```bash
#!/bin/bash
source /pkgscripts/include/pkg_util.sh

package="uptime-kuma"
version="1.23.15-1"
os_min_ver="7.0-40000"
displayname="Uptime Kuma"
description="A self-hosted monitoring tool like Uptime Robot"
arch="noarch"
maintainer="SynoCommunity"
maintainer_url="https://github.com/SynoCommunity"
support_url="https://github.com/louislam/uptime-kuma"
adminprotocol="http"
adminport="3001"
adminurl="/"
startable="yes"
install_dep_packages="Node.js_v22"
checkport="yes"

pkg_dump_info
```

---

## 3. Scripts Directory

### Lifecycle Script Execution Order

**Install:** `preinst` -> extract package.tgz -> `postinst`
**Upgrade:** `preupgrade` -> `preuninst` -> extract -> `postinst` -> `postupgrade`
**Uninstall:** `preuninst` -> remove files -> `postuninst`
**Start:** `prestart` (DSM 7) -> `start-stop-status start`
**Stop:** `start-stop-status stop`
**Status:** `start-stop-status status`

### start-stop-status Exit Codes
| Code | Meaning |
|------|---------|
| 0 | Package is running |
| 1 | Program dead, /var/run pid file exists |
| 2 | Program dead, /var/lock lock file exists |
| 3 | Package not running |
| 4 | Status unknown |
| 150 | Package is broken |

### Environment Variables Available in Scripts
| Variable | Description |
|----------|-------------|
| `SYNOPKG_PKGNAME` | Package name (lowercase) |
| `SYNOPKG_PKGDEST` | Installation path (`/var/packages/<pkg>/target`) |
| `SYNOPKG_PKGDEST_VOL` | Volume (`/volume1`, `/volume2`) |
| `SYNOPKG_PKGVAR` | Var directory (DSM 7: `/var/packages/<pkg>/var`) |
| `SYNOPKG_PKGHOME` | Home directory (DSM 7: `/var/packages/<pkg>/home`) |
| `SYNOPKG_PKG_STATUS` | Current operation (INSTALL, UPGRADE, UNINSTALL) |
| `SYNOPKG_DSM_VERSION_MAJOR` | DSM major version number |
| `SYNOPKG_TEMP_LOGFILE` | Temp log file path |

---

## 4. conf Directory (DSM 7+)

### conf/privilege

**MANDATORY** for DSM 7. Packages must run as non-root user.

```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "uptime-kuma"
}
```

Extended example with groups and capabilities:
```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "sc-uptime-kuma",
    "groupname": "synocommunity",
    "ctrl-script": "run-as-root"
}
```

**Key points:**
- `run-as: "package"` is MANDATORY in DSM 7 (cannot use `system`)
- `ctrl-script: "run-as-root"` allows start-stop-status to run as root if needed
- Package user is automatically created as `sc-<pkgname>` by spksrc framework
- For DSM 7, root packages require Synology signing + dev token

### conf/resource

Defines system resources the package needs. Contains workers.

```json
{
    "port-config": {
        "protocol-file": "app/uptime-kuma.sc"
    },
    "data-share": {
        "shares": [
            {
                "name": "uptime-kuma",
                "permission": {
                    "rw": ["sc-uptime-kuma"]
                }
            }
        ]
    },
    "usr-local-linker": {
        "bin": ["bin/uptime-kuma"]
    }
}
```

#### port-config Worker
- Copies `.sc` file to `/usr/local/etc/service.d/`
- `.sc` file format (Service Configure):
```
[uptime-kuma]
title="Uptime Kuma"
desc="Uptime Kuma"
port_forward="yes"
dst.ports="3001/tcp"
```

#### data-share Worker
- Creates shared folders during package startup
- Folders persist after uninstallation (to prevent data loss)
- Since DSM 7.0-41201, creates symlinks at `/var/packages/<pkg>/shares/`

```json
"data-share": {
    "shares": [{
        "name": "<share-name>",
        "permission": {
            "ro": ["<user-name>"],
            "rw": ["<user-name>"]
        },
        "once": false
    }]
}
```

#### usr-local-linker Worker
- Creates/removes symlinks in `/usr/local/{bin,lib,etc}`
- Relative paths from `/var/packages/<pkg>/target/`

```json
"usr-local-linker": {
    "bin": ["usr/bin/tool1"],
    "lib": ["lib/libfoo.so"],
    "etc": ["etc/config"]
}
```

---

## 5. WIZARD_UIFILES

### JSON Format (Pre-DSM 7.2.2)

Wizard files are JSON arrays of step objects:

```json
[
    {
        "step_title": "Uptime Kuma Configuration",
        "items": [
            {
                "type": "textfield",
                "desc": "Please specify a shared folder for this package.",
                "subitems": [
                    {
                        "key": "wizard_shared_folder_name",
                        "desc": "Shared Folder",
                        "defaultValue": "uptime-kuma",
                        "validator": {
                            "allowBlank": false,
                            "regex": {
                                "expr": "/^[\\w _-]+$/",
                                "errorText": "Subdirectories are not supported."
                            }
                        }
                    }
                ]
            },
            {
                "desc": ""
            },
            {
                "desc": "If you let the installer create the shared folder, it is created under the same volume as the package is installed.<br/>If you want to use a different volume, create the shared folder first in DSM Control Panel."
            },
            {
                "desc": ""
            },
            {
                "desc": "This package runs as internal service user <b>'sc-uptime-kuma'</b> in DSM. The shared folder is configured at installation time to be accessible by this user.<p>Please read <a target=\"_blank\" href=\"https://github.com/SynoCommunity/spksrc/wiki/Permission-Management\">Permission Management</a> for details."
            }
        ]
    }
]
```

### Item Types Available
- `textfield` — Text input with validation
- `password` — Password input
- `combobox` — Dropdown selection
- `multiselect` — Multi-selection
- `singleselect` — Radio button selection

### Dynamic Wizards
- `install_uifile.sh` — Shell script that generates JSON dynamically, writes to `$SYNOPKG_TEMP_LOGFILE`
- Supports localization: `install_uifile_fre`, `install_uifile_cht`, etc.

### DSM 7.2.2+ (Vue.js v2 Render Function)
New format uses Vue.js 2.7.14 components with webpack compilation. More complex but more powerful. The older JSON format still works.

---

## 6. spksrc Build System

### Repository Structure
```
spksrc/
├── cross/           # Cross-compiled libraries and tools
│   ├── openssl3/
│   ├── sqlite/
│   └── <pkg>/       # Each has Makefile, digests, PLIST
├── native/          # Natively-compiled build tools
│   ├── cmake/
│   └── <pkg>/
├── spk/             # Final SPK package definitions
│   ├── transmission/
│   ├── gitea/
│   ├── demoservice/
│   └── <pkg>/       # Makefile + src/ directory
│       ├── Makefile
│       └── src/
│           ├── service-setup.sh
│           ├── <pkg>.png    # Icon (256x256+)
│           ├── wizard/
│           │   └── install_uifile
│           └── conf/        # (optional custom conf)
├── mk/              # Build system makefiles
│   ├── spksrc.spk.mk
│   ├── spksrc.service.mk
│   ├── spksrc.cross-cc.mk
│   └── ...
├── toolchain/       # Architecture toolchains
├── packages/        # Output .spk files
└── Makefile
```

### Build Workflow
```bash
# Setup
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc && make setup

# Build for specific architecture
cd spk/<package>
make arch-x64-7.1          # Single arch
make all-supported          # All supported architectures

# Clean
make clean                  # Remove build dirs
make spkclean              # Remove only SPK artifacts
```

### Build Sequence
1. Read package Makefile
2. Download appropriate toolchain
3. For each dependency:
   - Download source to `distrib/`
   - Extract, configure, make, install
4. Package everything into SPK under `packages/`:
   - Binaries, scripts, icons, config files
   - Wizard UI files, help docs (optional)

### Docker Development
```bash
docker build - < Dockerfile
docker run -it -v $(pwd):/spksrc <image_id> /bin/bash
# Inside container:
cd spk/<package> && make all-supported
```

---

## 7. spksrc Makefile Variables

### SPK Package Makefile (spk/<pkg>/Makefile)

#### Package Identity
| Variable | Description | Example |
|----------|-------------|---------|
| `SPK_NAME` | Package identifier (lowercase) | `SPK_NAME = uptime-kuma` |
| `SPK_VERS` | Software version | `SPK_VERS = 1.23.15` |
| `SPK_REV` | Package revision (starts at 1) | `SPK_REV = 1` |
| `SPK_ICON` | Icon path (256x256+ PNG) | `SPK_ICON = src/uptime-kuma.png` |
| `DISPLAY_NAME` | Package Center display name | `DISPLAY_NAME = Uptime Kuma` |
| `DESCRIPTION` | Package description | `DESCRIPTION = A monitoring tool` |
| `HOMEPAGE` | Software homepage URL | `HOMEPAGE = https://uptime.kuma.pet` |
| `LICENSE` | License type | `LICENSE = MIT` |
| `MAINTAINER` | GitHub username | `MAINTAINER = SynoCommunity` |
| `MAINTAINER_URL` | Maintainer URL | `MAINTAINER_URL = https://github.com/...` |
| `CHANGELOG` | Changes for current SPK_REV | `CHANGELOG = "Initial release"` |

#### Architecture & Compatibility
| Variable | Description | Example |
|----------|-------------|---------|
| `ARCH` | Force architecture (empty = noarch) | `override ARCH=` |
| `OS_MIN_VER` | Minimum DSM version | `OS_MIN_VER = 7.0-40000` |
| `REQUIRED_MIN_DSM` | Build-time DSM minimum | `REQUIRED_MIN_DSM = 7.0` |
| `UNSUPPORTED_ARCHS` | Excluded architectures | `UNSUPPORTED_ARCHS = cedarview` |

#### Dependencies
| Variable | Description | Example |
|----------|-------------|---------|
| `DEPENDS` | Build + runtime dependencies | `DEPENDS = cross/sqlite` |
| `BUILD_DEPENDS` | Build-only dependencies | `BUILD_DEPENDS = cross/python311` |
| `SPK_DEPENDS` | Required installed SPK packages | `SPK_DEPENDS = "python3>=3.7"` |

#### Service Configuration
| Variable | Description | Example |
|----------|-------------|---------|
| `STARTABLE` | Package provides a service | `STARTABLE = yes` |
| `SERVICE_USER` | Runtime user (use `auto`) | `SERVICE_USER = auto` |
| `SERVICE_SETUP` | Custom service-setup script | `SERVICE_SETUP = src/service-setup.sh` |
| `SERVICE_PORT` | Service TCP port | `SERVICE_PORT = 3001` |
| `SERVICE_PORT_TITLE` | Port name for firewall | `SERVICE_PORT_TITLE = Uptime Kuma (HTTP)` |
| `SERVICE_PORT_PROTOCOL` | Protocol (http/https) | `SERVICE_PORT_PROTOCOL = http` |
| `SERVICE_PORT_URL` | URL context path | `SERVICE_PORT_URL = /` |
| `SERVICE_COMMAND` | Full service start command | `SERVICE_COMMAND = ...` |
| `ADMIN_PORT` | Admin web UI port | `ADMIN_PORT = $(SERVICE_PORT)` |
| `ADMIN_PROTOCOL` | Admin protocol | `ADMIN_PROTOCOL = http` |
| `ADMIN_URL` | Admin URL path | `ADMIN_URL = /` |

#### Wizard & Shared Folders
| Variable | Description | Example |
|----------|-------------|---------|
| `WIZARDS_DIR` | Wizard files location | `WIZARDS_DIR = src/wizard/` |
| `SERVICE_WIZARD_SHARENAME` | Wizard var for share name | `SERVICE_WIZARD_SHARENAME = wizard_shared_folder_name` |

#### Build Targets
| Variable | Description | Example |
|----------|-------------|---------|
| `POST_STRIP_TARGET` | Post-strip custom target | `POST_STRIP_TARGET = pkg_extra_install` |
| `PRE_COPY_TARGET` | Pre-copy custom target | `PRE_COPY_TARGET = pkg_pre_copy` |
| `CONF_DIR` | Custom conf directory | `CONF_DIR = src/conf` |

#### Include
Every SPK Makefile must end with:
```makefile
include ../../mk/spksrc.spk.mk
```

---

## 8. Service Support Framework

spksrc provides a generic service management framework. When `SERVICE_USER` and `SERVICE_SETUP` are set, the framework auto-generates:

### Auto-Generated Files
1. **`conf/privilege`** — User/group configuration
2. **`conf/resource`** — Port config, shared folders, usr-local-linker
3. **`scripts/service-setup`** — Aggregated from Makefile vars + custom SERVICE_SETUP
4. **`scripts/installer`** — Generic installer (DSM 5/6/7 variants)
5. **`scripts/start-stop-status`** — Service lifecycle management

### service-setup.sh Template (Custom Part)

```bash
# Package specific behaviors
# Sourced by generic installer and start-stop-status scripts

# Service command — how to start the application
SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/start.sh"
SVC_CWD="${SYNOPKG_PKGVAR}"

# Background execution
SVC_BACKGROUND=y        # Fork to background
SVC_WRITE_PID=y         # Framework writes PID file

# Available hook functions:
# validate_preinst()    — Validate before install (exit 1 to abort)
# validate_preupgrade() — Validate before upgrade
# validate_preuninst()  — Validate before uninstall
# service_preinst()     — Before install
# service_postinst()    — After install
# service_preuninst()   — Before uninstall
# service_postuninst()  — After uninstall
# service_preupgrade()  — Before upgrade
# service_postupgrade() — After upgrade
# service_prestart()    — Before service start
# service_poststop()    — After service stop
# service_restore()     — Called during upgrade before restoring backed-up files

service_postinst() {
    if [ "${SYNOPKG_PKG_STATUS}" == "INSTALL" ]; then
        # First-time installation setup
        echo "Performing initial setup..."
    fi
}

service_prestart() {
    # Called before service starts
    # Good place to load config, set environment
    echo "Preparing to start service..."
}
```

### Important Service Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVICE_COMMAND` | Full command to start service | — |
| `SVC_CWD` | Working directory for service | — |
| `SVC_BACKGROUND` | Fork to background | n |
| `SVC_WRITE_PID` | Framework writes PID file | n |
| `PID_FILE` | PID file path | `${SYNOPKG_PKGVAR}/${SPK_NAME}.pid` |
| `LOG_FILE` | Log file path | `${SYNOPKG_PKGVAR}/${SPK_NAME}.log` |
| `SVC_NO_REDIRECT` | Don't redirect stdout/stderr | n |
| `SVC_QUIET` | Suppress start/stop messages | n |
| `SVC_KEEP_LOG` | Don't clear log on restart | n |
| `SVC_WAIT_TIMEOUT` | Timeout waiting for PID | 20 seconds |
| `SHARE_PATH` | Full path to wizard-configured share | — |
| `SHARE_NAME` | Name of wizard-configured share | — |

### User Account Naming
- DSM 7: `sc-<SPK_NAME>` (e.g., `sc-uptime-kuma`)
- DSM 6: `sc-<SPK_NAME>`
- DSM 5: `svc-<SPK_NAME>`

---

## 9. DSM 7 Breaking Changes & Requirements

### Mandatory Requirements
1. **conf/privilege with run-as: package** — All packages MUST include this
2. **Required INFO fields**: `package`, `version`, `os_min_ver`, `description`, `arch`, `maintainer`
3. **os_min_ver >= 7.0-40000** — Required for DSM 7 packages
4. **PACKAGE_ICON.PNG = 64x64** — Changed from 72x72 in DSM 6
5. **No root execution** — Packages cannot run as root unless Synology-signed

### Changes from DSM 6
- Package signing removed from packing stage
- Home directory moved: `/var/packages/<pkg>/target` -> `/var/packages/<pkg>/home` (0700)
- FHS directories respect privilege settings
- Package logs at `/var/log/packages/<pkg>.log`
- `prestart` script runs on bootup to check if package can start
- `synopkg install` has same constraints as UI installation
- Starting package A auto-starts dependency B
- Users cannot add/remove keyrings or adjust trust levels
- Non-Synology packages trigger installation alerts

### Prohibited in DSM 7
- `run-as: system` in conf/privilege
- Root execution without Synology signing
- Legacy BusyBox start-stop-daemon approach (deprecated)

---

## 10. Node.js Package Strategy

### Two Approaches

#### Approach A: Depend on Synology's Node.js Package (Recommended for SPK)
Like Homebridge, declare `install_dep_packages="Node.js_v22"` in INFO:
- Synology provides official Node.js packages (v16, v18, v20, v22)
- Node.js binary available at a known path after install
- Pro: Smaller package size, automatic Node.js updates
- Con: Depends on Synology maintaining the Node.js package

```bash
# INFO.sh
install_dep_packages="Node.js_v22"

# In service-setup.sh or start script:
NODE="/var/packages/Node.js_v22/target/usr/local/bin/node"
# Or add to PATH:
PATH="/var/packages/Node.js_v22/target/usr/local/bin:${PATH}"
```

#### Approach B: Bundle Node.js in the SPK
Cross-compile Node.js as part of the package:
- Pro: Self-contained, no external dependencies
- Con: Larger package, must compile for all architectures, maintenance burden

#### Approach C: Use `noarch` with System Node.js
Set `arch="noarch"` and depend on the Synology Node.js package:
- Pro: Single package for all architectures
- Con: Still depends on system Node.js

### Recommended for Uptime Kuma
**Approach A** with `install_dep_packages="Node.js_v22"`:
- Uptime Kuma is primarily JavaScript (Node.js)
- Uses SQLite via better-sqlite3 (native module — needs compilation per arch)
- For native modules: either cross-compile or use prebuild binaries

**If using noarch (no native modules):**
- Bundle all node_modules (pre-installed via npm)
- Use `arch="noarch"` since no compiled code
- Note: better-sqlite3 has native bindings, so this may NOT work without prebuilds

---

## 11. Reference Package: Gitea

### Directory Structure
```
spk/gitea/
├── Makefile
└── src/
    ├── gitea.png           # Icon
    ├── conf.ini            # Config template
    ├── service-setup.sh    # Service hooks
    └── wizard/
        ├── install_uifile      # Install wizard JSON
        ├── install_uifile_plk  # Polish locale
        ├── upgrade_uifile      # Upgrade wizard
        └── upgrade_uifile_plk  # Polish locale
```

### Makefile
```makefile
SPK_NAME = gitea
SPK_VERS = 1.25.4
SPK_REV = 27
SPK_ICON = src/gitea.png

MAINTAINER = wkobiela
DESCRIPTION = Gitea is a community managed lightweight code hosting solution written in Go.
DISPLAY_NAME = Gitea
CHANGELOG = "1. Update to v1.25.4 (security release)."

LICENSE = MIT

DEPENDS = cross/gitea
SPK_DEPENDS = "git>=2"

SERVICE_USER = auto
SERVICE_SETUP = src/service-setup.sh
STARTABLE = yes
WIZARDS_DIR = src/wizard/
SERVICE_WIZARD_SHARENAME = wizard_shared_folder_name

SERVICE_PORT = 8418
SERVICE_PORT_TITLE = $(DISPLAY_NAME) (HTTP)
ADMIN_PORT = $(SERVICE_PORT)

POST_STRIP_TARGET = gitea_extra_install

include ../../mk/spksrc.spk.mk

.PHONY: gitea_extra_install
gitea_extra_install:
	@$(MSG) "Install conf.ini file"
	@install -m 755 -d $(STAGING_DIR)/var
	@install -m 644 src/conf.ini $(STAGING_DIR)/var/conf.ini
```

### service-setup.sh
```bash
GITEA="${SYNOPKG_PKGDEST}/bin/gitea"
CFG_FILE="${SYNOPKG_PKGVAR}/conf.ini"
PATH="/var/packages/git/target/bin:${PATH}"

if [ $SYNOPKG_DSM_VERSION_MAJOR -lt 7 ]; then
    SYNOPKG_PKGHOME="${SYNOPKG_PKGVAR}"
fi

ENV="PATH=${PATH} HOME=${SYNOPKG_PKGHOME}"
SERVICE_COMMAND="env ${ENV} ${GITEA} web --port ${SERVICE_PORT} --pid ${PID_FILE}"
SVC_BACKGROUND=y

service_postinst() {
    if [ "${SYNOPKG_PKG_STATUS}" == "INSTALL" ]; then
        IP=$(ip route get 1 | awk '{print $(NF);exit}')
        sed -i -e "s|@share_path@|${SHARE_PATH}|g" ${CFG_FILE}
        sed -i -e "s|@ip_address@|${IP:=localhost}|g" ${CFG_FILE}
        sed -i -e "s|@service_port@|${SERVICE_PORT}|g" ${CFG_FILE}
    fi
}

service_restore() {
    if [ ${SYNOPKG_DSM_VERSION_MAJOR} -lt 7 ]; then
        [ -f "${SYNOPKG_PKGVAR}/conf.ini" ] && cp -f ${SYNOPKG_PKGVAR}/conf.ini ${TMP_DIR}/conf.ini.new
    fi
}
```

### install_uifile
```json
[
    {
        "step_title": "Gitea configuration",
        "items": [
            {
                "type": "textfield",
                "desc": "Please specify a shared folder for this package.",
                "subitems": [
                    {
                        "key": "wizard_shared_folder_name",
                        "desc": "Shared Folder",
                        "defaultValue": "gitea-share",
                        "validator": {
                            "allowBlank": false,
                            "regex": {
                                "expr": "/^[\\w _-]+$/",
                                "errorText": "Subdirectories are not supported."
                            }
                        }
                    }
                ]
            },
            {
                "desc": "If you let the installer create the shared folder, it is created under the same volume as the package is installed."
            },
            {
                "desc": ""
            },
            {
                "desc": "This package runs as internal service user 'sc-gitea' in DSM."
            }
        ]
    }
]
```

---

## 12. Reference Package: Homebridge (Node.js)

The Homebridge SPK is the closest reference for an Uptime Kuma package since it's also a Node.js application.

### Key Design Decisions
- **Node.js dependency**: `install_dep_packages="Node.js_v22"` — uses Synology's official Node.js
- **Architecture-specific builds**: Builds per architecture (x86_64, armv8, armv7, i686)
- **Custom build system**: Uses Synology toolkit (SynoBuildConf) not spksrc
- **Service management**: Uses `synosystemctl` with systemd user units

### INFO.sh
```bash
#!/bin/bash
package="homebridge"
. "/pkgscripts-ng/include/pkg_util.sh"

version=${SPK_PACKAGE_VERSION:-1.0.0}
os_min_ver="7.0-40761"
maintainer="homebridge"
thirdparty="yes"
arch="${SPK_ARCH:-x86_64}"
reloadui="yes"
dsmuidir="ui"
dsmappname="homebridge.homebridge"
silent_install="no"
silent_upgrade="no"
adminprotocol="http"
adminurl=""
adminport="8581"
install_dep_packages="Node.js_v22"
displayname="Homebridge"
description="Homebridge on Synology DSM."
maintainer_url="https://github.com/homebridge/homebridge-syno-spk"
support_url="https://github.com/homebridge/homebridge-syno-spk"

[ "$(caller)" != "0 NULL" ] && return 0
pkg_dump_info
```

### conf/privilege
```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "homebridge"
}
```

### conf/resource
```json
{
    "systemd-user-unit": {},
    "data-share": {
        "shares": [
            {
                "name": "homebridge",
                "permission": {
                    "rw": ["homebridge"]
                }
            }
        ]
    },
    "usr-local-linker": {
        "bin": [
            "app/hb-shell",
            "app/hb-service"
        ]
    },
    "port-config": {
        "protocol-file": "app/homebridge.sc"
    }
}
```

### start-stop-status
```bash
#!/bin/bash
case "$1" in
    start)
        if [ "${EUID}" -eq 0 ]; then
            sudo -u homebridge synosystemctl start pkguser-homebridge
        else
            synosystemctl start pkguser-homebridge
        fi
        ;;
    stop)
        if [ "${EUID}" -eq 0 ]; then
            sudo -u homebridge synosystemctl stop pkguser-homebridge
        else
            synosystemctl stop pkguser-homebridge
        fi
        ;;
    status)
        if [ "${EUID}" -eq 0 ]; then
            sudo -u homebridge synosystemctl get-active-status pkguser-homebridge
        else
            synosystemctl get-active-status pkguser-homebridge
        fi
        ;;
    log)
        echo ""
        ;;
    *)
        echo "Usage: $0 {start|stop|status}" >&2
        exit 1
        ;;
esac
```

---

## 13. SynoCommunity Contribution Guidelines

### Package Request Format
- Software name and description
- Website and documentation links
- Build/installation documentation
- Source code location
- License information

### Pull Request Requirements
1. Create a new branch (never work on master)
2. `make all-supported` builds successfully
3. Package upgrade works correctly
4. New installation completes without errors
5. Reference the Developers HOW-TO for setup

### Issue Format
- Title: `[package name] Short description`
- Include: NAS model, architecture, DSM version
- Include: what you did, expected vs actual results
- Provide logs (backtick-wrapped or linked)

### PR Checklist
- [ ] Build rule `all-supported` completes successfully
- [ ] Package upgrade succeeds
- [ ] New installation completes without errors
- [ ] WIP PRs use `[WIP]` prefix

### Code Standards
- All package names in SynoCommunity use lowercase letters only
- Maintainer should be a GitHub username
- Custom targets follow naming: `INSTALL_TARGET = newpackage_install`
- Clean up development artifacts before submitting

---

## 14. Recommendations for Uptime Kuma SPK

### Architecture Decision
**Option 1 — spksrc Framework (SynoCommunity submission path)**
- Use the spksrc build system
- Create `cross/uptime-kuma` for the application build
- Create `spk/uptime-kuma` for the SPK packaging
- Pro: Direct path to SynoCommunity repository inclusion
- Con: More complex, needs cross-compilation setup for better-sqlite3

**Option 2 — Standalone SPK (Homebridge-style)**
- Use Synology's toolkit directly
- Build architecture-specific packages
- Pro: More control, simpler for Node.js apps
- Con: Not in SynoCommunity, must host repository yourself

**Option 3 — Hybrid: noarch SPK with Node.js dependency**
- If Uptime Kuma can run without native modules or with prebuilt binaries
- Set `arch="noarch"` for universal package
- Depend on `Node.js_v22` for runtime
- Pro: One package for all architectures
- Con: Native module challenges (better-sqlite3)

### Recommended Package Structure for Uptime Kuma
```
spk/uptime-kuma/
├── Makefile
└── src/
    ├── uptime-kuma.png          # 256x256 icon
    ├── service-setup.sh         # Service hooks
    ├── start.sh                 # Start script wrapper
    ├── conf/                    # (Optional custom conf)
    │   ├── privilege
    │   └── resource
    ├── wizard/
    │   └── install_uifile       # Installation wizard
    └── app/                     # Application files (or use DEPENDS)
```

### Key Configuration Values
```
SPK_NAME = uptime-kuma
SERVICE_PORT = 3001
SERVICE_USER = auto
STARTABLE = yes
install_dep_packages = Node.js_v22 (in INFO)
```

### Service Start Pattern
```bash
# service-setup.sh
NODE="/var/packages/Node.js_v22/target/usr/local/bin/node"
# Or find node dynamically:
NODE=$(which node 2>/dev/null || echo "/var/packages/Node.js_v22/target/usr/local/bin/node")

SERVICE_COMMAND="${NODE} ${SYNOPKG_PKGDEST}/server/server.js"
SVC_CWD="${SYNOPKG_PKGDEST}"
SVC_BACKGROUND=y
SVC_WRITE_PID=y

# Environment
export UPTIME_KUMA_HOST=0.0.0.0
export UPTIME_KUMA_PORT=${SERVICE_PORT}
export DATA_DIR="${SYNOPKG_PKGVAR}"
```

---

## Sources

- [SynoCommunity/spksrc GitHub](https://github.com/SynoCommunity/spksrc)
- [spksrc CONTRIBUTING.md](https://github.com/SynoCommunity/spksrc/blob/master/CONTRIBUTING.md)
- [spksrc Developers HOW-TO](https://github.com/SynoCommunity/spksrc/wiki/Developers-HOW-TO)
- [spksrc Makefile Variables](https://github.com/SynoCommunity/spksrc/wiki/Makefile-variables)
- [spksrc Service Support](https://github.com/SynoCommunity/spksrc/wiki/Service-Support)
- [spksrc Permission Management](https://github.com/SynoCommunity/spksrc/wiki/Permission-Management)
- [Synology Developer Guide](https://help.synology.com/developer-guide/synology_package/introduction.html)
- [Synology INFO Necessary Fields](https://help.synology.com/developer-guide/synology_package/INFO_necessary_fields.html)
- [Synology INFO Optional Fields](https://help.synology.com/developer-guide/synology_package/INFO_optional_fields.html)
- [Synology Privilege Configuration](https://help.synology.com/developer-guide/privilege/preface.html)
- [Synology Port Config Worker](https://help.synology.com/developer-guide/resource_acquisition/port_config.html)
- [Synology Data Share Worker](https://help.synology.com/developer-guide/resource_acquisition/data_share.html)
- [Synology usr-local-linker](https://help.synology.com/developer-guide/resource_acquisition/usrlocal_linker.html)
- [Synology DSM 7 Breaking Changes](https://help.synology.com/developer-guide/breaking_changes.html)
- [Synology WIZARD_UIFILES v2](https://help.synology.com/developer-guide/synology_package/wizard/WIZARD_UIFILES_v2.html)
- [Synology First Package Guide](https://help.synology.com/developer-guide/getting_started/first_package.html)
- [Homebridge SPK](https://github.com/homebridge/homebridge-syno-spk)
- [DSM 7 Developer Guide PDF](https://global.download.synology.com/download/Document/Software/DeveloperGuide/Os/DSM/All/enu/DSM_Developer_Guide_7_enu.pdf)
