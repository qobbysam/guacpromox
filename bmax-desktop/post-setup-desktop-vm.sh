#!/bin/bash

################################################################################
# POST-SETUP DESKTOP VM SCRIPT
# 
# This script completes the desktop VM setup after the initial setup-desktop-vm.sh
# has been run. It installs Chrome scripts and creates the desktop shortcut.
#
# USAGE: ./post-setup-desktop-vm.sh
#
# REQUIREMENTS:
# - setup-desktop-vm.sh must be run first
# - Scripts must be in the current directory:
#   - launch-chrome.sh
#   - cleanup-chrome-sessions.sh
#   - setup-chrome-master.sh
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CHROME_LAUNCHER="/usr/local/bin/launch-chrome.sh"
CLEANUP_SCRIPT="/usr/local/bin/cleanup-chrome-sessions.sh"
SHARED_USER="shared-desktop"

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header "Desktop VM Post-Setup - Starting"

# Check if running as correct user
CURRENT_USER=$(whoami)
if [[ "$CURRENT_USER" != "$SHARED_USER" ]] && [[ "$CURRENT_USER" != "root" ]]; then
    print_warning "This script should be run as '$SHARED_USER' user or root"
    echo -e "${YELLOW}Current user: $CURRENT_USER${NC}"
    echo ""
    read -p "Continue anyway? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        exit 1
    fi
fi

# Check if required scripts exist
print_info "Checking for required scripts..."

REQUIRED_SCRIPTS=("launch-chrome.sh" "cleanup-chrome-sessions.sh" "setup-chrome-master.sh")
MISSING_SCRIPTS=()

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        MISSING_SCRIPTS+=("$script")
        print_error "Required script not found: $script"
    else
        print_success "Found: $script"
    fi
done

if [[ ${#MISSING_SCRIPTS[@]} -gt 0 ]]; then
    print_error "Missing required scripts. Please ensure all scripts are in the current directory."
    exit 1
fi

# Section 2.3: Install Chrome Scripts
print_header "Installing Chrome Scripts"

# Install launch script
print_info "Installing launch-chrome.sh..."
if [[ "$CURRENT_USER" == "root" ]]; then
    cp launch-chrome.sh "$CHROME_LAUNCHER"
    chmod +x "$CHROME_LAUNCHER"
    chown "$SHARED_USER":"$SHARED_USER" "$CHROME_LAUNCHER"
else
    sudo cp launch-chrome.sh "$CHROME_LAUNCHER"
    sudo chmod +x "$CHROME_LAUNCHER"
    sudo chown "$SHARED_USER":"$SHARED_USER" "$CHROME_LAUNCHER"
fi

if [[ -f "$CHROME_LAUNCHER" ]] && [[ -x "$CHROME_LAUNCHER" ]]; then
    print_success "Launch script installed: $CHROME_LAUNCHER"
else
    print_error "Failed to install launch script"
    exit 1
fi

# Install cleanup script
print_info "Installing cleanup-chrome-sessions.sh..."
if [[ "$CURRENT_USER" == "root" ]]; then
    cp cleanup-chrome-sessions.sh "$CLEANUP_SCRIPT"
    chmod +x "$CLEANUP_SCRIPT"
    chown "$SHARED_USER":"$SHARED_USER" "$CLEANUP_SCRIPT"
else
    sudo cp cleanup-chrome-sessions.sh "$CLEANUP_SCRIPT"
    sudo chmod +x "$CLEANUP_SCRIPT"
    sudo chown "$SHARED_USER":"$SHARED_USER" "$CLEANUP_SCRIPT"
fi

if [[ -f "$CLEANUP_SCRIPT" ]] && [[ -x "$CLEANUP_SCRIPT" ]]; then
    print_success "Cleanup script installed: $CLEANUP_SCRIPT"
else
    print_error "Failed to install cleanup script"
    exit 1
fi

# Copy master profile setup script to home directory
print_info "Copying setup-chrome-master.sh to home directory..."
HOME_DIR="$HOME"
if [[ "$CURRENT_USER" == "root" ]]; then
    HOME_DIR="/home/$SHARED_USER"
fi

cp setup-chrome-master.sh "$HOME_DIR/"
chmod +x "$HOME_DIR/setup-chrome-master.sh"

if [[ "$CURRENT_USER" == "root" ]]; then
    chown "$SHARED_USER":"$SHARED_USER" "$HOME_DIR/setup-chrome-master.sh"
fi

print_success "Master profile setup script copied to: $HOME_DIR/setup-chrome-master.sh"

# Section 2.4: Create Chrome Desktop Shortcut
print_header "Creating Chrome Desktop Shortcut"

DESKTOP_DIR="$HOME_DIR/Desktop"
if [[ "$CURRENT_USER" == "root" ]]; then
    DESKTOP_DIR="/home/$SHARED_USER/Desktop"
fi

# Ensure Desktop directory exists
if [[ ! -d "$DESKTOP_DIR" ]]; then
    print_info "Creating Desktop directory..."
    if [[ "$CURRENT_USER" == "root" ]]; then
        mkdir -p "$DESKTOP_DIR"
        chown "$SHARED_USER":"$SHARED_USER" "$DESKTOP_DIR"
    else
        mkdir -p "$DESKTOP_DIR"
    fi
fi

# Create desktop shortcut
print_info "Creating Chrome desktop shortcut..."
SHORTCUT_FILE="$DESKTOP_DIR/Chrome-Shared.desktop"

cat > "$SHORTCUT_FILE" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome (Shared Config)
Comment=Launch Chrome with shared configuration
Exec=/usr/local/bin/launch-chrome.sh
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF

# Set permissions
chmod +x "$SHORTCUT_FILE"
if [[ "$CURRENT_USER" == "root" ]]; then
    chown "$SHARED_USER":"$SHARED_USER" "$SHORTCUT_FILE"
fi

# Trust the desktop file
if command -v gio &> /dev/null; then
    if [[ "$CURRENT_USER" == "root" ]]; then
        sudo -u "$SHARED_USER" gio set "$SHORTCUT_FILE" metadata::trusted true 2>/dev/null || true
    else
        gio set "$SHORTCUT_FILE" metadata::trusted true 2>/dev/null || true
    fi
fi

if [[ -f "$SHORTCUT_FILE" ]] && [[ -x "$SHORTCUT_FILE" ]]; then
    print_success "Desktop shortcut created: $SHORTCUT_FILE"
else
    print_warning "Desktop shortcut created but may need manual trust: $SHORTCUT_FILE"
fi

print_header "Post-Setup Complete"

echo ""
print_info "Setup Summary:"
echo "  • Chrome launcher installed: $CHROME_LAUNCHER"
echo "  • Cleanup script installed: $CLEANUP_SCRIPT"
echo "  • Master profile setup script: $HOME_DIR/setup-chrome-master.sh"
echo "  • Desktop shortcut created: $SHORTCUT_FILE"
echo ""
print_warning "NEXT STEPS:"
echo "  1. Run setup-chrome-master.sh as $SHARED_USER to configure master profile"
echo "  2. Test XRDP connection from another machine"
echo "  3. Verify Chrome launches correctly from desktop shortcut"
echo ""

# If running as root, provide instructions
if [[ "$CURRENT_USER" == "root" ]]; then
    echo ""
    print_info "Since you ran this as root, switch to $SHARED_USER to continue:"
    echo "  su - $SHARED_USER"
    echo "  cd ~"
    echo "  ./setup-chrome-master.sh"
    echo ""
fi

print_success "Post-setup complete!"
