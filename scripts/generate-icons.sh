#!/bin/bash
# generate-icons.sh — Download/generate Uptime Kuma icons for SPK packaging
#
# Produces:
#   PACKAGE_ICON.PNG     (64x64, required for DSM 7)
#   PACKAGE_ICON_256.PNG (256x256, required for Package Center)
#
# Dependencies (one of):
#   - ImageMagick (convert command)
#   - librsvg (rsvg-convert command)
#   - sips (macOS built-in)
#
# Usage:
#   ./scripts/generate-icons.sh [output_dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${PROJECT_DIR}/spk/uptime-kuma}"
SVG_SOURCE="${PROJECT_DIR}/icons/uptime-kuma.svg"

# Official Uptime Kuma icon URL from GitHub
ICON_URL="https://raw.githubusercontent.com/louislam/uptime-kuma/master/public/icon.png"

echo "=== Uptime Kuma Icon Generator ==="
echo "Output directory: ${OUTPUT_DIR}"

mkdir -p "${OUTPUT_DIR}"

# Step 1: Try downloading the official icon
TMP_ICON="${OUTPUT_DIR}/.icon-original.png"

download_official_icon() {
    echo "Attempting to download official Uptime Kuma icon..." >&2
    if curl -fsSL --connect-timeout 10 "${ICON_URL}" -o "${TMP_ICON}" 2>/dev/null; then
        echo "  Downloaded official icon." >&2
        return 0
    fi
    echo "  Download failed. Will use SVG source." >&2
    rm -f "${TMP_ICON}"
    return 1
}

# Step 2: Resize with ImageMagick
resize_imagemagick() {
    local src="$1" size="$2" dest="$3"
    if command -v magick >/dev/null 2>&1; then
        magick "${src}" -resize "${size}x${size}" -strip "${dest}"
        return $?
    elif command -v convert >/dev/null 2>&1; then
        convert "${src}" -resize "${size}x${size}" -strip "${dest}"
        return $?
    fi
    return 1
}

# Step 3: Resize with rsvg-convert (SVG only)
resize_rsvg() {
    local src="$1" size="$2" dest="$3"
    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w "${size}" -h "${size}" "${src}" -o "${dest}"
        return $?
    fi
    return 1
}

# Step 4: Resize with sips (macOS)
resize_sips() {
    local src="$1" size="$2" dest="$3"
    if command -v sips >/dev/null 2>&1; then
        cp "${src}" "${dest}"
        sips -z "${size}" "${size}" "${dest}" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Generate icons from a PNG source
generate_from_png() {
    local src="$1"
    echo "Generating icons from PNG source: ${src}"

    for tool in imagemagick sips; do
        case "${tool}" in
            imagemagick)
                if resize_imagemagick "${src}" 64 "${OUTPUT_DIR}/PACKAGE_ICON.PNG" && \
                   resize_imagemagick "${src}" 256 "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"; then
                    echo "  Generated icons with ImageMagick."
                    return 0
                fi
                ;;
            sips)
                if resize_sips "${src}" 64 "${OUTPUT_DIR}/PACKAGE_ICON.PNG" && \
                   resize_sips "${src}" 256 "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"; then
                    echo "  Generated icons with sips."
                    return 0
                fi
                ;;
        esac
    done
    return 1
}

# Generate icons from the SVG source
generate_from_svg() {
    echo "Generating icons from SVG source: ${SVG_SOURCE}"

    if ! [ -f "${SVG_SOURCE}" ]; then
        echo "  ERROR: SVG source not found at ${SVG_SOURCE}"
        return 1
    fi

    # Try rsvg-convert first (best SVG rendering)
    if resize_rsvg "${SVG_SOURCE}" 64 "${OUTPUT_DIR}/PACKAGE_ICON.PNG" && \
       resize_rsvg "${SVG_SOURCE}" 256 "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"; then
        echo "  Generated icons with rsvg-convert."
        return 0
    fi

    # Try ImageMagick (can handle SVG)
    if resize_imagemagick "${SVG_SOURCE}" 64 "${OUTPUT_DIR}/PACKAGE_ICON.PNG" && \
       resize_imagemagick "${SVG_SOURCE}" 256 "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"; then
        echo "  Generated icons with ImageMagick (SVG)."
        return 0
    fi

    return 1
}

# Main flow
main() {
    local tmp_icon=""

    # Try official icon first
    if download_official_icon; then
        if generate_from_png "${TMP_ICON}"; then
            rm -f "${TMP_ICON}"
            echo ""
            echo "Icons generated successfully:"
            ls -la "${OUTPUT_DIR}/PACKAGE_ICON.PNG" "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"
            exit 0
        fi
        rm -f "${TMP_ICON}"
    fi

    # Fall back to SVG source
    if generate_from_svg; then
        echo ""
        echo "Icons generated successfully:"
        ls -la "${OUTPUT_DIR}/PACKAGE_ICON.PNG" "${OUTPUT_DIR}/PACKAGE_ICON_256.PNG"
        exit 0
    fi

    # Nothing worked
    echo ""
    echo "ERROR: Could not generate icons. Install one of:"
    echo "  - ImageMagick:  brew install imagemagick   (macOS)"
    echo "  - librsvg:      brew install librsvg        (macOS)"
    echo "  - On Linux:     apt install imagemagick librsvg2-bin"
    echo ""
    echo "Or manually create:"
    echo "  ${OUTPUT_DIR}/PACKAGE_ICON.PNG     (64x64 PNG)"
    echo "  ${OUTPUT_DIR}/PACKAGE_ICON_256.PNG (256x256 PNG)"
    exit 1
}

main
