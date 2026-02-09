# Contributing to Uptime Kuma SPK

Thank you for your interest in contributing to the Uptime Kuma SPK package for Synology NAS.

## Ways to Contribute

- Report bugs or installation issues
- Test on different NAS models and DSM versions
- Improve documentation
- Add translations for the installation wizard
- Submit code improvements

## Development Setup

### Prerequisites

- Docker (for building with spksrc)
- Git
- A Synology NAS or Virtual DSM for testing

### Getting Started

1. Fork this repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/synology-uptime-kuma.git
   cd synology-uptime-kuma
   ```
3. Set up the spksrc build environment (see [BUILD.md](BUILD.md))
4. Make your changes
5. Build and test the SPK on a NAS or Virtual DSM

### Project Structure

```
.
├── cross/uptime-kuma/       # Cross-compilation rules (download, build, install)
│   ├── Makefile             # Build targets for Uptime Kuma application
│   └── digests              # SHA256 checksums for source verification
├── spk/uptime-kuma/         # SPK package definition
│   ├── Makefile             # Package metadata (name, version, ports, etc.)
│   ├── INFO.sh              # Package Center metadata generator
│   └── src/
│       ├── service-setup.sh # Service lifecycle hooks
│       ├── uptime-kuma.png  # Package icon (256x256)
│       ├── conf/            # DSM privilege and resource configuration
│       ├── app/             # Service port configuration (.sc file)
│       ├── wizard/          # Installation and upgrade wizard UI files
│       ├── DESCRIPTION_*    # Localized package descriptions
├── icons/                   # SVG source icon
├── scripts/                 # Utility scripts (icon generation)
├── screenshots/             # Package Center screenshots
├── Makefile                 # Top-level build entry point
└── PLIST                    # Package file listing
```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use meaningful variable names with uppercase for constants and environment variables
- Quote all variable expansions: `"${VAR}"` not `$VAR`
- Add comments for non-obvious logic
- Use functions for reusable blocks
- Test with `shellcheck` when possible

### Makefiles

- Follow the spksrc naming conventions for targets (e.g., `pkgname_extra_install`)
- Use `@$(MSG)` for build progress messages
- Use `@` prefix to suppress command echo

### JSON Files (Wizard, Config)

- Use consistent indentation (4 spaces)
- Validate JSON before committing

## Adding Translations

### Package Descriptions

Create a new `DESCRIPTION_<lang>` file in `spk/uptime-kuma/src/`:

- `DESCRIPTION_enu` -- English (required)
- `DESCRIPTION_fre` -- French
- `DESCRIPTION_ger` -- German
- `DESCRIPTION_spn` -- Spanish
- `DESCRIPTION_jpn` -- Japanese
- `DESCRIPTION_chs` -- Chinese Simplified

Language codes follow the Synology convention (3-letter codes).

### Installation Wizard

Create a localized version of `install_uifile` in `spk/uptime-kuma/src/wizard/`:

- `install_uifile` -- English (default)
- `install_uifile_fre` -- French
- `install_uifile_ger` -- German

The file format is JSON. Translate the `desc` and `step_title` values.

## Testing Requirements

Before submitting a pull request, verify:

1. **Build passes:** `make all-supported` completes without errors
2. **Fresh install works:** Install the SPK on a clean NAS (no prior Uptime Kuma data)
3. **Upgrade works:** Upgrade from the previous version and verify data is preserved
4. **Service lifecycle:** Start, stop, and restart work correctly via Package Center
5. **Web UI accessible:** The Uptime Kuma web interface loads after installation

Test on at least one NAS model or Virtual DSM before submitting.

## Submitting a Pull Request

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-change
   ```
2. Make your changes in small, focused commits
3. Write clear commit messages describing the "why"
4. Push your branch and open a PR against `main`
5. Fill out the PR template with:
   - Summary of changes
   - Testing performed (NAS model, DSM version, architecture)
   - Screenshots if applicable

## Reporting Issues

When reporting a bug, include:

- **NAS model** (e.g., DS920+)
- **Architecture** (x86_64, aarch64, or armv7)
- **DSM version** (e.g., 7.2.1-69057 Update 5)
- **Package version** (e.g., 2.1.0-1)
- **Steps to reproduce** the issue
- **Log output** from `/var/log/packages/uptime-kuma.log`
- **Expected behavior** vs **actual behavior**

## Versioning

The package version follows the format `<upstream_version>-<package_revision>`:

- `2.1.0-1` means Uptime Kuma v2.1.0, package revision 1
- When updating Uptime Kuma: bump `SPK_VERS` in both Makefiles, reset `SPK_REV` to 1
- When fixing the package only: increment `SPK_REV`

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
