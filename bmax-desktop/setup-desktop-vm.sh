#!/bin/bash

################################################################################
# DESKTOP VM SETUP SCRIPT
# 
# This script configures an Ubuntu Desktop VM for multi-user XRDP access
# with shared Chrome browser sessions.
#
# USAGE: sudo ./setup-desktop-vm.sh
#
# REQUIREMENTS:
# - Ubuntu 22.04 LTS Desktop (already installed)
# - Root/sudo access
# - Internet connection
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

print_header "Desktop VM Setup - Starting"

# Update system
print_info "Updating system packages..."
apt-get update >> "$LOG_FILE" 2>&1
apt-get upgrade -y >> "$LOG_FILE" 2>&1
print_success "System updated"

# Install XRDP
print_info "Installing XRDP..."
apt-get install -y xrdp >> "$LOG_FILE" 2>&1
print_success "XRDP installed"

# Configure XRDP for concurrent sessions
print_info "Configuring XRDP for concurrent sessions..."

# Backup original config
cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup

# Configure XRDP to allow multiple sessions
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

[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
EOF

# Configure sesman for concurrent sessions
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

print_success "XRDP configured for concurrent sessions"

# Create XRDP directories and set permissions
print_info "Creating XRDP directories..."
mkdir -p /var/log/xrdp
mkdir -p /run/xrdp
chown xrdp:xrdp /var/log/xrdp
chown xrdp:xrdp /run/xrdp
chmod 755 /var/log/xrdp
chmod 755 /run/xrdp
print_success "XRDP directories created"

# Install Google Chrome
print_info "Installing Google Chrome..."
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - >> "$LOG_FILE" 2>&1
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update >> "$LOG_FILE" 2>&1
apt-get install -y google-chrome-stable >> "$LOG_FILE" 2>&1
print_success "Google Chrome installed"

# Install additional dependencies
print_info "Installing additional dependencies..."
apt-get install -y rsync jq >> "$LOG_FILE" 2>&1
print_success "Dependencies installed"

# Create shared user account
print_info "Creating shared user account: $SHARED_USER..."
if id "$SHARED_USER" &>/dev/null; then
    print_warning "User $SHARED_USER already exists, skipping creation"
else
    useradd -m -s /bin/bash "$SHARED_USER"
    echo "$SHARED_USER:$SHARED_USER_PASSWORD" | chpasswd
    print_success "User created (Password: $SHARED_USER_PASSWORD)"
    print_warning "IMPORTANT: Change this password after setup!"
fi

# Create directory structure
print_info "Creating directory structure..."
mkdir -p "$CHROME_MASTER_PROFILE"
mkdir -p "$CHROME_SESSIONS_DIR"
mkdir -p "/var/log/chrome-sessions"

# Set proper permissions
chown -R "$SHARED_USER":"$SHARED_USER" "$CHROME_MASTER_PROFILE"
chown -R "$SHARED_USER":"$SHARED_USER" "$CHROME_SESSIONS_DIR"
chown -R "$SHARED_USER":"$SHARED_USER" "/var/log/chrome-sessions"
chmod 755 "$CHROME_MASTER_PROFILE"
chmod 755 "$CHROME_SESSIONS_DIR"

print_success "Directory structure created"

# Enable and start XRDP
print_info "Enabling and starting XRDP service..."
systemctl enable xrdp >> "$LOG_FILE" 2>&1
systemctl start xrdp >> "$LOG_FILE" 2>&1
print_success "XRDP service started"

# Configure firewall
print_info "Configuring firewall..."
ufw allow 3389/tcp >> "$LOG_FILE" 2>&1
print_success "Firewall configured (port 3389 open)"

# Create Chrome launcher script (will be populated by extraction)
print_info "Chrome launcher script will be created separately..."
print_success "Directory prepared for Chrome launcher"

print_header "Desktop VM Setup - Complete"

echo ""
print_info "Setup Summary:"
echo "  • XRDP installed and configured for concurrent sessions"
echo "  • Google Chrome installed"
echo "  • Shared user created: $SHARED_USER"
echo "  • Initial password: $SHARED_USER_PASSWORD"
echo "  • Master profile directory: $CHROME_MASTER_PROFILE"
echo "  • Session profiles directory: $CHROME_SESSIONS_DIR"
echo ""
print_warning "NEXT STEPS:"
echo "  1. Copy launch-chrome.sh to $CHROME_LAUNCHER"
echo "  2. Copy setup-chrome-master.sh to /home/$SHARED_USER/"
echo "  3. Copy cleanup-chrome-sessions.sh to /usr/local/bin/"
echo "  4. Run setup-chrome-master.sh as $SHARED_USER to configure master profile"
echo "  5. Test XRDP connection from another machine"
echo "  6. Change the default password for $SHARED_USER"
echo ""
print_success "Log file: $LOG_FILE"
