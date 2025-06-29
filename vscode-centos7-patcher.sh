#!/bin/bash

# VS Code Remote-SSH CentOS 7.9 Auto-Patcher
# This script automatically patches VS Code Server installations to work with CentOS 7.9
# by using newer glibc and libstdc++ libraries in user space

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$HOME/local"
BIN_DIR="$HOME/bin"
VSCODE_SERVER_DIR="$HOME/.vscode-server"
LOG_FILE="$HOME/vscode-patcher.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

error_nonfatal() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running on CentOS 7
check_centos7() {
    if [[ ! -f /etc/centos-release ]]; then
        error "This script is designed for CentOS systems only"
    fi
    
    if ! grep -q "CentOS Linux release 7" /etc/centos-release; then
        error "This script is designed for CentOS 7 only"
    fi
    
    log "✓ Running on CentOS 7"
}

# Check current library versions
check_current_libraries() {
    log "Checking current library versions..."
    
    local glibc_version=$(ldd --version | head -1 | grep -o '[0-9]\+\.[0-9]\+')
    local libstdcxx_version=$(strings /usr/lib64/libstdc++.so.6 | grep GLIBCXX | tail -1)
    
    log "Current glibc version: $glibc_version"
    log "Current libstdc++ version: $libstdcxx_version"
    
    # Check if libraries meet VS Code requirements
    if [[ "$glibc_version" < "2.28" ]]; then
        log "✓ glibc upgrade needed (current: $glibc_version, required: 2.28+)"
        return 0
    fi
    
    if [[ "$libstdcxx_version" < "GLIBCXX_3.4.21" ]]; then
        log "✓ libstdc++ upgrade needed (current: $libstdcxx_version, required: GLIBCXX_3.4.21+)"
        return 0
    fi
    
    log "Libraries appear sufficient, but continuing with setup for compatibility"
}

# Setup local directory structure
setup_directories() {
    log "Setting up directory structure..."
    mkdir -p "$LOCAL_DIR" "$BIN_DIR"
    cd "$LOCAL_DIR"
    log "✓ Directories created: $LOCAL_DIR, $BIN_DIR"
}

# Download required packages
download_packages() {
    log "Downloading required packages..."
    
    local glibc_url="https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/Packages/glibc-2.28-251.el8_10.13.x86_64.rpm"
    local libstdcxx_url="https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/Packages/libstdc%2B%2B-8.5.0-23.el8_10.alma.1.x86_64.rpm"
    local patchelf_url="https://github.com/NixOS/patchelf/releases/download/0.15.0/patchelf-0.15.0-x86_64.tar.gz"
    
    # Download glibc if not exists
    if [[ ! -f glibc-2.28-251.el8_10.13.x86_64.rpm ]]; then
        log "Downloading glibc..."
        wget -q "$glibc_url" || error "Failed to download glibc"
        success "✓ glibc downloaded"
    else
        log "✓ glibc already exists"
    fi
    
    # Download libstdc++ if not exists
    if [[ ! -f libstdc++-8.5.0-23.el8_10.alma.1.x86_64.rpm ]]; then
        log "Downloading libstdc++..."
        wget -q "$libstdcxx_url" || error "Failed to download libstdc++"
        success "✓ libstdc++ downloaded"
    else
        log "✓ libstdc++ already exists"
    fi
    
    # Download patchelf if not exists
    if [[ ! -f "$BIN_DIR/patchelf" ]]; then
        log "Downloading patchelf..."
        wget -q "$patchelf_url" -O patchelf.tar.gz || error "Failed to download patchelf"
        tar -xzf patchelf.tar.gz
        cp bin/patchelf "$BIN_DIR/"
        chmod +x "$BIN_DIR/patchelf"
        rm -f patchelf.tar.gz
        success "✓ patchelf installed to $BIN_DIR/patchelf"
    else
        log "✓ patchelf already exists"
    fi
}

# Extract packages
extract_packages() {
    log "Extracting packages..."
    
    # Check if already extracted
    if [[ -d usr/lib64 ]]; then
        log "✓ Packages already extracted"
        return 0
    fi
    
    # Extract glibc
    log "Extracting glibc..."
    rpm2cpio glibc-2.28-251.el8_10.13.x86_64.rpm | cpio -idmv >/dev/null 2>&1 || error "Failed to extract glibc"
    
    # Extract libstdc++
    log "Extracting libstdc++..."
    rpm2cpio libstdc++-8.5.0-23.el8_10.alma.1.x86_64.rpm | cpio -idmv >/dev/null 2>&1 || error "Failed to extract libstdc++"
    
    success "✓ Packages extracted"
}

