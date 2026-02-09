# Building the Uptime Kuma SPK Package

This document describes how to build the Uptime Kuma SPK package for Synology NAS using the SynoCommunity spksrc build system.

## Prerequisites

- **Docker** (recommended) or a Debian/Ubuntu build machine
- **Git**
- **Internet access** for downloading toolchains and source code
- ~10 GB free disk space for the build environment

## Repository Setup

### Option A: Build within the spksrc tree (recommended)

```bash
# Clone the spksrc repository
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc

# Copy the Uptime Kuma package files into the spksrc tree
cp -r /path/to/uptime-kuma-spk/cross/uptime-kuma cross/
cp -r /path/to/uptime-kuma-spk/spk/uptime-kuma spk/
```

### Option B: Use as an overlay

Symlink the package directories into an existing spksrc checkout:

```bash
cd /path/to/spksrc
ln -s /path/to/uptime-kuma-spk/cross/uptime-kuma cross/uptime-kuma
ln -s /path/to/uptime-kuma-spk/spk/uptime-kuma spk/uptime-kuma
```

## Building with Docker (Recommended)

The spksrc project provides a Docker-based build environment that includes all necessary toolchains.

### 1. Set up the Docker environment

```bash
cd spksrc

# Build the Docker image (first time only)
docker build -t spksrc -f Dockerfile .

# Or pull the pre-built image
docker pull ghcr.io/synocommunity/spksrc
```

### 2. Start the build container

```bash
docker run -it -v $(pwd):/spksrc ghcr.io/synocommunity/spksrc /bin/bash
```

### 3. Build for a specific architecture

Inside the container:

```bash
cd /spksrc/spk/uptime-kuma

# Build for x86_64 (Intel/AMD NAS)
make arch-x64-7.1

# Build for aarch64 (ARM64 NAS, e.g., DS223, DS224+)
make arch-aarch64-7.1

# Build for armv7 (older ARM NAS, e.g., DS218)
make arch-armv7-7.1
```

### 4. Build for all supported architectures

```bash
cd /spksrc/spk/uptime-kuma
make all-supported
```

This builds the SPK for every architecture supported by the package.

## Building without Docker

### 1. Install build dependencies

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    automake \
    autoconf \
    libtool \
    pkg-config \
    cmake \
    git \
    curl \
    wget \
    python3 \
    bison \
    flex \
    gawk \
    gettext \
    libssl-dev \
    zlib1g-dev
```

### 2. Set up spksrc

```bash
cd spksrc
make setup
```

### 3. Build

```bash
cd spk/uptime-kuma
make arch-x64-7.1
```

## Build Output

Built SPK files are placed in the `spksrc/packages/` directory:

```
packages/
  uptime-kuma_x86_64-7.1_2.1.0-1.spk
  uptime-kuma_aarch64-7.1_2.1.0-1.spk
  uptime-kuma_armv7-7.1_2.1.0-1.spk
```

The filename format is: `<name>_<arch>-<dsm>_<version>.spk`

## Build Process Overview

The build system performs these steps:

1. **Download** -- Fetches the Uptime Kuma v2.1.0 source tarball from GitHub
2. **Verify** -- Checks SHA256 hash against `cross/uptime-kuma/digests`
3. **Extract** -- Unpacks the source into the work directory
4. **Compile** -- Runs `npm ci --omit dev` to install production Node.js dependencies
5. **Download dist** -- Fetches the pre-built frontend from GitHub Releases
6. **Install** -- Copies server, dist, node_modules, and metadata to the staging directory
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

- Ensure the Docker container has internet access
- Check that Node.js_v22 paths are correct in the cross Makefile
- Try clearing the npm cache: `npm cache clean --force`

### Toolchain download fails

- Verify internet connectivity from the build environment
- Check the spksrc wiki for known toolchain issues
- Try `make clean` and rebuild

### Architecture not supported

- Check `UNSUPPORTED_ARCHS` in the SPK Makefile
- Verify the toolchain exists for the target architecture
- See the spksrc wiki for supported architecture list

### Hash mismatch

- Re-download the source tarball
- Recompute the SHA256 hash
- Update `cross/uptime-kuma/digests` with the correct value

## Cleaning Build Artifacts

```bash
# Clean everything
cd spksrc/spk/uptime-kuma
make clean

# Clean only SPK artifacts (keep downloaded sources)
make spkclean

# Clean the cross-compilation artifacts
cd spksrc/cross/uptime-kuma
make clean
```
