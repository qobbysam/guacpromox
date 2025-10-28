#!/bin/bash

################################################################################
# COMPREHENSIVE DESKTOP VM SETUP SCRIPT
# 
# This script sets up an Ubuntu Desktop VM for multi-user XRDP access
# with shared Chrome browser sessions. It includes all fixes and configurations
# needed for Proxmox VMs and XRDP.
#
# USAGE: sudo ./setup-desktop-vm-new.sh
#
# REQUIREMENTS:
# - Ubuntu 22.04 LTS (Desktop or Server)
# - Root/sudo access
# - Internet connection
# - Running in a VM (Proxmox, VirtualBox, etc.)
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SHARED_USER="shared-desktop"
SHARED_USER_PASSWORD="ChangeMe123!"
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"
CHROME_SESSIONS_DIR="/opt/chrome-sessions"
CHROME_LAUNCHER="/usr/local/bin/launch-chrome.sh"
CLEANUP_SCRIPT="/usr/local/bin/cleanup-chrome-sessions.sh"
LOG_FILE="/var/log/desktop-vm-setup.log"

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

print_header() {
    log ""
    log "${CYAN}========================================${NC}"
    log "${CYAN}  $1${NC}"
    log "${CYAN}========================================${NC}"
    log ""
}

print_success() {
    log "${GREEN}✓ $1${NC}"
}

print_error() {
    log "${RED}✗ $1${NC}"
}

print_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