# Setup environment variables (NOT setting LD_LIBRARY_PATH globally)
setup_environment() {
    log "Setting up environment variables..."
    
    # Remove any existing problematic LD_LIBRARY_PATH entries from bashrc
    if grep -q "LD_LIBRARY_PATH.*$LOCAL_DIR" "$HOME/.bashrc" 2>/dev/null; then
        log "Removing problematic LD_LIBRARY_PATH from .bashrc..."
        sed -i "/LD_LIBRARY_PATH.*$(echo "$LOCAL_DIR" | sed 's/[[\.*^$()+?{|/]/\\&/g')/d" "$HOME/.bashrc"
    fi
    
    # Unset any current LD_LIBRARY_PATH that might cause issues
    if [[ "$LD_LIBRARY_PATH" == *"$LOCAL_DIR"* ]]; then
        log "Unsetting problematic LD_LIBRARY_PATH for current session..."
        unset LD_LIBRARY_PATH
    fi
    
    # NOTE: We DON'T set LD_LIBRARY_PATH globally as it breaks system commands
    # Instead, we rely purely on patchelf to set the interpreter and rpath
    
    log "✓ Environment setup complete (using patchelf only, no global LD_LIBRARY_PATH)"
}

# Find all VS Code server installations
find_vscode_servers() {
    if [[ ! -d "$VSCODE_SERVER_DIR/bin" ]]; then
        log "No VS Code server installations found"
        return 1
    fi
    
    find "$VSCODE_SERVER_DIR/bin" -maxdepth 1 -type d -name "*" | grep -v "^$VSCODE_SERVER_DIR/bin$" | sort
}

# Check if a node binary needs patching
needs_patching() {
    local node_binary="$1"
    
    if [[ ! -f "$node_binary" ]]; then
        return 1
    fi
    
    # Check current interpreter
    local current_interpreter=$("$BIN_DIR/patchelf" --print-interpreter "$node_binary" 2>/dev/null || echo "")
    local expected_interpreter="$LOCAL_DIR/usr/lib64/ld-linux-x86-64.so.2"
    
    if [[ "$current_interpreter" == "$expected_interpreter" ]]; then
        return 1  # Already patched
    fi
    
    return 0  # Needs patching
}

# Patch a single VS Code server installation
# Returns: 0=newly patched, 1=already patched, 2=error
patch_vscode_server() {
    local server_dir="$1"
    local commit_hash=$(basename "$server_dir")
    
    log "Checking VS Code server: $commit_hash"
    
    local node_binary="$server_dir/node"
    
    if [[ ! -f "$node_binary" ]]; then
        warning "No node binary found in $server_dir"
        return 2
    fi
    
    if ! needs_patching "$node_binary"; then
        log "✓ $commit_hash already patched"
        return 1  # Already patched
    fi
    
    log "Patching VS Code server: $commit_hash"
    
    # Create backup if it doesn't exist
    if [[ ! -f "$node_binary.backup" ]]; then
        cp "$node_binary" "$node_binary.backup"
        log "✓ Created backup: $node_binary.backup"
    fi
    
    # Patch the binary
    "$BIN_DIR/patchelf" \
        --set-interpreter "$LOCAL_DIR/usr/lib64/ld-linux-x86-64.so.2" \
        --set-rpath "$LOCAL_DIR/usr/lib64" \
        "$node_binary" || {
            error_nonfatal "Failed to patch $node_binary"
            return 2
        }
    
    # Test the patched binary
    if "$node_binary" --version >/dev/null 2>&1; then
        success "✓ Successfully patched and tested $commit_hash"
        
        # Get Node.js version (run without global LD_LIBRARY_PATH to avoid conflicts)
        local node_version=$("$node_binary" --version 2>/dev/null || echo "version check failed")
        log "  Node.js version: $node_version"
        return 0  # Newly patched
    else
        error_nonfatal "Patched binary failed to run for $commit_hash"
        return 2  # Error
    fi
}

