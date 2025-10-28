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
touch /var/log/xrdp/xrdp.log
chown xrdp:xrdp /var/log/xrdp/xrdp.log 2>/dev/null || chown root:root /var/log/xrdp/xrdp.log
chmod 644 /var/log/xrdp/xrdp.log

print_success "Directories created and permissions set"

# Fix xrdp.ini logging configuration
print_info "Checking xrdp.ini configuration..."
if [ -f /etc/xrdp/xrdp.ini ]; then
    if ! grep -q "^\[Logging\]" /etc/xrdp/xrdp.ini; then
        print_info "Adding Logging section to xrdp.ini..."
        # Backup original
        cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup.$(date +%Y%m%d_%H%M%S)
        
        # Add logging section before [Xorg] section using awk
        awk '/^\[Xorg\]/ {print "[Logging]"; print "LogFile=/var/log/xrdp/xrdp.log"; print "LogLevel=INFO"; print "EnableSyslog=true"; print "SyslogLevel=INFO"; print ""}1' /etc/xrdp/xrdp.ini > /tmp/xrdp.ini.new && mv /tmp/xrdp.ini.new /etc/xrdp/xrdp.ini
        print_success "Logging configuration added"
    else
        print_info "Logging section already exists in xrdp.ini"
        
        # Ensure log file path is correct
        if grep -q "^LogFile=" /etc/xrdp/xrdp.ini; then
            sed -i 's|^LogFile=.*|LogFile=/var/log/xrdp/xrdp.log|' /etc/xrdp/xrdp.ini
            print_info "Updated log file path"
        fi
    fi
else
    print_error "xrdp.ini not found at /etc/xrdp/xrdp.ini"
fi

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