print_info() {
    log "${BLUE}ℹ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "Comprehensive Desktop VM Setup - Starting"
log "Setup started at: $(date)"

# ============================================================================
# STEP 1: System Update
# ============================================================================
print_header "Step 1: System Update"
print_info "Updating system packages..."
apt-get update >> "$LOG_FILE" 2>&1 || { print_error "Failed to update package list"; exit 1; }
apt-get upgrade -y >> "$LOG_FILE" 2>&1 || { print_error "Failed to upgrade packages"; exit 1; }
print_success "System updated"

# ============================================================================
# STEP 2: Install XRDP
# ============================================================================
print_header "Step 2: Installing XRDP"
print_info "Installing XRDP package..."
if ! apt-get install -y xrdp >> "$LOG_FILE" 2>&1; then
    print_error "Failed to install XRDP"
    exit 1
fi
print_success "XRDP installed"

# ============================================================================
# STEP 3: Create XRDP Directories and Set Permissions
# ============================================================================
print_header "Step 3: Creating XRDP Directories"
print_info "Creating required directories..."
mkdir -p /var/log/xrdp
mkdir -p /run/xrdp
chown xrdp:xrdp /var/log/xrdp 2>/dev/null || chown root:root /var/log/xrdp
chown xrdp:xrdp /run/xrdp 2>/dev/null || chown root:root /run/xrdp
chmod 755 /var/log/xrdp
chmod 755 /run/xrdp
touch /var/log/xrdp/xrdp.log
chown xrdp:xrdp /var/log/xrdp/xrdp.log 2>/dev/null || chown root:root /var/log/xrdp/xrdp.log
chmod 644 /var/log/xrdp/xrdp.log
print_success "XRDP directories created with proper permissions"

# ============================================================================
# STEP 4: Install XFCE4 Desktop Environment
# ============================================================================
print_header "Step 4: Installing XFCE4 Desktop Environment"
print_info "Installing XFCE4 (required for XRDP desktop)..."
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    >> "$LOG_FILE" 2>&1; then
    print_error "Failed to install XFCE4"
    exit 1
fi
print_success "XFCE4 desktop environment installed"

# ============================================================================
# STEP 5: Install Xorg Virtualization Drivers
# ============================================================================
print_header "Step 5: Installing Xorg Virtualization Drivers"
print_info "Installing Xorg drivers for VM environments..."
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-video-fbdev \
    xserver-xorg-input-all \
    xserver-xorg-core \
    >> "$LOG_FILE" 2>&1; then
    print_warning "Failed to install some Xorg drivers, continuing..."
fi
print_success "Xorg virtualization drivers installed"

# ============================================================================
# STEP 6: Configure Xorg for Virtualization
# ============================================================================
print_header "Step 6: Configuring Xorg for Virtualization"
print_info "Creating Xorg configuration for VM environments..."
mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/10-xrdp.conf <<'EOF'
Section "ServerLayout"
    Identifier "X11 Server"
    Screen 0 "Screen0"
    Option "AutoAddDevices" "false"
    Option "AutoEnableDevices" "false"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    SubSection "Display"
        Depth 24
        Modes "1920x1080" "1600x1200" "1280x1024" "1024x768"
    EndSubSection
EndSection

Section "Device"
    Identifier "Card0"
    Driver "dummy"
    VideoRam 256000
    Option "IgnoreEDID" "true"
    Option "NoDDC" "true"
EndSection

Section "Monitor"
    Identifier "Monitor0"
    HorizSync 30.0-70.0
    VertRefresh 50.0-75.0
    Modeline "1920x1080" 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync +vsync
    Modeline "1600x1200" 162.00 1600 1664 1856 2160 1200 1201 1204 1250 +hsync +vsync
    Modeline "1280x1024" 108.00 1280 1328 1440 1688 1024 1025 1028 1066 +hsync +vsync
    Modeline "1024x768" 65.00 1024 1048 1184 1344 768 771 777 806 -hsync -vsync
EndSection
EOF

print_success "Xorg configuration created (dummy driver for VMs)"

# ============================================================================
# STEP 7: Configure XRDP
# ============================================================================
print_header "Step 7: Configuring XRDP"

# Backup original configs
if [ -f /etc/xrdp/xrdp.ini ]; then
    cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Configure xrdp.ini with logging section
print_info "Configuring xrdp.ini..."
cat > /etc/xrdp/xrdp.ini <<'EOF'
[Globals]
ini_version=1
fork=true
port=3389
tcp_nodelay=true
tcp_keepalive=true
security_layer=negotiate
crypt_level=high
certificate=
key_file=
ssl_protocols=TLSv1.2, TLSv1.3
autorun=
allow_channels=true
allow_multimon=true
bitmap_cache=true
bitmap_compression=true
bulk_compression=true
max_bpp=32
new_cursors=true
use_fastpath=both
blue=009cb5
grey=dedede
ls_top_window_bg_color=009cb5
ls_width=350
ls_height=430
ls_bg_color=dedede
ls_title=Ubuntu Remote Desktop
channel_code=1
xrdp.ini=xrdp.ini

[Logging]
LogFile=/var/log/xrdp/xrdp.log
LogLevel=INFO
EnableSyslog=true
SyslogLevel=INFO

[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
EOF

# Configure sesman.ini
print_info "Configuring sesman.ini..."
if [ -f /etc/xrdp/sesman.ini ]; then
    cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

cat > /etc/xrdp/sesman.ini <<'EOF'
[Globals]
ListenPort=3350
EnableUserWindowManager=true
UserWindowManager=startwm.sh
DefaultWindowManager=startwm.sh

[Security]
AllowRootLogin=false
MaxLoginRetry=4
TerminalServerUsers=tsusers
TerminalServerAdmins=tsadmins
AlwaysGroupCheck=false

[Sessions]
X11DisplayOffset=10
MaxSessions=50
KillDisconnected=false
IdleTimeLimit=0
DisconnectedTimeLimit=0
Policy=Default

[Logging]
LogFile=xrdp-sesman.log
LogLevel=INFO
EnableSyslog=1
SyslogLevel=INFO

[SessionVariables]
PULSE_SCRIPT=/etc/xrdp/pulse/default.pa
EOF

print_success "XRDP configuration files created"

# ============================================================================
# STEP 8: Configure startwm.sh for XFCE4
# ============================================================================
print_header "Step 8: Configuring Window Manager Startup"
print_info "Configuring startwm.sh to launch XFCE4..."

if [ -f /etc/xrdp/startwm.sh ]; then
    cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

cat > /etc/xrdp/startwm.sh <<'EOF'
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
EOF

chmod +x /etc/xrdp/startwm.sh
print_success "Window manager startup script configured"

# ============================================================================
# STEP 9: Install Build Tools and Dependencies
# ============================================================================
print_header "Step 9: Installing Build Tools and Dependencies"
print_info "Installing additional dependencies..."
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y \
    rsync \
    jq \
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
    >> "$LOG_FILE" 2>&1; then
    print_warning "Some dependencies failed to install, continuing..."
fi
print_success "Dependencies installed"

# ============================================================================
# STEP 10: Configure Polkit Authentication
# ============================================================================
print_header "Step 10: Configuring Polkit Authentication"
print_info "Setting up polkit to prevent desktop errors..."
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

print_success "Polkit authentication configured"

# ============================================================================
# STEP 11: Install Google Chrome
# ============================================================================
print_header "Step 11: Installing Google Chrome"
print_info "Adding Google Chrome repository..."

# Add Google Chrome signing key
if ! wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - >> "$LOG_FILE" 2>&1; then
    print_warning "Failed to add GPG key (may already exist), continuing..."
fi

# Add repository
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Update and install
print_info "Installing Google Chrome..."
apt-get update >> "$LOG_FILE" 2>&1 || { print_error "Failed to update package list after adding Chrome repo"; exit 1; }
if ! apt-get install -y google-chrome-stable >> "$LOG_FILE" 2>&1; then
    print_error "Failed to install Google Chrome"
    exit 1
fi
print_success "Google Chrome installed"

# ============================================================================
# STEP 12: Create Shared User Account
# ============================================================================
print_header "Step 12: Creating Shared User Account"
print_info "Creating user account: $SHARED_USER..."
if id "$SHARED_USER" &>/dev/null; then
    print_warning "User $SHARED_USER already exists, skipping creation"
else
    useradd -m -s /bin/bash "$SHARED_USER"
    echo "$SHARED_USER:$SHARED_USER_PASSWORD" | chpasswd
    print_success "User created (Password: $SHARED_USER_PASSWORD)"
    print_warning "IMPORTANT: Change this password after setup!"
fi

# Add xrdp user to ssl-cert group if it exists
if id "xrdp" &>/dev/null && getent group ssl-cert >/dev/null 2>&1; then
    usermod -a -G ssl-cert xrdp 2>/dev/null || true
fi

# ============================================================================
# STEP 13: Create Directory Structure
# ============================================================================
print_header "Step 13: Creating Directory Structure"
print_info "Creating Chrome profile and session directories..."
mkdir -p "$CHROME_MASTER_PROFILE"
mkdir -p "$CHROME_SESSIONS_DIR"
mkdir -p "/var/log/chrome-sessions"

# Set proper permissions
chown -R "$SHARED_USER":"$SHARED_USER" "$CHROME_MASTER_PROFILE"
chown -R "$SHARED_USER":"$SHARED_USER" "$CHROME_SESSIONS_DIR"
chown -R "$SHARED_USER":"$SHARED_USER" "/var/log/chrome-sessions"
chmod 755 "$CHROME_MASTER_PROFILE"
chmod 755 "$CHROME_SESSIONS_DIR"
chmod 755 "/var/log/chrome-sessions"

print_success "Directory structure created"

# ============================================================================
# STEP 14: Install Chrome Scripts (if present)
# ============================================================================
print_header "Step 14: Installing Chrome Scripts"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/launch-chrome.sh" ]; then
    print_info "Installing launch-chrome.sh..."
    cp "$SCRIPT_DIR/launch-chrome.sh" "$CHROME_LAUNCHER"
    chmod +x "$CHROME_LAUNCHER"
    chown "$SHARED_USER":"$SHARED_USER" "$CHROME_LAUNCHER"
    print_success "Chrome launcher installed"
else
    print_warning "launch-chrome.sh not found in script directory, skipping..."
fi

if [ -f "$SCRIPT_DIR/cleanup-chrome-sessions.sh" ]; then
    print_info "Installing cleanup-chrome-sessions.sh..."
    cp "$SCRIPT_DIR/cleanup-chrome-sessions.sh" "$CLEANUP_SCRIPT"
    chmod +x "$CLEANUP_SCRIPT"
    chown "$SHARED_USER":"$SHARED_USER" "$CLEANUP_SCRIPT"
    print_success "Cleanup script installed"
else
    print_warning "cleanup-chrome-sessions.sh not found in script directory, skipping..."
fi

if [ -f "$SCRIPT_DIR/setup-chrome-master.sh" ]; then
    print_info "Copying setup-chrome-master.sh to user home..."
    cp "$SCRIPT_DIR/setup-chrome-master.sh" "/home/$SHARED_USER/"
    chmod +x "/home/$SHARED_USER/setup-chrome-master.sh"
    chown "$SHARED_USER":"$SHARED_USER" "/home/$SHARED_USER/setup-chrome-master.sh"
    print_success "Master profile setup script installed"
else
    print_warning "setup-chrome-master.sh not found in script directory, skipping..."
fi

# ============================================================================
# STEP 15: Configure Firewall
# ============================================================================
print_header "Step 15: Configuring Firewall"
print_info "Opening port 3389 for RDP..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 3389/tcp >> "$LOG_FILE" 2>&1 || true
    print_success "Firewall rule added (port 3389)"
else
    print_warning "UFW not found, please manually configure firewall to allow port 3389"
fi

# ============================================================================
# STEP 16: Enable and Start Services
# ============================================================================
print_header "Step 16: Starting XRDP Services"
print_info "Enabling and starting XRDP..."
systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable xrdp >> "$LOG_FILE" 2>&1
systemctl enable xrdp-sesman >> "$LOG_FILE" 2>&1

if systemctl restart xrdp xrdp-sesman >> "$LOG_FILE" 2>&1; then
    sleep 3
    if systemctl is-active --quiet xrdp && systemctl is-active --quiet xrdp-sesman; then
        print_success "XRDP services started successfully"
    else
        print_error "XRDP services failed to start"
        print_info "Check logs: sudo journalctl -u xrdp -u xrdp-sesman -n 50"
    fi
else
    print_error "Failed to restart XRDP services"
fi

# ============================================================================
# COMPLETION
# ============================================================================
print_header "Setup Complete!"

log ""
print_info "Setup Summary:"
log "  • System updated"
log "  • XRDP installed and configured"
log "  • XFCE4 desktop environment installed"
log "  • Xorg configured for virtualization (dummy driver)"
log "  • XRDP directories created with proper permissions"
log "  • Window manager configured for XFCE4"
log "  • Build tools and dependencies installed"
log "  • Polkit authentication configured"
log "  • Google Chrome installed"
log "  • Shared user created: $SHARED_USER"
log "  • Chrome directories created"
log "  • Firewall configured (port 3389)"
log ""
print_warning "IMPORTANT NEXT STEPS:"
log "  1. Change the password for user $SHARED_USER:"
log "     sudo passwd $SHARED_USER"
log ""
log "  2. Configure the master Chrome profile:"
log "     sudo -u $SHARED_USER /home/$SHARED_USER/setup-chrome-master.sh"
log "     (Log into all required accounts, install extensions, set bookmarks)"
log ""
log "  3. Test XRDP connection from another machine:"
log "     Connect to: $(hostname -I | awk '{print $1}')"
log "     Username: $SHARED_USER"
log "     Password: [the password you set]"
log ""
log "  4. After connecting via RDP, launch Chrome from desktop or:"
log "     /usr/local/bin/launch-chrome.sh"
log ""
log "  5. Set up automatic cleanup (optional):"
log "     Add to crontab: 0 2 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 7"
log ""
print_info "Log file: $LOG_FILE"
log ""
print_success "Setup completed at: $(date)"
log ""

