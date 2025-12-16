#!/bin/sh

set -e  # Exit on error

# Configuration
BINARY="cfg2env"
VERSION="${VERSION:-latest}"
GITHUB_REPO="HanDaber/cfg2env"
INSTALL_DIR="${INSTALL_DIR:-${XDG_BIN_HOME:-${HOME}/.local/bin}}"
VERIFY_CHECKSUM="${VERIFY_CHECKSUM:-1}"
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
                printf "  INSTALL_DIR       Installation directory (default: \$XDG_BIN_HOME or \$HOME/.local/bin)\n"
                printf "  VERSION           Version to install (default: latest, format: v0.1.0 or 0.1.0)\n"
                printf "  VERIFY_CHECKSUM   Verify checksums (default: 1, set to 0 to skip)\n"
                printf "\nExamples:\n"
                printf "  # Install latest version\n"
                printf "  curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | sh\n"
                printf "\n  # Install specific version\n"
                printf "  curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | VERSION=v0.1.0 sh\n"
                printf "\n  # Install without checksum verification (not recommended)\n"
                printf "  curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | VERIFY_CHECKSUM=0 sh\n"
                printf "\n  # Build from local source\n"
                printf "  ./install.sh --local\n"
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
        
        # Check for checksum tool if verification is enabled
        if [ "$VERIFY_CHECKSUM" = "1" ]; then
            if command -v sha256sum >/dev/null 2>&1; then
                CHECKSUM_CMD="sha256sum"
            elif command -v shasum >/dev/null 2>&1; then
                CHECKSUM_CMD="shasum -a 256"
            else
                error "Checksum verification enabled but neither sha256sum nor shasum found. Install one or set VERIFY_CHECKSUM=0"
            fi
        fi
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

# Normalize version format (add 'v' prefix if missing)
normalize_version() {
    if [ "$VERSION" = "latest" ]; then
        step "Fetching latest release version..."
        VERSION=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            error "Failed to fetch latest version"
        fi
        step "Latest version: $VERSION"
    else
        # Ensure version has 'v' prefix
        case "$VERSION" in
            v*) ;;
            *) VERSION="v$VERSION" ;;
        esac
    fi
}

# Verify checksum
verify_checksum() {
    if [ "$VERIFY_CHECKSUM" != "1" ]; then
        printf "${BLUE}Note: ${NC}Checksum verification skipped (VERIFY_CHECKSUM=0)\n"
        return 0
    fi
    
    step "Verifying checksum..."
    
    CHECKSUM_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/${BINARY}_${VERSION#v}_checksums.txt"
    CHECKSUM_FILE="$TMP_DIR/checksums.txt"
    ARCHIVE_NAME="${BINARY}_${VERSION#v}_${OS}_${ARCH}.tar.gz"
    
    # Download checksums file
    if ! curl -fsSL "$CHECKSUM_URL" -o "$CHECKSUM_FILE"; then
        error "Failed to download checksums file from $CHECKSUM_URL"
    fi
    
    # Extract expected checksum for our archive
    EXPECTED_CHECKSUM=$(grep "$ARCHIVE_NAME" "$CHECKSUM_FILE" | awk '{print $1}')
    if [ -z "$EXPECTED_CHECKSUM" ]; then
        error "Checksum for $ARCHIVE_NAME not found in checksums file"
    fi
    
    # Calculate actual checksum
    cd "$TMP_DIR"
    ACTUAL_CHECKSUM=$($CHECKSUM_CMD "$ARCHIVE_NAME" | awk '{print $1}')
    
    # Compare checksums
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        error "Checksum verification failed!\nExpected: $EXPECTED_CHECKSUM\nActual:   $ACTUAL_CHECKSUM"
    fi
    
    success "Checksum verified"
}

# Download and install binary
install_binary() {
    step "Installing $BINARY..."
    
    # Normalize version format
    normalize_version
    
    # Build download URL (note: version in URL doesn't have 'v' prefix)
    ARCHIVE_NAME="${BINARY}_${VERSION#v}_${OS}_${ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/$ARCHIVE_NAME"
    
    # Download archive
    step "Downloading from $DOWNLOAD_URL..."
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$ARCHIVE_NAME"; then
        error "Failed to download $BINARY from $DOWNLOAD_URL"
    fi
    
    # Verify checksum
    verify_checksum
    
    # Extract archive
    step "Extracting archive..."
    if ! tar xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"; then
        error "Failed to extract archive"
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