# Patch all VS Code server installations
patch_all_servers() {
    set +e  # Disable set -e for this function to handle errors gracefully
    
    log "Scanning for VS Code server installations..."
    
    local servers=($(find_vscode_servers))
    
    if [[ ${#servers[@]} -eq 0 ]]; then
        warning "No VS Code server installations found in $VSCODE_SERVER_DIR/bin"
        log "Try connecting with VS Code Remote-SSH first to install the server"
        set -e  # Re-enable before returning
        return 1
    fi
    
    log "Found ${#servers[@]} VS Code server installation(s)"
    
    local patched_count=0
    local already_patched=0
    local error_count=0
    
    for server_dir in "${servers[@]}"; do
        patch_vscode_server "$server_dir"
        local result=$?
        
        case $result in
            0) ((patched_count++)) ;;       # Newly patched
            1) ((already_patched++)) ;;     # Already patched
            2) ((error_count++)) ;;         # Error
        esac
    done
    
    log "Summary:"
    log "  - Newly patched: $patched_count"
    log "  - Already patched: $already_patched"
    log "  - Errors: $error_count"
    log "  - Total servers: ${#servers[@]}"
    
    set -e  # Re-enable set -e before returning
    
    # Return success (0) if we processed all servers without errors
    # Only return failure if there were actual errors or no servers found
    if [[ $error_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Verify library versions
verify_libraries() {
    log "Verifying extracted library versions..."
    
    # Check glibc version
    if [[ -f "$LOCAL_DIR/usr/lib64/ld-linux-x86-64.so.2" ]]; then
        local glibc_version=$("$LOCAL_DIR/usr/lib64/ld-linux-x86-64.so.2" --version | head -1)
        log "✓ Extracted glibc: $glibc_version"
    else
        error "glibc not found in extracted libraries"
    fi
    
    # Check libstdc++ version
    if [[ -f "$LOCAL_DIR/usr/lib64/libstdc++.so.6.0.25" ]]; then
        local libstdcxx_versions=$(strings "$LOCAL_DIR/usr/lib64/libstdc++.so.6.0.25" | grep GLIBCXX | tail -3)
        log "✓ Extracted libstdc++ versions:"
        echo "$libstdcxx_versions" | while read line; do
            log "    $line"
        done
    else
        error "libstdc++ not found in extracted libraries"
    fi
}

# Monitor for new VS Code server installations
monitor_mode() {
    log "Starting monitor mode - watching for new VS Code server installations..."
    log "Press Ctrl+C to stop monitoring"
    
    local last_count=0
    
    while true; do
        local servers=($(find_vscode_servers 2>/dev/null || echo ""))
        local current_count=${#servers[@]}
        
        if [[ $current_count -gt $last_count ]]; then
            log "Detected new VS Code server installation(s)!"
            patch_all_servers
            last_count=$current_count
        fi
        
        sleep 10
    done
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    cd "$HOME"
    # Add any cleanup operations here if needed
}

# Show usage information
show_usage() {
    echo "VS Code Remote-SSH CentOS 7.9 Auto-Patcher"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -s, --setup     Initial setup (download libraries, setup environment)"
    echo "  -p, --patch     Patch existing VS Code server installations"
    echo "  -a, --auto      Full automatic setup and patching"
    echo "  -m, --monitor   Monitor mode - watch for new installations"
    echo "  -v, --verify    Verify library versions and installation"
    echo "  -c, --check     Check current system libraries"
    echo ""
    echo "Examples:"
    echo "  $0 --auto       # Full automatic setup and patching"
    echo "  $0 --patch      # Only patch existing installations"
    echo "  $0 --monitor    # Watch for new VS Code server installations"
    echo ""
}

# Main function
main() {
    log "=== VS Code Remote-SSH CentOS 7.9 Auto-Patcher ==="
    log "Log file: $LOG_FILE"
    
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--setup)
            check_centos7
            setup_directories
            download_packages
            extract_packages
            setup_environment
            verify_libraries
            success "Setup complete! Now run with --patch to patch VS Code servers"
            ;;
        -p|--patch)
            if [[ ! -f "$BIN_DIR/patchelf" ]]; then
                error "patchelf not found. Run with --setup first"
            fi
            set +e  # Temporarily disable set -e for patching
            patch_all_servers
            local result=$?
            set -e  # Re-enable set -e
            if [[ $result -eq 0 ]]; then
                success "Patching complete!"
            else
                warning "Patching completed with some errors. Check the log for details."
            fi
            ;;
        -a|--auto)
            check_centos7
            check_current_libraries
            setup_directories
            download_packages
            extract_packages
            setup_environment
            verify_libraries
            patch_all_servers
            success "Auto-patching complete!"
            ;;
        -m|--monitor)
            if [[ ! -f "$BIN_DIR/patchelf" ]]; then
                error "patchelf not found. Run with --setup first"
            fi
            monitor_mode
            ;;
        -v|--verify)
            verify_libraries
            patch_all_servers
            ;;
        -c|--check)
            check_centos7
            check_current_libraries
            ;;
        "")
            warning "No option specified. Use --help for usage information"
            show_usage
            exit 1
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information"
            ;;
    esac
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "$@"
