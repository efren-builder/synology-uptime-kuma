PKG_NAME = uptime-kuma
PKG_VERS = 2.1.0
PKG_EXT = tar.gz
PKG_DIST_NAME = $(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://github.com/louislam/uptime-kuma/archive/refs/tags
PKG_DIST_FILE = $(PKG_NAME)-$(PKG_VERS).$(PKG_EXT)
PKG_DIR = $(PKG_NAME)-$(PKG_VERS)

DEPENDS =

HOMEPAGE = https://uptime.kuma.pet
COMMENT  = A self-hosted monitoring tool
LICENSE  = MIT

# Node.js path for spksrc build environment
# For standalone builds, use scripts/build-spk.sh which bundles Node.js
NODE_DIR = /usr/local
NODE_BIN = $(NODE_DIR)/bin/node
NPM_BIN  = $(NODE_DIR)/bin/npm

CONFIGURE_TARGET = nop
COMPILE_TARGET = uptime_kuma_compile
INSTALL_TARGET = uptime_kuma_install

# Uptime Kuma pre-built frontend dist URL
DIST_URL = https://github.com/louislam/uptime-kuma/releases/download/$(PKG_VERS)/dist.tar.gz

include ../../mk/spksrc.cross-cc.mk

.PHONY: uptime_kuma_compile
uptime_kuma_compile:
	@$(MSG) "Installing production dependencies for Uptime Kuma"
	cd $(WORK_DIR)/$(PKG_DIR) && \
		env HOME=$(WORK_DIR) PATH=$(NODE_DIR)/bin:$$PATH \
		$(NPM_BIN) ci --omit dev --no-audit --no-fund
	@$(MSG) "Downloading pre-built frontend dist"
	cd $(WORK_DIR)/$(PKG_DIR) && \
		curl -sL "$(DIST_URL)" | tar xzf -

.PHONY: uptime_kuma_install
uptime_kuma_install:
	@$(MSG) "Installing Uptime Kuma to staging directory"
	@install -d $(STAGING_INSTALL_PREFIX)/uptime-kuma
	@# Install server files
	@cp -a $(WORK_DIR)/$(PKG_DIR)/server $(STAGING_INSTALL_PREFIX)/uptime-kuma/server
	@# Install pre-built frontend dist
	@cp -a $(WORK_DIR)/$(PKG_DIR)/dist $(STAGING_INSTALL_PREFIX)/uptime-kuma/dist
	@# Install node_modules (production only)
	@cp -a $(WORK_DIR)/$(PKG_DIR)/node_modules $(STAGING_INSTALL_PREFIX)/uptime-kuma/node_modules
	@# Install package metadata files
	@cp -a $(WORK_DIR)/$(PKG_DIR)/package.json $(STAGING_INSTALL_PREFIX)/uptime-kuma/package.json
	@# Install database directory structure
	@install -d $(STAGING_INSTALL_PREFIX)/uptime-kuma/db
	@# Copy migration files if present
	@if [ -d "$(WORK_DIR)/$(PKG_DIR)/db" ]; then \
		cp -a $(WORK_DIR)/$(PKG_DIR)/db/* $(STAGING_INSTALL_PREFIX)/uptime-kuma/db/ 2>/dev/null || true; \
	fi
	@# Copy extra directories needed at runtime
	@for dir in config extra src; do \
		if [ -d "$(WORK_DIR)/$(PKG_DIR)/$$dir" ]; then \
			cp -a "$(WORK_DIR)/$(PKG_DIR)/$$dir" $(STAGING_INSTALL_PREFIX)/uptime-kuma/$$dir; \
		fi; \
	done
