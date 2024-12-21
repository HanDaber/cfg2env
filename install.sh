#!/bin/sh

set -e  # Exit on error

# Configuration
BINARY="cfg2env"
VERSION="latest"
GITHUB_REPO="handaber/cfg2env"
# Default to user's local bin if XDG_BIN_HOME or HOME is set, fallback to /usr/local/bin
INSTALL_DIR="${XDG_BIN_HOME:-${HOME}/.local/bin}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
LOCAL_INSTALL=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print step
step() {
    printf "${BLUE}==> ${NC}$1\n"
}

# Print error and exit
error() {
    printf "${RED}Error: ${NC}$1\n" >&2
    exit 1
}

# Print success
success() {
    printf "${GREEN}==>${NC} $1\n"
}

# Parse arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --local)
                LOCAL_INSTALL=true
                shift
                ;;
            --help)
                printf "Usage: $0 [--local] [--help]\n"
                printf "\nOptions:\n"
                printf "  --local    Install from local source code instead of downloading release\n"
                printf "  --help     Show this help message\n"
                printf "\nEnvironment variables:\n"
                printf "  INSTALL_DIR    Installation directory (default: \$XDG_BIN_HOME or \$HOME/.local/bin)\n"
                printf "  VERSION        Version to install (default: latest)\n"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) error "Unsupported architecture: $ARCH" ;;
    esac
    
    case "$OS" in
        linux|darwin) ;;
        *) error "Unsupported operating system: $OS" ;;
    esac
}

# Check for required tools
check_dependencies() {
    step "Checking dependencies..."
    
    if [ "$LOCAL_INSTALL" = true ]; then
        for cmd in go make; do
            if ! command -v $cmd >/dev/null 2>&1; then
                error "$cmd is required but not installed"
            fi
        done
    else
        for cmd in curl tar; do
            if ! command -v $cmd >/dev/null 2>&1; then
                error "$cmd is required but not installed"
            fi
        done
    fi
}

# Ensure installation directory exists
setup_install_dir() {
    step "Setting up installation directory..."
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" || error "Failed to create installation directory: $INSTALL_DIR"
    fi
    
    # Check if directory is writable
    if [ ! -w "$INSTALL_DIR" ]; then
        error "Installation directory is not writable: $INSTALL_DIR\nPlease set INSTALL_DIR to a writable location."
    fi
    
    # Add to PATH if not already in it
    case ":$PATH:" in
        *":$INSTALL_DIR:"*) ;;
        *)
            SHELL_NAME=$(basename "$SHELL")
            SHELL_PROFILE=""
            case "$SHELL_NAME" in
                bash) SHELL_PROFILE="$HOME/.bashrc" ;;
                zsh) SHELL_PROFILE="$HOME/.zshrc" ;;
                fish) SHELL_PROFILE="$HOME/.config/fish/config.fish" ;;
            esac
            
            if [ -n "$SHELL_PROFILE" ]; then
                printf "\nNote: You may want to add the following line to your $SHELL_PROFILE:\n"
                printf "  export PATH=\"\$PATH:$INSTALL_DIR\"\n\n"
            fi
            ;;
    esac
}

# Create temporary directory
setup_tmp() {
    step "Creating temporary directory..."
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
}

# Build from source
build_local() {
    step "Building from source..."
    
    # Check if we're in the project directory
    if [ ! -f "go.mod" ] || ! grep -q "module.*$BINARY" "go.mod"; then
        error "Not in the $BINARY project directory. Please run this script from the project root."
    fi
    
    # Build the binary
    step "Running make build..."
    if ! make build; then
        error "Failed to build $BINARY"
    fi
    
    # Check if binary was built
    if [ ! -f "bin/$BINARY" ]; then
        error "Binary not found after build"
    fi
    
    # Install binary
    step "Installing to $INSTALL_DIR..."
    cp "bin/$BINARY" "$INSTALL_DIR/" || error "Failed to copy binary to $INSTALL_DIR"
    chmod +x "$INSTALL_DIR/$BINARY" || error "Failed to make binary executable"
}

# Download and install binary
install_binary() {
    step "Installing $BINARY..."
    
    # Download URL
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/${BINARY}_${VERSION}_${OS}_${ARCH}.tar.gz"
    
    # Download and extract
    step "Downloading from $DOWNLOAD_URL..."
    if ! curl -sL "$DOWNLOAD_URL" | tar xz -C "$TMP_DIR"; then
        error "Failed to download and extract $BINARY"
    fi
    
    # Install binary
    step "Installing to $INSTALL_DIR..."
    mv "$TMP_DIR/$BINARY" "$INSTALL_DIR/" || error "Failed to move binary to $INSTALL_DIR"
    chmod +x "$INSTALL_DIR/$BINARY" || error "Failed to make binary executable"
}

# Verify installation
verify_installation() {
    step "Verifying installation..."
    if [ -x "$INSTALL_DIR/$BINARY" ]; then
        success "$BINARY has been installed to $INSTALL_DIR/$BINARY"
        if ! command -v $BINARY >/dev/null 2>&1; then
            printf "\nNote: Installation directory is not in PATH. You can either:\n"
            printf "1. Add it to your PATH:\n"
            printf "   export PATH=\"\$PATH:$INSTALL_DIR\"\n"
            printf "2. Or run it directly:\n"
            printf "   $INSTALL_DIR/$BINARY --help\n\n"
        else
            printf "\nTo get started, run:\n"
            printf "  $BINARY --help\n\n"
        fi
    else
        error "Installation failed"
    fi
}

main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Header
    printf "${GREEN}Installing ${BINARY}...${NC}\n\n"
    
    # Run installation steps
    check_dependencies
    setup_install_dir
    if [ "$LOCAL_INSTALL" = true ]; then
        build_local
    else
        detect_platform
        setup_tmp
        install_binary
    fi
    verify_installation
}

main "$@" 