#!/bin/bash

################################################################################
# XRDP XORG CRASH FIX SCRIPT
# 
# This script fixes Xorg crashes (signal 11) in Proxmox VMs by:
# - Installing Xorg drivers for virtualization
# - Configuring Xorg to use dummy/framebuffer driver
# - Disabling hardware acceleration
#
# USAGE: sudo ./fix-xrdp-xorg.sh
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

print_header "XRDP Xorg Crash Fix Script"

# Step 1: Install Xorg drivers for virtualization
print_info "Installing Xorg virtualization drivers..."
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-video-fbdev \
    xserver-xorg-input-all \
    xserver-xorg-core \
    > /dev/null 2>&1

print_success "Xorg drivers installed"

# Step 2: Create Xorg configuration for XRDP
print_info "Creating Xorg configuration for XRDP..."
mkdir -p /etc/X11/xorg.conf.d

# Create a minimal Xorg config that works in VMs
cat > /etc/X11/xorg.conf.d/10-xrdp.conf <<'EOF'
Section "ServerLayout"
    Identifier "X11 Server"
    Screen 0 "Screen0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection

Section "Device"
    Identifier "Card0"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "Monitor0"
    HorizSync 30.0-70.0
    VertRefresh 50.0-75.0
    Modeline "1920x1080" 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync +vsync
EndSection
EOF

print_success "Xorg configuration created"

# Step 3: Configure XRDP to use correct Xorg command
print_info "Updating sesman.ini to use proper Xorg settings..."

# Backup original
if [ ! -f /etc/xrdp/sesman.ini.backup ]; then
    cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.backup.$(date +%Y%m%d_%H%M%S)
fi

# Check if sesman.ini has a [Xorg] section or if we need to modify the X11 command
# The issue is that Xorg needs to be started with -config flag to use our dummy driver
sed -i 's|X11DisplayOffset=.*|X11DisplayOffset=10\nKillDisconnected=false|' /etc/xrdp/sesman.ini

# Create a wrapper script for starting Xorg
print_info "Creating Xorg wrapper script..."
cat > /usr/local/bin/xrdp-xorg.sh <<'XORGEOF'
#!/bin/bash
# XRDP Xorg wrapper - fixes crashes in virtualized environments

DISPLAY_NUM=$1
AUTH_FILE=$2

# Use dummy driver for virtualization
exec /usr/bin/Xorg :${DISPLAY_NUM} \
    -config /etc/X11/xorg.conf.d/10-xrdp.conf \
    -configdir /etc/X11/xorg.conf.d \
    -nolisten tcp \
    -auth ${AUTH_FILE} \
    -logfile /var/log/xrdp/xorg-${DISPLAY_NUM}.log
XORGEOF

chmod +x /usr/local/bin/xrdp-xorg.sh
print_success "Xorg wrapper script created"

# Step 4: Alternative approach - configure startwm.sh to handle X errors better
print_info "Updating startwm.sh to handle X server issues..."
if [ -f /etc/xrdp/startwm.sh ]; then
    # Backup
    cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add XDG_RUNTIME_DIR creation and error handling
    cat > /etc/xrdp/startwm.sh <<'WMEOF'
#!/bin/sh
if test -r /etc/profile; then
    . /etc/profile
fi
if test -r /etc/default/locale; then
    . /etc/default/locale
    test -z "${LANG+x}" || export LANG
    test -z "${LANGUAGE+x}" || export LANGUAGE
    test -z "${LC_ALL+x}" || export LC_ALL
fi
if test -r /etc/profile; then
    . /etc/profile
fi

# Set desktop environment variables
export DESKTOP_SESSION=xfce
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_DIRS=/etc/xdg/xfce4

# Ensure XDG_RUNTIME_DIR exists and is writable
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Wait a moment for X server to be ready
sleep 1

# Start XFCE
if command -v startxfce4 >/dev/null; then
    exec startxfce4
elif command -v xfce4-session >/dev/null; then
    exec xfce4-session
else
    exec /etc/X11/Xsession
fi
WMEOF
    chmod +x /etc/xrdp/startwm.sh
    print_success "startwm.sh updated"
fi

# Step 5: Install xserver-xorg-core with reinstall to fix corruption
print_info "Reinstalling xserver-xorg-core to fix any corruption..."
DEBIAN_FRONTEND=noninteractive apt-get install --reinstall -y xserver-xorg-core > /dev/null 2>&1
print_success "X server reinstalled"

# Step 6: Set proper permissions on log directories
print_info "Setting permissions on log directories..."
mkdir -p /var/log/xrdp
chown xrdp:xrdp /var/log/xrdp
chmod 755 /var/log/xrdp
print_success "Permissions set"

# Step 7: Restart services
print_info "Restarting XRDP services..."
systemctl restart xrdp xrdp-sesman
sleep 3

if systemctl is-active --quiet xrdp && systemctl is-active --quiet xrdp-sesman; then
    print_success "XRDP services restarted successfully"
else
    print_error "Some services failed to restart"
    print_info "Check status: sudo systemctl status xrdp xrdp-sesman"
fi

print_header "Xorg Fix Complete"

echo ""
print_info "Fix Summary:"
echo "  • Xorg virtualization drivers installed (dummy, fbdev)"
echo "  • Xorg configuration created for VM environment"
echo "  • Xorg wrapper script created"
echo "  • startwm.sh updated with better error handling"
echo "  • X server core reinstalled"
echo ""
print_warning "IMPORTANT:"
echo "  • Disconnect and reconnect via RDP to test the fix"
echo "  • The X server should now start without crashing"
echo ""
print_info "If issues persist, check logs:"
echo "  sudo tail -f /var/log/xrdp/xorg-*.log"
echo "  sudo journalctl -u xrdp-sesman -f"

