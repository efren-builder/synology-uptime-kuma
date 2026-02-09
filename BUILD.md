# Building the Uptime Kuma SPK Package

This document describes how to build the Uptime Kuma SPK package for Synology NAS.

## Prerequisites

- **Docker** (recommended) or a Debian/Ubuntu build machine
- **Git**
- **Internet access** for downloading toolchains and source code
- ~10 GB free disk space for the build environment

## Option A: Standalone Build Script (Recommended)

The standalone build script handles everything -- downloads Node.js, Uptime Kuma source, and assembles the SPK without needing the full spksrc toolchain.

```bash
# Build for x86_64 (Intel/AMD NAS -- default)
./scripts/build-spk.sh

# The .spk file is placed in packages/
ls packages/*.spk
```

The script:
1. Downloads the Uptime Kuma v2.1.0 source tarball and verifies its SHA256 hash
2. Downloads a glibc 2.17 compatible Node.js 22 binary for the target architecture
3. Runs `npm ci --omit dev` to install production dependencies
4. Downloads the pre-built frontend from GitHub Releases
5. Assembles the SPK archive with scripts, icons, wizard, and configuration

### Changing the target architecture

Edit the `ARCH` variable at the top of `scripts/build-spk.sh`:

| ARCH | Target |
|------|--------|
| `x86_64` | Intel/AMD NAS (DS220+, DS920+, etc.) |
| `aarch64` | ARM64 NAS (DS223, DS224+, etc.) |
| `armv7` | Older ARM NAS (DS218, DS118, etc.) |

## Option B: Build with spksrc

For integration with the [spksrc](https://github.com/SynoCommunity/spksrc) build system:

### Repository Setup

```bash
# Clone the spksrc repository
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc

# Copy the Uptime Kuma package files into the spksrc tree
cp -r /path/to/this/repo/cross/uptime-kuma cross/
cp -r /path/to/this/repo/spk/uptime-kuma spk/
```

Or use as an overlay (symlinks):

```bash
cd /path/to/spksrc
ln -s /path/to/this/repo/cross/uptime-kuma cross/uptime-kuma
ln -s /path/to/this/repo/spk/uptime-kuma spk/uptime-kuma
```

### Building with Docker

```bash
cd spksrc

# Build the Docker image (first time only)
docker build -t spksrc -f Dockerfile .

# Or pull the pre-built image
docker pull ghcr.io/synocommunity/spksrc

# Start the build container
docker run -it -v $(pwd):/spksrc ghcr.io/synocommunity/spksrc /bin/bash

# Inside the container:
cd /spksrc/spk/uptime-kuma

# Build for x86_64
make arch-x64-7.1

# Or build for all architectures
make all-supported
```

### Building without Docker

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential automake autoconf libtool pkg-config cmake \
    git curl wget python3 bison flex gawk gettext libssl-dev zlib1g-dev

cd spksrc
make setup

cd spk/uptime-kuma
make arch-x64-7.1
```

## Build Output

Built SPK files are placed in the `packages/` directory:

```
packages/
  uptime-kuma_x86_64-7.1_2.1.0-1.spk
```

## Build Process Overview

The build performs these steps:

1. **Download** -- Fetches the Uptime Kuma v2.1.0 source tarball from GitHub
2. **Verify** -- Checks SHA256 hash against `cross/uptime-kuma/digests`
3. **Extract** -- Unpacks the source into the work directory
4. **Download Node.js** -- Fetches a glibc 2.17 compatible Node.js 22 binary
5. **Install deps** -- Runs `npm ci --omit dev` to install production Node.js dependencies
6. **Download dist** -- Fetches the pre-built frontend from GitHub Releases
7. **Package** -- Assembles the SPK archive with scripts, icons, wizard, and configuration

## Updating the Digest

Before building, ensure the digest file has the correct SHA256 hash:

```bash
# Download the tarball and compute its hash
curl -sL https://github.com/louislam/uptime-kuma/archive/refs/tags/2.1.0.tar.gz | shasum -a 256

# Update cross/uptime-kuma/digests with the output
```

## Testing the Built SPK

### Install on a test NAS

1. Copy the `.spk` file to your NAS (via SMB, SCP, or web upload)
2. Open Package Center > Manual Install
3. Browse to the `.spk` file
4. Complete the installation wizard
5. Verify the service starts and the web UI is accessible

### Install on Virtual DSM

For testing without a physical NAS:

1. Set up Virtual DSM in VMware or VirtualBox (see [Synology Virtual DSM](https://www.synology.com/dsm/feature/virtual_dsm))
2. Install the SPK as described above
3. Test all lifecycle operations (install, start, stop, upgrade, uninstall)

### Verify package contents

```bash
# Inspect the SPK archive
tar -tvf packages/uptime-kuma_x86_64-7.1_2.1.0-1.spk

# Inspect the inner package.tgz
tar -xf packages/uptime-kuma_x86_64-7.1_2.1.0-1.spk package.tgz
tar -tvf package.tgz | head -50
```

## Troubleshooting Build Issues

### npm ci fails

- Ensure the build environment has internet access
- Check that Node.js is available in the build path
- Try clearing the npm cache: `npm cache clean --force`

### Hash mismatch

- Re-download the source tarball
- Recompute the SHA256 hash
- Update `cross/uptime-kuma/digests` with the correct value

### Cleaning Build Artifacts

```bash
# Clean standalone build
rm -rf build/ packages/*.spk

# Clean spksrc build
cd spksrc/spk/uptime-kuma
make clean
```
