#!/bin/bash
# INFO.sh — Generates the INFO metadata file for the Uptime Kuma SPK package
# This file is sourced by the spksrc build system or Synology toolkit.

package="uptime-kuma"
version="2.1.0-1"
os_min_ver="7.0-40000"
displayname="Uptime Kuma"
description="A self-hosted monitoring tool. Monitor HTTP(s), TCP, Ping, DNS, Docker, MQTT, and more. Features 87+ notification providers, status pages, 2FA, proxy support, and certificate monitoring."
arch="x86_64 aarch64 armv7"
maintainer="efren-builder"
maintainer_url="https://efren.me"
support_url="https://github.com/louislam/uptime-kuma/wiki"
adminprotocol="http"
adminport="3001"
adminurl="/"
startable="yes"
# Node.js is bundled in the package (DSM only provides up to v18, Uptime Kuma requires >= 20.4)
checkport="yes"
silent_install="no"
silent_upgrade="no"
support_conf_folder="yes"
