#!/bin/bash

################################################################################
# XRDP DESKTOP FIX SCRIPT
# 
# This script fixes the "no desktop" issue after XRDP login by installing
# XFCE4 desktop environment and configuring startwm.sh properly.
#
# USAGE: sudo ./fix-xrdp-desktop.sh
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

print_header "XRDP Desktop Fix Script"

# Step 1: Install desktop environment (XFCE4 works best with XRDP)
print_info "Installing XFCE4 desktop environment..."
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    > /dev/null 2>&1

if dpkg -l | grep -q xfce4; then
    print_success "XFCE4 installed"
else
    print_error "XFCE4 installation may have failed"
fi

# Step 2: Configure startwm.sh
print_info "Configuring /etc/xrdp/startwm.sh..."

# Backup original
if [ ! -f /etc/xrdp/startwm.sh.backup ]; then
    cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Create proper startwm.sh
cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
# xrdp X session start script (c) 2015, 2017 mirabilos
# published under The MirOS Licence

if test -r /etc/profile; then
        . /etc/profile
fi

if test -r /etc/default/locale; then
        . /etc/default/locale
        test -z "${LANG+x}" || export LANG
        test -z "${LANGUAGE+x}" || export LANGUAGE
        test -z "${LC_ALL+x}" || export LC_ALL
        test -z "${LC_COLLATE+x}" || export LC_COLLATE
        test -z "${LC_CTYPE+x}" || export LC_CTYPE
        test -z "${LC_MESSAGES+x}" || export LC_MESSAGES
        test -z "${LC_MONETARY+x}" || export LC_MONETARY
        test -z "${LC_NUMERIC+x}" || export LC_NUMERIC
        test -z "${LC_TIME+x}" || export LC_TIME
fi

if test -r /etc/profile; then
        . /etc/profile
fi

# Set default desktop environment to XFCE
export DESKTOP_SESSION=xfce
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_DIRS=/etc/xdg/xfce4

# Fix for clipboard and other issues
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start XFCE
if command -v startxfce4 >/dev/null; then
    exec startxfce4
elif command -v xfce4-session >/dev/null; then
    exec xfce4-session
else
    # Fallback to default Ubuntu desktop if XFCE not available
    if command -v gnome-session >/dev/null; then
        exec gnome-session
    elif command -v unity >/dev/null; then
        exec unity
    else
        # Last resort: start a basic window manager
        exec /etc/X11/Xsession
    fi
fi
EOF

chmod +x /etc/xrdp/startwm.sh
print_success "startwm.sh configured"

# Step 3: Install additional build tools and dependencies
print_info "Installing build tools and dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    xorg-dev \
    libx11-dev \
    libxfixes-dev \
    libssl-dev \
    libpam0g-dev \
    libtool \
    libjpeg-dev \
    flex \
    bison \
    gettext \
    autoconf \
    libxml-parser-perl \
    libfuse-dev \
    xsltproc \
    libxrandr-dev \
    python3-libxml2 \
    nasm \
    xserver-xorg-dev \
    x11-apps \
    > /dev/null 2>&1

print_success "Build tools and dependencies installed"

# Step 4: Add user to ssl-cert group (sometimes needed)
print_info "Configuring user permissions..."
if id "xrdp" &>/dev/null; then
    usermod -a -G ssl-cert xrdp 2>/dev/null || true
fi

# Step 5: Fix polkit authentication (prevents many desktop errors)
print_info "Configuring polkit authentication..."
if [ ! -d /etc/polkit-1/localauthority/50-local.d ]; then
    mkdir -p /etc/polkit-1/localauthority/50-local.d
fi

cat > /etc/polkit-1/localauthority/50-local.d/02-allow-colord.pkla <<'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

print_success "Polkit configured"

# Step 6: Restart services
print_info "Restarting XRDP service..."
systemctl restart xrdp
sleep 2

if systemctl is-active --quiet xrdp; then
    print_success "XRDP service restarted"
else
    print_error "XRDP service failed to restart"
    print_info "Check status: sudo systemctl status xrdp"
fi

print_header "Desktop Fix Complete"

echo ""
print_info "Fix Summary:"
echo "  • XFCE4 desktop environment installed"
echo "  • startwm.sh configured to launch XFCE4"
echo "  • Build tools and dependencies installed"
echo "  • Polkit authentication configured"
echo ""
print_warning "IMPORTANT:"
echo "  • Disconnect and reconnect via RDP to see the changes"
echo "  • After login, you should see the XFCE4 desktop"
echo ""
print_info "If you still have issues, check logs:"
echo "  sudo journalctl -u xrdp-sesman -n 50"
echo "  sudo tail -f /var/log/xrdp-sesman.log"

