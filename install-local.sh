#!/bin/bash

# install-local.sh - Install the local ollama-symlinks build
# Usage: ./install-local.sh [--dry-run] [--no-build]

set -e

BINARY_NAME="ollama-symlinks"
INSTALL_DIR="/usr/local/bin"
BUILD_SCRIPT="./build.sh"
SOURCE_BINARY="./${BINARY_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Main installation logic
install() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local BUILD_PATH="${SCRIPT_DIR}/${BUILD_SCRIPT#./}"
    local SOURCE_PATH="${SCRIPT_DIR}/${SOURCE_BINARY#./}"
    local TARGET_PATH="${INSTALL_DIR}/${BINARY_NAME}"

    log_info "Local source binary: ${SOURCE_PATH}"
    log_info "Install target: ${TARGET_PATH}"

    if [ "$DRY_RUN" = "true" ]; then
        if [ "$NO_BUILD" != "true" ]; then
            log_info "DRY RUN: Would build local binary using ${BUILD_PATH}"
        fi
        log_info "DRY RUN: Would install ${SOURCE_PATH} to ${TARGET_PATH}"
        return 0
    fi

    if [ "$NO_BUILD" != "true" ]; then
        if [ ! -x "$BUILD_PATH" ]; then
            log_error "Build script not found or not executable: ${BUILD_PATH}"
            exit 1
        fi
        log_info "Building local binary..."
        (cd "$SCRIPT_DIR" && "$BUILD_PATH")
    fi

    if [ ! -f "$SOURCE_PATH" ]; then
        log_error "Local binary not found: ${SOURCE_PATH}"
        log_error "Run ./build.sh first, or run this installer without --no-build."
        exit 1
    fi

    chmod +x "$SOURCE_PATH"

    log_info "Installing to ${INSTALL_DIR} (may require sudo)..."
    if [ -w "$INSTALL_DIR" ]; then
        cp "$SOURCE_PATH" "$TARGET_PATH"
    else
        sudo cp "$SOURCE_PATH" "$TARGET_PATH"
    fi

    log_success "${BINARY_NAME} installed successfully to ${INSTALL_DIR}"

    # Check if INSTALL_DIR is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "${INSTALL_DIR} is not in your PATH. You may need to add it to your shell profile."
    fi

    log_info "If the command is not found, run 'rehash' (zsh) or 'hash -r' (bash) to refresh your shell."
    log_info "You can now run it using: ${BINARY_NAME} --help"
}

# Check for flags
DRY_RUN=false
NO_BUILD=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --no-build) NO_BUILD=true ;;
        *) log_error "Unknown argument: $arg"; exit 1 ;;
    esac
done

# Execute unless skipped (for testing)
if [ -z "$SKIP_INSTALL" ]; then
    install
fi
