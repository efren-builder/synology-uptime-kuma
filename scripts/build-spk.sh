#!/bin/bash
# build-spk.sh — Build Uptime Kuma SPK package for Synology NAS
#
# This script builds a complete .spk file without requiring the full spksrc
# toolchain. It uses Docker to install npm dependencies for Linux x86_64.
#
# Usage: ./scripts/build-spk.sh [arch]
#   arch: x64 (default), aarch64, armv7
#
# Output: packages/uptime-kuma-2.1.0-1_x86_64.spk

set -euo pipefail

# Configuration
PKG_NAME="uptime-kuma"
PKG_VERS="2.1.0"
SPK_REV="1"
ARCH="${1:-x64}"
NODE_MAJOR="22"
NODE_VERSION="22.22.0"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
PACKAGE_DIR="${BUILD_DIR}/package"
SPK_DIR="${BUILD_DIR}/spk"
OUTPUT_DIR="${PROJECT_DIR}/packages"

# Map arch names
case "${ARCH}" in
    x64|x86_64|amd64)
        ARCH_NAME="x86_64"
        DOCKER_PLATFORM="linux/amd64"
        NPM_ARCH="x64"
        NODE_ARCH="linux-x64-glibc-217"
        ;;
    aarch64|arm64)
        ARCH_NAME="aarch64"
        DOCKER_PLATFORM="linux/arm64"
        NPM_ARCH="arm64"
        NODE_ARCH="linux-arm64-glibc-217"
        ;;
    armv7|armhf)
        ARCH_NAME="armv7"
        DOCKER_PLATFORM="linux/arm/v7"
        NPM_ARCH="arm"
        NODE_ARCH="linux-armv7l-glibc-217"
        ;;
    *)
        echo "Unknown architecture: ${ARCH}"
        echo "Usage: $0 [x64|aarch64|armv7]"
        exit 1
        ;;
esac

SPK_FILE="${OUTPUT_DIR}/${PKG_NAME}-${PKG_VERS}-${SPK_REV}_${ARCH_NAME}.spk"

echo "============================================="
echo "  Uptime Kuma SPK Builder"
echo "============================================="
echo "  Version:      ${PKG_VERS}"
echo "  Revision:     ${SPK_REV}"
echo "  Architecture: ${ARCH_NAME}"
echo "  Platform:     ${DOCKER_PLATFORM}"
echo "  Output:       ${SPK_FILE}"
echo "============================================="
echo ""

# Clean previous build
echo "[1/8] Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${PACKAGE_DIR}" "${SPK_DIR}" "${OUTPUT_DIR}"

# Download source
echo "[2/8] Downloading Uptime Kuma v${PKG_VERS}..."
TARBALL_URL="https://github.com/louislam/uptime-kuma/archive/refs/tags/${PKG_VERS}.tar.gz"
curl -fsSL "${TARBALL_URL}" -o "${BUILD_DIR}/source.tar.gz"

# Verify checksum
echo "  Verifying SHA256 checksum..."
EXPECTED_SHA="4514170107a914f79f7831d7b6fa76ca18e59b2da7185c8826d6faae6633203d"
ACTUAL_SHA=$(shasum -a 256 "${BUILD_DIR}/source.tar.gz" | awk '{print $1}')
if [ "${ACTUAL_SHA}" != "${EXPECTED_SHA}" ]; then
    echo "  ERROR: SHA256 mismatch!"
    echo "  Expected: ${EXPECTED_SHA}"
    echo "  Got:      ${ACTUAL_SHA}"
    exit 1
fi
echo "  Checksum OK."

# Extract source
echo "[3/8] Extracting source..."
tar xzf "${BUILD_DIR}/source.tar.gz" -C "${BUILD_DIR}"
SRC_DIR="${BUILD_DIR}/uptime-kuma-${PKG_VERS}"

# Download Node.js binary for the target architecture
echo "[4/8] Downloading Node.js v${NODE_VERSION} for ${ARCH_NAME}..."
NODE_TARBALL="node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz"
# Use unofficial builds compiled against glibc 2.17 for Synology DSM compatibility
NODE_URL="https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/${NODE_TARBALL}"
curl -fsSL "${NODE_URL}" -o "${BUILD_DIR}/${NODE_TARBALL}"
echo "  Extracting Node.js..."
tar xJf "${BUILD_DIR}/${NODE_TARBALL}" -C "${BUILD_DIR}"
NODE_EXTRACTED="${BUILD_DIR}/node-v${NODE_VERSION}-${NODE_ARCH}"
echo "  Node.js v${NODE_VERSION} ready."

# Install production dependencies using Docker (for correct Linux architecture)
echo "[5/8] Installing production dependencies for ${ARCH_NAME} (via Docker)..."
echo "  This may take a few minutes on first run..."

