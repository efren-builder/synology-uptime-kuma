# Top-level Makefile for Uptime Kuma SPK
# Compatible with spksrc build system
#
# Usage:
#   make setup          - Verify build environment
#   make clean          - Clean build artifacts
#   make spk            - Build SPK package (run from spk/uptime-kuma/)
#
# For spksrc integration, this repository should be placed within
# the spksrc tree or referenced as an overlay.

.PHONY: all setup clean spk help

all: spk

setup:
	@echo "=== Uptime Kuma SPK Build Environment ==="
	@echo "Checking prerequisites..."
	@command -v tar >/dev/null 2>&1 || { echo "ERROR: tar is required"; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required"; exit 1; }
	@command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || { echo "ERROR: sha256sum or shasum is required"; exit 1; }
	@echo "Prerequisites OK."

spk:
	$(MAKE) -C spk/uptime-kuma

clean:
	$(MAKE) -C spk/uptime-kuma clean
	$(MAKE) -C cross/uptime-kuma clean

help:
	@echo "Uptime Kuma SPK Package Builder"
	@echo ""
	@echo "Targets:"
	@echo "  setup   - Check build prerequisites"
	@echo "  spk     - Build SPK package (delegates to spk/uptime-kuma)"
	@echo "  clean   - Clean all build artifacts"
	@echo "  help    - Show this help"
	@echo ""
	@echo "For spksrc integration:"
	@echo "  cd spk/uptime-kuma && make arch-x64-7.1"
	@echo "  cd spk/uptime-kuma && make all-supported"
