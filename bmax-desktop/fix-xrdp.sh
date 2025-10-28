#!/bin/bash

################################################################################
# XRDP FIX SCRIPT
# 
# This script fixes common xrdp startup issues by creating required directories
# and setting proper permissions.
#
# USAGE: sudo ./fix-xrdp.sh
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "XRDP Fix Script"

# Create required directories
print_info "Creating required directories..."
mkdir -p /var/log/xrdp
mkdir -p /run/xrdp

# Set proper permissions
print_info "Setting permissions..."
chown xrdp:xrdp /var/log/xrdp 2>/dev/null || chown root:root /var/log/xrdp
chown xrdp:xrdp /run/xrdp 2>/dev/null || chown root:root /run/xrdp
chmod 755 /var/log/xrdp
chmod 755 /run/xrdp

print_success "Directories created and permissions set"

# Verify xrdp user exists
if id "xrdp" &>/dev/null; then
    print_success "xrdp user exists"
else
    print_error "xrdp user does not exist - xrdp package may not be installed correctly"
fi

# Try to start xrdp
print_info "Starting xrdp service..."
systemctl daemon-reload
systemctl restart xrdp

sleep 2

# Check status
if systemctl is-active --quiet xrdp; then
    print_success "XRDP is now running!"
    echo ""
    print_info "Check status with: sudo systemctl status xrdp"
    print_info "View logs with: sudo journalctl -u xrdp -f"
else
    print_error "XRDP failed to start"
    echo ""
    print_info "Check logs with: sudo journalctl -u xrdp -n 50"
    exit 1
fi

print_header "Fix Complete"