docker run --rm --platform "${DOCKER_PLATFORM}" \
    -v "${SRC_DIR}:/app" \
    -w /app \
    "node:${NODE_MAJOR}-bookworm-slim" \
    sh -c "npm ci --omit dev --no-audit --no-fund 2>&1 | tail -5"

echo "  Dependencies installed."

# Download pre-built frontend dist
echo "[6/8] Downloading pre-built frontend..."
DIST_URL="https://github.com/louislam/uptime-kuma/releases/download/${PKG_VERS}/dist.tar.gz"
curl -fsSL "${DIST_URL}" -o "${BUILD_DIR}/dist.tar.gz"
tar xzf "${BUILD_DIR}/dist.tar.gz" -C "${SRC_DIR}"
echo "  Frontend downloaded."

# Assemble package contents
echo "[7/8] Assembling package..."

# Create the app directory structure inside package
APP_DIR="${PACKAGE_DIR}/uptime-kuma"
mkdir -p "${APP_DIR}"

# Copy application files
cp -a "${SRC_DIR}/server" "${APP_DIR}/server"
cp -a "${SRC_DIR}/dist" "${APP_DIR}/dist"
cp -a "${SRC_DIR}/node_modules" "${APP_DIR}/node_modules"
cp -a "${SRC_DIR}/package.json" "${APP_DIR}/package.json"

# Copy db directory if it exists (migration files)
if [ -d "${SRC_DIR}/db" ]; then
    cp -a "${SRC_DIR}/db" "${APP_DIR}/db"
fi

# Copy extra/config/src dirs if they exist
for dir in config extra src; do
    if [ -d "${SRC_DIR}/${dir}" ]; then
        cp -a "${SRC_DIR}/${dir}" "${APP_DIR}/${dir}"
    fi
done

# Bundle Node.js runtime
echo "  Bundling Node.js v${NODE_VERSION}..."
mkdir -p "${PACKAGE_DIR}/node/bin"
cp "${NODE_EXTRACTED}/bin/node" "${PACKAGE_DIR}/node/bin/node"
# Create npm/npx symlinks pointing to the bundled node
cp -a "${NODE_EXTRACTED}/lib" "${PACKAGE_DIR}/node/lib"
cp "${NODE_EXTRACTED}/bin/npm" "${PACKAGE_DIR}/node/bin/npm" 2>/dev/null || true
cp "${NODE_EXTRACTED}/bin/npx" "${PACKAGE_DIR}/node/bin/npx" 2>/dev/null || true
echo "  Node.js bundled ($(du -sh "${PACKAGE_DIR}/node" | awk '{print $1}'))."

# Copy the port config file
mkdir -p "${PACKAGE_DIR}/app"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/app/uptime-kuma.sc" "${PACKAGE_DIR}/app/"

# Create package.tgz
echo "  Creating package.tgz..."
(cd "${PACKAGE_DIR}" && tar czf "${SPK_DIR}/package.tgz" .)

# Build the SPK archive
echo "[8/8] Building SPK file..."

# Copy scripts
mkdir -p "${SPK_DIR}/scripts"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/service-setup.sh" "${SPK_DIR}/scripts/service-setup"

# Generate the start-stop-status script (simplified for standalone build)
cat > "${SPK_DIR}/scripts/start-stop-status" << 'SSEOF'
#!/bin/sh

# Source service-setup for configuration
. "$(dirname "$0")/service-setup"

case "$1" in
    start)
        echo "Starting ${SYNOPKG_PKGNAME}..."

        # Run prestart checks
        if type service_prestart >/dev/null 2>&1; then
            service_prestart || exit 1
        fi

        # Start the service in background
        cd "${SVC_CWD}"
        export UPTIME_KUMA_HOST UPTIME_KUMA_PORT DATA_DIR NODE_ENV PATH
        nohup ${SERVICE_COMMAND} >> "${LOG_FILE:-/dev/null}" 2>&1 &
        echo $! > "${PID_FILE}"
        echo "Started with PID $(cat "${PID_FILE}")"
        ;;
    stop)
        echo "Stopping ${SYNOPKG_PKGNAME}..."
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            if kill -0 "${PID}" 2>/dev/null; then
                kill -TERM "${PID}"
                # Wait up to 30 seconds for graceful shutdown
                TIMEOUT=30
                while [ ${TIMEOUT} -gt 0 ] && kill -0 "${PID}" 2>/dev/null; do
                    sleep 1
                    TIMEOUT=$((TIMEOUT - 1))
                done
                if kill -0 "${PID}" 2>/dev/null; then
                    kill -9 "${PID}" 2>/dev/null
                fi
            fi
            rm -f "${PID_FILE}"
        fi

        if type service_poststop >/dev/null 2>&1; then
            service_poststop
        fi
        ;;
    status)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            if kill -0 "${PID}" 2>/dev/null; then
                exit 0  # Running
            fi
        fi
        exit 3  # Not running
        ;;
    log)
        echo "${LOG_FILE:-/var/log/packages/${SYNOPKG_PKGNAME}.log}"
        ;;
    *)
        echo "Usage: $0 {start|stop|status|log}" >&2
        exit 1
        ;;
