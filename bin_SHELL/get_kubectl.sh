#!/bin/bash
# kubectl installation script
# Downloads and installs kubectl for a specified version
# Usage: ./get_kubectl [version]
#   If version is not provided, fetches the latest stable version
#   Version can be specified as: v1.28.0, 1.28.0, or latest

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_version() {
    echo -e "${BLUE}[VERSION]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [version]"
    echo ""
    echo "Options:"
    echo "  version    Kubernetes version to install (e.g., v1.28.0, 1.28.0, or 'latest')"
    echo "             If not provided, fetches the latest stable version"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install latest stable version"
    echo "  $0 latest             # Install latest stable version"
    echo "  $0 v1.28.0            # Install version 1.28.0"
    echo "  $0 1.28.0             # Install version 1.28.0 (v prefix added automatically)"
    exit 1
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case $OS in
    linux)
        OS="linux"
        ;;
    darwin)
        OS="darwin"
        ;;
    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac
print_status "Detected OS: $OS"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
print_status "Detected architecture: $ARCH"

# Get version
VERSION_INPUT="${1:-latest}"

if [[ "$VERSION_INPUT" == "latest" ]] || [[ -z "$1" ]]; then
    print_status "Fetching latest stable kubectl version..."
    VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
    if [ -z "$VERSION" ]; then
        print_error "Failed to fetch latest version"
        exit 1
    fi
    print_version "Latest stable version: $VERSION"
else
    # Normalize version input (add 'v' prefix if missing)
    if [[ ! "$VERSION_INPUT" =~ ^v ]]; then
        VERSION="v${VERSION_INPUT}"
    else
        VERSION="$VERSION_INPUT"
    fi
    print_version "Requested version: $VERSION"
fi

# Verify version exists
print_status "Verifying version exists..."
if ! curl -sL "https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}/kubectl" -o /dev/null -w "%{http_code}" | grep -q "200"; then
    print_error "Version $VERSION not found or not available for ${OS}/${ARCH}"
    print_warning "You can check available versions at: https://github.com/kubernetes/kubernetes/releases"
    exit 1
fi

# Set download URL
DOWNLOAD_URL="https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}/kubectl"
print_status "Download URL: $DOWNLOAD_URL"

# Set installation directory (default to /usr/local/bin, but check if we need sudo)
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Check if we can write to install directory
NEED_SUDO=false
if [ ! -w "$INSTALL_DIR" ]; then
    NEED_SUDO=true
    print_warning "Installation directory $INSTALL_DIR requires sudo privileges"
fi

# Download kubectl
print_status "Downloading kubectl..."
cd "$TEMP_DIR"
if ! curl -sL "$DOWNLOAD_URL" -o kubectl; then
    print_error "Failed to download kubectl"
    exit 1
fi

# Verify download
if [ ! -f "kubectl" ]; then
    print_error "Downloaded file not found"
    exit 1
fi

# Make executable
chmod +x kubectl

# Verify kubectl binary
print_status "Verifying kubectl binary..."
if ! ./kubectl version --client --short 2>/dev/null | head -n 1; then
    print_warning "Could not verify kubectl version, but binary exists"
fi

# Install kubectl
print_status "Installing kubectl to $INSTALL_DIR..."
if [ "$NEED_SUDO" = true ]; then
    if sudo cp kubectl "$INSTALL_DIR/kubectl"; then
        print_status "Successfully installed kubectl to $INSTALL_DIR/kubectl"
    else
        print_error "Failed to install kubectl (sudo required)"
        exit 1
    fi
else
    if cp kubectl "$INSTALL_DIR/kubectl"; then
        print_status "Successfully installed kubectl to $INSTALL_DIR/kubectl"
    else
        print_error "Failed to install kubectl"
        exit 1
    fi
fi

# Verify installation
print_status "Verifying installation..."
if command -v kubectl &> /dev/null; then
    INSTALLED_VERSION=$(kubectl version --client --short 2>/dev/null | head -n 1 || echo "unknown")
    print_status "kubectl is now available in PATH"
    print_version "$INSTALLED_VERSION"
    print_status "Installation complete!"
else
    print_warning "kubectl installed but not found in PATH"
    print_warning "Make sure $INSTALL_DIR is in your PATH"
    exit 1
fi