esac
SSEOF
chmod +x "${SPK_DIR}/scripts/start-stop-status"

# Generate installer scripts
cat > "${SPK_DIR}/scripts/preinst" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/service-setup"
if type validate_preinst >/dev/null 2>&1; then
    validate_preinst || exit 1
fi
exit 0
EOF

cat > "${SPK_DIR}/scripts/postinst" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/service-setup"
if type service_postinst >/dev/null 2>&1; then
    service_postinst
fi
exit 0
EOF

cat > "${SPK_DIR}/scripts/preuninst" << 'EOF'
#!/bin/sh
exit 0
EOF

cat > "${SPK_DIR}/scripts/postuninst" << 'EOF'
#!/bin/sh
exit 0
EOF

cat > "${SPK_DIR}/scripts/preupgrade" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/service-setup"
if type service_preupgrade >/dev/null 2>&1; then
    service_preupgrade || exit 1
fi
exit 0
EOF

cat > "${SPK_DIR}/scripts/postupgrade" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/service-setup"
if type service_postupgrade >/dev/null 2>&1; then
    service_postupgrade
fi
exit 0
EOF

chmod +x "${SPK_DIR}/scripts/"*

# Copy conf directory
mkdir -p "${SPK_DIR}/conf"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/conf/privilege" "${SPK_DIR}/conf/"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/conf/resource" "${SPK_DIR}/conf/"

# Copy wizard
mkdir -p "${SPK_DIR}/WIZARD_UIFILES"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/wizard/install_uifile" "${SPK_DIR}/WIZARD_UIFILES/"
cp "${PROJECT_DIR}/spk/uptime-kuma/src/wizard/upgrade_uifile" "${SPK_DIR}/WIZARD_UIFILES/"
# Copy localized wizards if they exist
for f in "${PROJECT_DIR}/spk/uptime-kuma/src/wizard/install_uifile_"*; do
    [ -f "$f" ] && cp "$f" "${SPK_DIR}/WIZARD_UIFILES/"
done

# Copy icons
cp "${PROJECT_DIR}/spk/uptime-kuma/PACKAGE_ICON.PNG" "${SPK_DIR}/"
cp "${PROJECT_DIR}/spk/uptime-kuma/PACKAGE_ICON_256.PNG" "${SPK_DIR}/"

# Copy LICENSE
cp "${PROJECT_DIR}/LICENSE" "${SPK_DIR}/LICENSE"

# Generate INFO file
cat > "${SPK_DIR}/INFO" << INFOEOF
package="${PKG_NAME}"
version="${PKG_VERS}-${SPK_REV}"
os_min_ver="7.0-40000"
displayname="Uptime Kuma"
description="A self-hosted monitoring tool. Monitor HTTP(s), TCP, Ping, DNS, Docker, MQTT, and more. Features 87+ notification providers, status pages, 2FA, proxy support, and certificate monitoring."
arch="${ARCH_NAME}"
maintainer="efren-builder"
maintainer_url="https://efren.me"
support_url="https://github.com/louislam/uptime-kuma/wiki"
adminprotocol="http"
adminport="3001"
adminurl="/"
startable="yes"
checkport="yes"
silent_install="no"
silent_upgrade="no"
support_conf_folder="yes"
INFOEOF

# Create the final .spk (tar archive)
echo "  Creating ${SPK_FILE}..."
(cd "${SPK_DIR}" && tar cf "${SPK_FILE}" INFO package.tgz scripts conf WIZARD_UIFILES PACKAGE_ICON.PNG PACKAGE_ICON_256.PNG LICENSE)

# Report
SPK_SIZE=$(du -sh "${SPK_FILE}" | awk '{print $1}')
echo ""
echo "============================================="
echo "  BUILD COMPLETE"
echo "============================================="
echo "  Output: ${SPK_FILE}"
echo "  Size:   ${SPK_SIZE}"
echo "============================================="
echo ""
echo "To install on your Synology NAS:"
echo "  1. Open Package Center"
echo "  2. Click 'Manual Install' (top-right)"
echo "  3. Upload: ${SPK_FILE}"
echo "  4. Follow the wizard"
echo "  5. Open http://YOUR_NAS_IP:3001"
echo ""
