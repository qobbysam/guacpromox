#!/bin/bash

################################################################################
# MULTI-USER REMOTE DESKTOP SYSTEM - COMPLETE DEPLOYMENT PACKAGE
# 
# This file contains all scripts and documentation needed to deploy a
# multi-user remote desktop environment with shared browser sessions.
#
# ARCHITECTURE:
# - Proxmox Host: Running multiple Ubuntu Desktop VMs
# - Guacamole Server: Web-based remote access gateway
# - Desktop VMs: Ubuntu Desktop with XRDP for concurrent user access
# - Access Method: Cloudflare Tunnel exposing Guacamole to internet
#
# USAGE:
# 1. Extract individual scripts using the extract_script function below
# 2. Follow the DEPLOYMENT-GUIDE section at the end of this file
# 3. Run scripts in the order specified in the deployment guide
#
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# SCRIPT EXTRACTION UTILITY
################################################################################

extract_all_scripts() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Script Extraction Utility${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This utility will extract all individual scripts from this package."
    echo ""
    
    # Create extraction directory
    EXTRACT_DIR="remote-desktop-deployment"
    mkdir -p "$EXTRACT_DIR"
    
    echo -e "${GREEN}Extracting scripts to: $EXTRACT_DIR/${NC}"
    echo ""
    
    # Extract each script section
    extract_script "SETUP_DESKTOP_VM" "$EXTRACT_DIR/setup-desktop-vm.sh"
    extract_script "LAUNCH_CHROME" "$EXTRACT_DIR/launch-chrome.sh"
    extract_script "SETUP_CHROME_MASTER" "$EXTRACT_DIR/setup-chrome-master.sh"
    extract_script "CLEANUP_CHROME_SESSIONS" "$EXTRACT_DIR/cleanup-chrome-sessions.sh"
    extract_script "DOCKER_COMPOSE" "$EXTRACT_DIR/docker-compose.yml"
    extract_script "SETUP_GUACAMOLE" "$EXTRACT_DIR/setup-guacamole.sh"
    extract_script "MANAGE_GUACAMOLE" "$EXTRACT_DIR/manage-guacamole.sh"
    extract_script "CONFIGURE_GUACAMOLE" "$EXTRACT_DIR/configure-guacamole.sh"
    extract_script "SETUP_CLOUDFLARE_TUNNEL" "$EXTRACT_DIR/setup-cloudflare-tunnel.sh"
    extract_script "README_DESKTOP" "$EXTRACT_DIR/README-DESKTOP.txt"
    extract_script "README_ADMIN" "$EXTRACT_DIR/README-ADMIN.txt"
    extract_script "DEPLOYMENT_GUIDE" "$EXTRACT_DIR/DEPLOYMENT-GUIDE.md"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Extraction Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "All scripts have been extracted to: $EXTRACT_DIR/"
    echo ""
    echo "Next steps:"
    echo "1. cd $EXTRACT_DIR"
    echo "2. Read DEPLOYMENT-GUIDE.md"
    echo "3. Follow the deployment phases"
}

extract_script() {
    local marker="$1"
    local output_file="$2"
    local start_marker="##### BEGIN_${marker} #####"
    local end_marker="##### END_${marker} #####"
    
    echo -n "Extracting $(basename $output_file)... "
    
    sed -n "/$start_marker/,/$end_marker/p" "$0" | sed '1d;$d' > "$output_file"
    
    if [[ "$output_file" == *.sh ]]; then
        chmod +x "$output_file"
    fi
    
    echo -e "${GREEN}✓${NC}"
}

# If script is run directly, extract all scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    extract_all_scripts
    exit 0
fi

################################################################################
# SCRIPT SECTIONS BEGIN HERE
################################################################################

##### BEGIN_SETUP_DESKTOP_VM #####
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
##### END_SETUP_DESKTOP_VM #####

##### BEGIN_LAUNCH_CHROME #####
#!/bin/bash

################################################################################
# CHROME LAUNCHER SCRIPT WITH SESSION ISOLATION
#
# This script launches Chrome with a unique profile for each XRDP session,
# while inheriting configurations from a master profile.
#
# USAGE: /usr/local/bin/launch-chrome.sh
#
# INSTALLATION: Copy to /usr/local/bin/launch-chrome.sh and chmod +x
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"
CHROME_SESSIONS_DIR="/opt/chrome-sessions"
LOG_DIR="/var/log/chrome-sessions"
CHROME_BIN="/usr/bin/google-chrome-stable"

# Generate unique session ID based on DISPLAY and timestamp
DISPLAY_NUM=$(echo "$DISPLAY" | tr -cd '0-9')
SESSION_ID="session-${DISPLAY_NUM}-$(date +%s)-$$"
SESSION_PROFILE="$CHROME_SESSIONS_DIR/$SESSION_ID"
LOG_FILE="$LOG_DIR/$SESSION_ID.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "========================================="
log "Chrome Session Launcher Starting"
log "Session ID: $SESSION_ID"
log "Display: $DISPLAY"
log "User: $USER"
log "========================================="

# Check if master profile exists
if [[ ! -d "$CHROME_MASTER_PROFILE" ]]; then
    echo -e "${RED}ERROR: Master profile not found at $CHROME_MASTER_PROFILE${NC}"
    echo -e "${YELLOW}Please run setup-chrome-master.sh first to create the master profile.${NC}"
    log "ERROR: Master profile not found"
    exit 1
fi

# Create session profile directory
log "Creating session profile directory: $SESSION_PROFILE"
mkdir -p "$SESSION_PROFILE"

# Copy master profile to session profile
log "Syncing master profile to session profile..."
echo -e "${BLUE}Initializing Chrome session...${NC}"

# Critical directories and files to sync from master profile
SYNC_ITEMS=(
    "Default/Cookies"
    "Default/Login Data"
    "Default/Preferences"
    "Default/Bookmarks"
    "Default/Extensions"
    "Default/Local Extension Settings"
    "Default/Sync Extension Settings"
    "Default/Web Data"
    "Local State"
    "First Run"
)

# Sync each item if it exists in master profile
for item in "${SYNC_ITEMS[@]}"; do
    src="$CHROME_MASTER_PROFILE/$item"
    dst="$SESSION_PROFILE/$item"
    
    if [[ -e "$src" ]]; then
        log "Syncing: $item"
        mkdir -p "$(dirname "$dst")"
        
        if [[ -d "$src" ]]; then
            rsync -a "$src/" "$dst/" 2>> "$LOG_FILE"
        else
            cp "$src" "$dst" 2>> "$LOG_FILE"
        fi
    fi
done

log "Profile sync complete"

# Set proper permissions
chmod -R 700 "$SESSION_PROFILE" 2>> "$LOG_FILE"

# Chrome flags for optimal performance and session isolation
CHROME_FLAGS=(
    "--user-data-dir=$SESSION_PROFILE"
    "--no-first-run"
    "--no-default-browser-check"
    "--disable-session-crashed-bubble"
    "--disable-infobars"
    "--disable-features=TranslateUI"
    "--disk-cache-dir=/tmp/chrome-cache-$SESSION_ID"
    "--disk-cache-size=104857600"
)

log "Launching Chrome with session profile"
log "Chrome flags: ${CHROME_FLAGS[*]}"

# Launch Chrome in background
"$CHROME_BIN" "${CHROME_FLAGS[@]}" >> "$LOG_FILE" 2>&1 &
CHROME_PID=$!

log "Chrome launched with PID: $CHROME_PID"

# Function to cleanup on exit
cleanup() {
    log "Cleanup triggered for session $SESSION_ID"
    
    # Optional: Sync bookmarks back to master profile
    BOOKMARKS_SRC="$SESSION_PROFILE/Default/Bookmarks"
    BOOKMARKS_DST="$CHROME_MASTER_PROFILE/Default/Bookmarks"
    
    if [[ -f "$BOOKMARKS_SRC" ]]; then
        log "Syncing bookmarks back to master profile"
        cp "$BOOKMARKS_SRC" "$BOOKMARKS_DST" 2>> "$LOG_FILE"
    fi
    
    # Wait a moment for Chrome to fully close
    sleep 2
    
    # Clean up temporary cache
    rm -rf "/tmp/chrome-cache-$SESSION_ID" 2>> "$LOG_FILE"
    
    log "Session cleanup complete"
    log "========================================="
}

# Register cleanup on script exit
trap cleanup EXIT

# Wait for Chrome process to exit
wait $CHROME_PID
EXIT_CODE=$?

log "Chrome process exited with code: $EXIT_CODE"

exit $EXIT_CODE
##### END_LAUNCH_CHROME #####

##### BEGIN_SETUP_CHROME_MASTER #####
#!/bin/bash

################################################################################
# CHROME MASTER PROFILE SETUP SCRIPT
#
# This script helps the administrator create and configure the master Chrome
# profile that will be shared across all user sessions.
#
# USAGE: Run as the shared-desktop user
#        ./setup-chrome-master.sh
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"
CHROME_BIN="/usr/bin/google-chrome-stable"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Chrome Master Profile Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if running as shared-desktop user
if [[ "$USER" != "shared-desktop" ]] && [[ "$USER" != "root" ]]; then
    echo -e "${YELLOW}⚠ Warning: This script should be run as 'shared-desktop' user${NC}"
    echo -e "${YELLOW}  Current user: $USER${NC}"
    echo ""
    read -p "Continue anyway? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        exit 1
    fi
fi

# Check if Chrome is installed
if [[ ! -f "$CHROME_BIN" ]]; then
    echo -e "${RED}✗ Google Chrome not found at $CHROME_BIN${NC}"
    echo -e "${RED}  Please install Google Chrome first${NC}"
    exit 1
fi

# Check if master profile directory exists
if [[ ! -d "$CHROME_MASTER_PROFILE" ]]; then
    echo -e "${RED}✗ Master profile directory not found: $CHROME_MASTER_PROFILE${NC}"
    echo -e "${RED}  Please run setup-desktop-vm.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}This script will launch Chrome in master profile configuration mode.${NC}"
echo ""
echo -e "${YELLOW}INSTRUCTIONS:${NC}"
echo "1. Chrome will open with the master profile"
echo "2. Log in to all required accounts:"
echo "   • Gmail/Google Workspace"
echo "   • Salesforce"
echo "   • Slack"
echo "   • Any other web applications"
echo "3. Install any required Chrome extensions"
echo "4. Configure bookmarks and preferences"
echo "5. When finished, close Chrome normally"
echo "6. This configuration will be shared with all users"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "• Each user will have their own isolated browsing session"
echo "• But they will all be logged into the same accounts"
echo "• Multiple users can use the same accounts simultaneously"
echo "• Individual browsing history and tabs are NOT shared"
echo ""

read -p "Press Enter to launch Chrome in master profile mode..."

echo ""
echo -e "${GREEN}Launching Chrome with master profile...${NC}"
echo -e "${BLUE}Master profile location: $CHROME_MASTER_PROFILE${NC}"
echo ""

# Launch Chrome with master profile
"$CHROME_BIN" --user-data-dir="$CHROME_MASTER_PROFILE" \
    --no-first-run \
    --no-default-browser-check

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Master Profile Configuration${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if profile was created
if [[ -d "$CHROME_MASTER_PROFILE/Default" ]]; then
    echo -e "${GREEN}✓ Master profile created successfully${NC}"
    echo ""
    echo -e "${BLUE}Profile contents:${NC}"
    ls -lh "$CHROME_MASTER_PROFILE/" | tail -n +2
    echo ""
    
    # Check for important files
    echo -e "${BLUE}Checking configuration:${NC}"
    
    if [[ -f "$CHROME_MASTER_PROFILE/Default/Cookies" ]]; then
        echo -e "${GREEN}✓ Cookies file present${NC}"
    else
        echo -e "${YELLOW}⚠ No cookies file found (may not have logged into any accounts)${NC}"
    fi
    
    if [[ -f "$CHROME_MASTER_PROFILE/Default/Bookmarks" ]]; then
        echo -e "${GREEN}✓ Bookmarks file present${NC}"
    else
        echo -e "${YELLOW}⚠ No bookmarks file${NC}"
    fi
    
    if [[ -d "$CHROME_MASTER_PROFILE/Default/Extensions" ]]; then
        ext_count=$(ls -1 "$CHROME_MASTER_PROFILE/Default/Extensions" 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ Extensions directory present ($ext_count extensions)${NC}"
    else
        echo -e "${YELLOW}⚠ No extensions directory${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Master profile setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo "1. Test the configuration by running: /usr/local/bin/launch-chrome.sh"
    echo "2. Connect via XRDP and verify all accounts are logged in"
    echo "3. Test with multiple concurrent XRDP sessions"
    echo "4. If you need to update the master profile, run this script again"
    echo ""
else
    echo -e "${RED}✗ Master profile was not created${NC}"
    echo -e "${YELLOW}  This might happen if Chrome was closed immediately${NC}"
    echo -e "${YELLOW}  Please try running this script again${NC}"
    echo ""
fi

echo -e "${BLUE}Master profile location: $CHROME_MASTER_PROFILE${NC}"
##### END_SETUP_CHROME_MASTER #####

##### BEGIN_CLEANUP_CHROME_SESSIONS #####
#!/bin/bash

################################################################################
# CHROME SESSIONS CLEANUP SCRIPT
#
# This script cleans up old Chrome session profiles to free up disk space.
# Should be run via cron daily or weekly.
#
# USAGE: /usr/local/bin/cleanup-chrome-sessions.sh [--days N] [--dry-run]
#
# OPTIONS:
#   --days N    Delete sessions older than N days (default: 7)
#   --dry-run   Show what would be deleted without actually deleting
################################################################################

# Configuration
CHROME_SESSIONS_DIR="/opt/chrome-sessions"
LOG_DIR="/var/log/chrome-sessions"
CLEANUP_LOG="/var/log/chrome-sessions-cleanup.log"
DEFAULT_DAYS=7

# Parse arguments
DAYS=$DEFAULT_DAYS
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            DAYS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--days N] [--dry-run]"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CLEANUP_LOG"
}

log "========================================="
log "Chrome Sessions Cleanup Starting"
log "Delete sessions older than: $DAYS days"
log "Dry run: $DRY_RUN"
log "========================================="

# Check if sessions directory exists
if [[ ! -d "$CHROME_SESSIONS_DIR" ]]; then
    log "ERROR: Sessions directory not found: $CHROME_SESSIONS_DIR"
    exit 1
fi

# Find old session directories
OLD_SESSIONS=$(find "$CHROME_SESSIONS_DIR" -maxdepth 1 -type d -name "session-*" -mtime +$DAYS)
SESSION_COUNT=$(echo "$OLD_SESSIONS" | grep -c "session-" || true)

if [[ $SESSION_COUNT -eq 0 ]]; then
    log "No old sessions found (older than $DAYS days)"
    log "Cleanup complete"
    exit 0
fi

log "Found $SESSION_COUNT session(s) to clean up"

# Calculate space to be freed
SPACE_TO_FREE=$(du -sh "$CHROME_SESSIONS_DIR" | awk '{print $1}')
log "Current sessions directory size: $SPACE_TO_FREE"

# Delete old sessions
DELETED_COUNT=0
FAILED_COUNT=0

while IFS= read -r session_dir; do
    if [[ -z "$session_dir" ]]; then
        continue
    fi
    
    session_name=$(basename "$session_dir")
    session_size=$(du -sh "$session_dir" 2>/dev/null | awk '{print $1}')
    session_age=$(find "$session_dir" -maxdepth 0 -printf '%Td days\n' 2>/dev/null)
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would delete: $session_name (Size: $session_size, Age: $session_age)"
    else
        log "Deleting: $session_name (Size: $session_size, Age: $session_age)"
        if rm -rf "$session_dir" 2>> "$CLEANUP_LOG"; then
            ((DELETED_COUNT++))
            log "  ✓ Deleted successfully"
        else
            ((FAILED_COUNT++))
            log "  ✗ Failed to delete"
        fi
    fi
done <<< "$OLD_SESSIONS"

# Clean up old log files
OLD_LOGS=$(find "$LOG_DIR" -type f -name "session-*.log" -mtime +$DAYS)
LOG_COUNT=$(echo "$OLD_LOGS" | grep -c "session-" || true)

if [[ $LOG_COUNT -gt 0 ]]; then
    log "Found $LOG_COUNT old log file(s)"
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would delete $LOG_COUNT log file(s)"
    else
        echo "$OLD_LOGS" | xargs rm -f 2>> "$CLEANUP_LOG"
        log "Deleted $LOG_COUNT old log file(s)"
    fi
fi

# Calculate space freed
if [[ $DRY_RUN == false ]] && [[ $DELETED_COUNT -gt 0 ]]; then
    NEW_SPACE=$(du -sh "$CHROME_SESSIONS_DIR" 2>/dev/null | awk '{print $1}')
    log "Sessions directory size after cleanup: $NEW_SPACE"
fi

# Summary
log "========================================="
if [[ $DRY_RUN == true ]]; then
    log "DRY RUN SUMMARY:"
    log "  Would delete: $SESSION_COUNT session(s)"
    log "  Would delete: $LOG_COUNT log file(s)"
else
    log "CLEANUP SUMMARY:"
    log "  Sessions deleted: $DELETED_COUNT"
    log "  Failed deletions: $FAILED_COUNT"
    log "  Logs deleted: $LOG_COUNT"
fi
log "Cleanup complete"
log "========================================="

# Exit with error if any deletions failed
if [[ $FAILED_COUNT -gt 0 ]]; then
    exit 1
fi

exit 0
##### END_CLEANUP_CHROME_SESSIONS #####

##### BEGIN_DOCKER_COMPOSE #####
version: '3.8'

################################################################################
# GUACAMOLE DOCKER COMPOSE CONFIGURATION
#
# This Docker Compose file deploys the complete Guacamole stack:
# - PostgreSQL database for user/connection management
# - guacd daemon for remote desktop protocol handling
# - Guacamole web application
#
# USAGE: docker-compose up -d
################################################################################

services:
  # PostgreSQL Database
  guacamole-db:
    container_name: guacamole-postgres
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: guacamole_db
      POSTGRES_USER: guacamole_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-ChangeMePostgresPassword123!}
      PGDATA: /var/lib/postgresql/data/guacamole
    volumes:
      - guacamole-db-data:/var/lib/postgresql/data
      - ./initdb.sql:/docker-entrypoint-initdb.d/initdb.sql:ro
    networks:
      - guacamole-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U guacamole_user -d guacamole_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Guacamole Daemon (guacd)
  guacd:
    container_name: guacd
    image: guacamole/guacd:1.5.4
    restart: unless-stopped
    networks:
      - guacamole-network
    volumes:
      - guacd-drive:/drive
      - guacd-record:/record
    healthcheck:
      test: ["CMD", "pgrep", "guacd"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Guacamole Web Application
  guacamole:
    container_name: guacamole
    image: guacamole/guacamole:1.5.4
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      GUACD_HOSTNAME: guacd
      GUACD_PORT: 4822
      POSTGRES_HOSTNAME: guacamole-db
      POSTGRES_DATABASE: guacamole_db
      POSTGRES_USER: guacamole_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-ChangeMePostgresPassword123!}
      POSTGRES_AUTO_CREATE_ACCOUNTS: "true"
    depends_on:
      guacamole-db:
        condition: service_healthy
      guacd:
        condition: service_healthy
    networks:
      - guacamole-network
    volumes:
      - guacamole-data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/guacamole/"]
      interval: 30s
      timeout: 10s
      retries: 5

networks:
  guacamole-network:
    driver: bridge

volumes:
  guacamole-db-data:
    driver: local
  guacamole-data:
    driver: local
  guacd-drive:
    driver: local
  guacd-record:
    driver: local
##### END_DOCKER_COMPOSE #####

##### BEGIN_SETUP_GUACAMOLE #####
#!/bin/bash

################################################################################
# GUACAMOLE SETUP SCRIPT
#
# This script installs and configures Apache Guacamole using Docker.
#
# USAGE: sudo ./setup-guacamole.sh
#
# REQUIREMENTS:
# - Ubuntu 22.04 LTS Server (or Desktop)
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
INSTALL_DIR="/opt/guacamole"
LOG_FILE="/var/log/guacamole-setup.log"
POSTGRES_PASSWORD=$(openssl rand -base64 24)
GUACAMOLE_VERSION="1.5.4"

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

print_header "Guacamole Setup - Starting"

# Update system
print_info "Updating system packages..."
apt-get update >> "$LOG_FILE" 2>&1
print_success "System updated"

# Install Docker
print_info "Installing Docker..."
if command -v docker &> /dev/null; then
    print_warning "Docker already installed"
else
    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg lsb-release >> "$LOG_FILE" 2>&1
    
    # Add Docker GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update >> "$LOG_FILE" 2>&1
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >> "$LOG_FILE" 2>&1
    
    # Start Docker
    systemctl enable docker >> "$LOG_FILE" 2>&1
    systemctl start docker >> "$LOG_FILE" 2>&1
    
    print_success "Docker installed"
fi

# Verify Docker installation
if ! docker --version >> "$LOG_FILE" 2>&1; then
    print_error "Docker installation failed"
    exit 1
fi

# Create installation directory
print_info "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
print_success "Installation directory created: $INSTALL_DIR"

# Generate database initialization script
print_info "Generating database initialization script..."
docker run --rm guacamole/guacamole:$GUACAMOLE_VERSION /opt/guacamole/bin/initdb.sh --postgres > "$INSTALL_DIR/initdb.sql"
print_success "Database initialization script created"

# Create .env file for docker-compose
print_info "Creating environment configuration..."
cat > "$INSTALL_DIR/.env" <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOF
chmod 600 "$INSTALL_DIR/.env"
print_success "Environment configuration created"

# Create docker-compose.yml (should be copied from extraction)
print_info "Docker Compose file should be in place..."
if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
    print_warning "docker-compose.yml not found, please copy it to $INSTALL_DIR/"
fi

# Start Guacamole stack
print_info "Starting Guacamole stack..."
cd "$INSTALL_DIR"
docker compose up -d >> "$LOG_FILE" 2>&1

# Wait for services to be healthy
print_info "Waiting for services to start (this may take 30-60 seconds)..."
sleep 10

# Check if containers are running
CONTAINERS_RUNNING=$(docker compose ps | grep -c "Up")
if [[ $CONTAINERS_RUNNING -ge 3 ]]; then
    print_success "All containers started successfully"
else
    print_warning "Some containers may not be running properly"
    docker compose ps
fi

# Configure firewall
print_info "Configuring firewall..."
ufw allow 8080/tcp >> "$LOG_FILE" 2>&1
print_success "Firewall configured (port 8080 open)"

# Create systemd service for auto-start
print_info "Creating systemd service..."
cat > /etc/systemd/system/guacamole.service <<EOF
[Unit]
Description=Guacamole Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable guacamole.service >> "$LOG_FILE" 2>&1
print_success "Systemd service created and enabled"

print_header "Guacamole Setup - Complete"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
print_info "Setup Summary:"
echo "  • Guacamole installed at: $INSTALL_DIR"
echo "  • Web interface: http://$SERVER_IP:8080/guacamole/"
echo "  • Default username: guacadmin"
echo "  • Default password: guacadmin"
echo "  • Database password: $POSTGRES_PASSWORD (saved in .env file)"
echo ""
print_warning "IMPORTANT SECURITY STEPS:"
echo "  1. Change the default 'guacadmin' password immediately!"
echo "  2. Create additional admin users"
echo "  3. Consider disabling the default guacadmin account"
echo ""
print_warning "NEXT STEPS:"
echo "  1. Access Guacamole web interface"
echo "  2. Log in with guacadmin / guacadmin"
echo "  3. Go to Settings (top-right) → Users → guacadmin → Change password"
echo "  4. Create user groups (admins, regular-users)"
echo "  5. Create RDP connections to desktop VMs"
echo "  6. Assign permissions to users/groups"
echo "  7. Run configure-guacamole.sh for guided setup"
echo ""
print_success "Log file: $LOG_FILE"
print_success "Configuration saved in: $INSTALL_DIR"
##### END_SETUP_GUACAMOLE #####

##### BEGIN_MANAGE_GUACAMOLE #####
#!/bin/bash

################################################################################
# GUACAMOLE MANAGEMENT SCRIPT
#
# This script provides easy management commands for Guacamole.
#
# USAGE: ./manage-guacamole.sh [command]
#
# COMMANDS:
#   start    - Start Guacamole services
#   stop     - Stop Guacamole services
#   restart  - Restart Guacamole services
#   status   - Show service status
#   logs     - Show recent logs
#   backup   - Backup Guacamole database
#   restore  - Restore Guacamole database
#   update   - Update Guacamole to latest version
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/guacamole"
BACKUP_DIR="/opt/guacamole/backups"

print_header() {
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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Guacamole installation not found at $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# Command functions
cmd_start() {
    print_header "Starting Guacamole Services"
    docker compose up -d
    print_success "Services started"
}

cmd_stop() {
    print_header "Stopping Guacamole Services"
    docker compose down
    print_success "Services stopped"
}

cmd_restart() {
    print_header "Restarting Guacamole Services"
    docker compose restart
    print_success "Services restarted"
}

cmd_status() {
    print_header "Guacamole Service Status"
    docker compose ps
    echo ""
    print_info "Container Health:"
    docker inspect guacamole-postgres guacd guacamole --format='{{.Name}}: {{.State.Health.Status}}' 2>/dev/null || echo "Health check info not available"
}

cmd_logs() {
    print_header "Guacamole Logs (Recent)"
    echo "Press Ctrl+C to exit log view"
    echo ""
    docker compose logs --tail=50 -f
}

cmd_backup() {
    print_header "Backing Up Guacamole Database"
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/guacamole-backup-$(date +%Y%m%d-%H%M%S).sql"
    
    print_info "Creating backup: $BACKUP_FILE"
    
    docker exec guacamole-postgres pg_dump -U guacamole_user guacamole_db > "$BACKUP_FILE"
    
    if [[ -f "$BACKUP_FILE" ]]; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
        print_success "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"
        
        # Keep only last 10 backups
        BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/guacamole-backup-*.sql 2>/dev/null | wc -l)
        if [[ $BACKUP_COUNT -gt 10 ]]; then
            print_info "Cleaning up old backups (keeping last 10)..."
            ls -1t "$BACKUP_DIR"/guacamole-backup-*.sql | tail -n +11 | xargs rm -f
        fi
    else
        print_error "Backup failed"
        exit 1
    fi
}

cmd_restore() {
    print_header "Restore Guacamole Database"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A $BACKUP_DIR/*.sql 2>/dev/null)" ]]; then
        print_error "No backups found in $BACKUP_DIR"
        exit 1
    fi
    
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/*.sql
    echo ""
    
    read -p "Enter backup filename to restore: " BACKUP_FILE
    
    if [[ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        print_error "Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}WARNING: This will overwrite the current database!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    print_info "Restoring database from: $BACKUP_FILE"
    
    docker exec -i guacamole-postgres psql -U guacamole_user guacamole_db < "$BACKUP_DIR/$BACKUP_FILE"
    
    print_success "Database restored"
    print_info "Restarting Guacamole..."
    docker compose restart guacamole
    print_success "Restore complete"
}

cmd_update() {
    print_header "Update Guacamole"
    
    echo -e "${YELLOW}This will update Guacamole to the latest version${NC}"
    read -p "Continue? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Update cancelled"
        exit 0
    fi
    
    # Backup first
    print_info "Creating backup before update..."
    cmd_backup
    
    # Pull latest images
    print_info "Pulling latest Docker images..."
    docker compose pull
    
    # Restart with new images
    print_info "Restarting with updated images..."
    docker compose up -d
    
    print_success "Update complete"
}

# Main command handler
case "${1:-help}" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs
        ;;
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore
        ;;
    update)
        cmd_update
        ;;
    help|*)
        print_header "Guacamole Management Script"
        echo "Usage: $0 [command]"
        echo ""
        echo "Available commands:"
        echo "  start    - Start Guacamole services"
        echo "  stop     - Stop Guacamole services"
        echo "  restart  - Restart Guacamole services"
        echo "  status   - Show service status"
        echo "  logs     - Show recent logs (follow mode)"
        echo "  backup   - Backup Guacamole database"
        echo "  restore  - Restore Guacamole database from backup"
        echo "  update   - Update Guacamole to latest version"
        echo ""
        ;;
esac
##### END_MANAGE_GUACAMOLE #####

##### BEGIN_CONFIGURE_GUACAMOLE #####
#!/bin/bash

################################################################################
# GUACAMOLE CONFIGURATION GUIDE
#
# This interactive script guides you through configuring Guacamole
# for multi-user access to desktop VMs.
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}>>> $1${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

wait_for_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
GUACAMOLE_URL="http://$SERVER_IP:8080/guacamole/"

print_header "Guacamole Configuration Guide"

echo "This interactive guide will help you configure Guacamole for"
echo "multi-user access to your desktop VMs."
echo ""
echo -e "Guacamole URL: ${CYAN}$GUACAMOLE_URL${NC}"
echo ""

print_warning "Before proceeding, ensure:"
echo "  • Guacamole is running (check with: ./manage-guacamole.sh status)"
echo "  • You can access the web interface"
echo "  • You have the default credentials (guacadmin / guacadmin)"
echo ""

wait_for_enter

# Step 1: Change Default Password
print_header "Step 1: Change Default Administrator Password"

echo "SECURITY CRITICAL: You must change the default password!"
echo ""
print_step "1. Navigate to: $GUACAMOLE_URL"
print_step "2. Log in with username: guacadmin, password: guacadmin"
print_step "3. Click your username (guacadmin) in the top-right corner"
print_step "4. Select 'Settings'"
print_step "5. Click on 'Users' tab"
print_step "6. Click on 'guacadmin'"
print_step "7. Enter a new strong password"
print_step "8. Click 'Save'"
echo ""

print_warning "Write down your new password in a secure location!"

wait_for_enter

# Step 2: Create User Groups
print_header "Step 2: Create User Groups"

echo "We'll create two groups:"
echo "  • admins: Full access to all desktop VMs"
echo "  • regular-users: Access only to assigned desktop VMs"
echo ""

print_section "Creating 'admins' group:"
print_step "1. Go to Settings → Groups"
print_step "2. Click 'New Group'"
print_step "3. Group name: admins"
print_step "4. Under 'Permissions', check:"
print_step "   □ Create new connections"
print_step "   □ Create new connection groups"
print_step "   □ Create new users"
print_step "   □ Create new user groups"
print_step "5. Click 'Save'"
echo ""

wait_for_enter

print_section "Creating 'regular-users' group:"
print_step "1. Click 'New Group' again"
print_step "2. Group name: regular-users"
print_step "3. No special permissions needed (users will only access assigned VMs)"
print_step "4. Click 'Save'"
echo ""

wait_for_enter

# Step 3: Create RDP Connections
print_header "Step 3: Create RDP Connections to Desktop VMs"

echo "Now we'll create connections to your desktop VMs."
echo ""
print_info "You'll need:"
echo "  • IP address of each desktop VM"
echo "  • RDP port (default: 3389)"
echo "  • Shared username: shared-desktop"
echo "  • Password for shared-desktop user"
echo ""

print_section "Creating an RDP connection:"
print_step "1. Go to Settings → Connections"
print_step "2. Click 'New Connection'"
print_step "3. Fill in the details:"
echo ""
echo "   Name: (e.g., 'Marketing Desktop', 'Sales Desktop', 'Dev Desktop')"
echo "   Location: ROOT"
echo "   Protocol: RDP"
echo ""
echo "   Parameters tab:"
echo "     Hostname: [IP address of desktop VM]"
echo "     Port: 3389"
echo "     Username: shared-desktop"
echo "     Password: [password for shared-desktop]"
echo ""
echo "   Display tab:"
echo "     Color depth: True color (32-bit)"
echo "     Force lossless: checked (optional, for better quality)"
echo ""
echo "   Performance tab (optional optimizations):"
echo "     Enable wallpaper: checked"
echo "     Enable theming: checked"
echo "     Enable font smoothing: checked"
echo ""
print_step "4. Click 'Save'"
echo ""

print_info "Example desktop VMs to create:"
echo "  • Marketing Desktop (192.168.1.101)"
echo "  • Sales Desktop (192.168.1.102)"
echo "  • Development Desktop (192.168.1.103)"
echo "  • General Use Desktop (192.168.1.104)"
echo ""

print_warning "Repeat this process for each desktop VM"

wait_for_enter

# Step 4: Create Users
print_header "Step 4: Create User Accounts"

echo "Create user accounts for people who will access the system."
echo ""

print_section "Creating an admin user:"
print_step "1. Go to Settings → Users"
print_step "2. Click 'New User'"
print_step "3. Username: [admin username]"
print_step "4. Password: [strong password]"
print_step "5. Under 'Groups', check: ✓ admins"
print_step "6. Click 'Save'"
echo ""

print_info "Admin users will automatically have access to ALL desktop VMs"

wait_for_enter

print_section "Creating a regular user:"
print_step "1. Click 'New User' again"
print_step "2. Username: [user username]"
print_step "3. Password: [strong password]"
print_step "4. Under 'Groups', check: ✓ regular-users"
print_step "5. Click 'Save'"
echo ""

print_info "Regular users will only see desktop VMs you assign to them"

wait_for_enter

# Step 5: Assign Permissions
print_header "Step 5: Assign Desktop VM Permissions"

echo "Now assign which desktop VMs each user/group can access."
echo ""

print_section "Assigning access to admin group:"
print_step "1. Go to Settings → Connections"
print_step "2. Click on a connection (e.g., 'Marketing Desktop')"
print_step "3. Go to the 'Permissions' tab"
print_step "4. Under 'Group Permissions', add: admins"
print_step "5. Check: ✓ Read"
print_step "6. Click 'Save'"
print_step "7. Repeat for all other desktop VM connections"
echo ""

wait_for_enter

print_section "Assigning access to specific users:"
print_step "1. Go to Settings → Connections"
print_step "2. Click on a connection (e.g., 'Marketing Desktop')"
print_step "3. Go to the 'Permissions' tab"
print_step "4. Under 'User Permissions', add the username"
print_step "5. Check: ✓ Read"
print_step "6. Click 'Save'"
echo ""

print_info "Example permission structure:"
echo "  Marketing Desktop → marketing_team group + individual users"
echo "  Sales Desktop → sales_team group + individual users"
echo "  Development Desktop → dev_team group + individual users"
echo "  General Desktop → all regular-users group"

wait_for_enter

# Step 6: Test Access
print_header "Step 6: Test User Access"

echo "Test that users can access their assigned desktops."
echo ""

print_step "1. Log out of guacadmin account"
print_step "2. Log in as a regular user"
print_step "3. Verify you only see assigned desktop VMs"
print_step "4. Click on a desktop to connect"
print_step "5. Verify XRDP connection works"
print_step "6. Launch Chrome using the desktop shortcut"
print_step "7. Verify you're automatically logged into configured accounts"
echo ""

print_section "Testing concurrent access:"
print_step "1. Connect to a desktop VM as User A"
print_step "2. Open Chrome and start browsing"
print_step "3. From another computer/browser, log in as User B"
print_step "4. Connect to the SAME desktop VM"
print_step "5. Open Chrome"
print_step "6. Verify:"
echo "     • Both users are logged into same accounts"
echo "     • Both can browse independently"
echo "     • Tabs/history are separate"
echo "     • No interference between sessions"

wait_for_enter

# Step 7: Security Hardening
print_header "Step 7: Security Hardening (Recommended)"

echo "Additional security measures:"
echo ""

print_section "1. Disable default guacadmin account:"
print_step "• After creating new admin users, disable guacadmin"
print_step "• Settings → Users → guacadmin → uncheck 'Login enabled'"
echo ""

print_section "2. Enable session recording (optional):"
print_step "• Edit connection → Recording tab"
print_step "• Path: /record"
print_step "• Name: \${GUAC_USERNAME}-\${GUAC_DATE}-\${GUAC_TIME}"
echo ""

print_section "3. Set idle timeouts:"
print_step "• Edit /opt/guacamole/docker-compose.yml"
print_step "• Add environment variable:"
print_step "  GUACAMOLE_IDLE_TIMEOUT: 900"
print_step "• Restart: ./manage-guacamole.sh restart"
echo ""

print_section "4. Configure Cloudflare Tunnel (next phase):"
print_step "• Adds HTTPS encryption"
print_step "• Provides access control"
print_step "• Hides server IP"

wait_for_enter

# Summary
print_header "Configuration Complete!"

echo -e "${GREEN}Guacamole is now configured for multi-user access!${NC}"
echo ""
echo "What you've accomplished:"
echo "  ✓ Changed default administrator password"
echo "  ✓ Created user groups (admins, regular-users)"
echo "  ✓ Created RDP connections to desktop VMs"
echo "  ✓ Created user accounts"
echo "  ✓ Assigned desktop VM permissions"
echo "  ✓ Tested access and concurrent sessions"
echo ""

print_info "Next steps:"
echo "  1. Set up Cloudflare Tunnel for secure internet access"
echo "  2. Configure additional desktop VMs as needed"
echo "  3. Train users on accessing the system"
echo "  4. Set up regular backups (./manage-guacamole.sh backup)"
echo ""

print_warning "Maintenance reminders:"
echo "  • Regularly backup Guacamole database"
echo "  • Update Docker images periodically"
echo "  • Review user access permissions"
echo "  • Monitor system logs"
echo ""

echo "For help, see:"
echo "  • DEPLOYMENT-GUIDE.md"
echo "  • README-ADMIN.txt"
echo "  • ./manage-guacamole.sh help"
##### END_CONFIGURE_GUACAMOLE #####

##### BEGIN_SETUP_CLOUDFLARE_TUNNEL #####
#!/bin/bash

################################################################################
# CLOUDFLARE TUNNEL SETUP SCRIPT
#
# This script installs and configures Cloudflare Tunnel (cloudflared)
# to expose Guacamole to the internet securely.
#
# USAGE: sudo ./setup-cloudflare-tunnel.sh
#
# REQUIREMENTS:
# - Cloudflare account with a domain
# - Root/sudo access
# - Guacamole already installed and running
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/cloudflare-tunnel-setup.log"

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "Cloudflare Tunnel Setup"

print_warning "PREREQUISITES:"
echo "  • Cloudflare account (free or paid)"
echo "  • Domain added to Cloudflare"
echo "  • Guacamole running on port 8080"
echo ""

read -p "Do you have a Cloudflare account and domain ready? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    print_info "Please set up Cloudflare account and domain first"
    echo "Visit: https://dash.cloudflare.com/sign-up"
    exit 0
fi

# Install cloudflared
print_info "Installing cloudflared..."

# Add Cloudflare GPG key
mkdir -p /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflared.list

apt-get update >> "$LOG_FILE" 2>&1
apt-get install -y cloudflared >> "$LOG_FILE" 2>&1

print_success "cloudflared installed"

# Verify installation
if ! command -v cloudflared &> /dev/null; then
    print_error "cloudflared installation failed"
    exit 1
fi

CLOUDFLARED_VERSION=$(cloudflared --version | head -n1)
print_info "Installed: $CLOUDFLARED_VERSION"

# Authenticate with Cloudflare
print_header "Cloudflare Authentication"

echo "You need to authenticate cloudflared with your Cloudflare account."
echo "This will open a browser window where you'll log in."
echo ""

read -p "Press Enter to start authentication..."

cloudflared tunnel login

if [[ ! -f ~/.cloudflared/cert.pem ]]; then
    print_error "Authentication failed - cert.pem not found"
    exit 1
fi

print_success "Authentication successful"

# Create tunnel
print_header "Creating Cloudflare Tunnel"

echo "Enter a name for your tunnel (e.g., guacamole-tunnel):"
read -p "Tunnel name: " TUNNEL_NAME

if [[ -z "$TUNNEL_NAME" ]]; then
    TUNNEL_NAME="guacamole-tunnel"
    print_info "Using default name: $TUNNEL_NAME"
fi

cloudflared tunnel create "$TUNNEL_NAME" >> "$LOG_FILE" 2>&1

if [[ $? -eq 0 ]]; then
    print_success "Tunnel created: $TUNNEL_NAME"
else
    print_error "Failed to create tunnel"
    exit 1
fi

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
print_info "Tunnel ID: $TUNNEL_ID"

# Configure tunnel
print_header "Configuring Tunnel"

echo "Enter your domain/subdomain for Guacamole (e.g., desktop.example.com):"
read -p "Domain: " TUNNEL_DOMAIN

if [[ -z "$TUNNEL_DOMAIN" ]]; then
    print_error "Domain is required"
    exit 1
fi

# Create tunnel configuration
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_DOMAIN
    service: http://localhost:8080
  - service: http_status:404
EOF

print_success "Tunnel configuration created"

# Create DNS route
print_info "Creating DNS route..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$TUNNEL_DOMAIN" >> "$LOG_FILE" 2>&1

if [[ $? -eq 0 ]]; then
    print_success "DNS route created: $TUNNEL_DOMAIN → $TUNNEL_NAME"
else
    print_warning "DNS route creation may have failed - check manually"
fi

# Install as system service
print_header "Installing System Service"

cloudflared service install >> "$LOG_FILE" 2>&1
systemctl enable cloudflared >> "$LOG_FILE" 2>&1
systemctl start cloudflared >> "$LOG_FILE" 2>&1

sleep 3

if systemctl is-active --quiet cloudflared; then
    print_success "Cloudflare Tunnel service installed and running"
else
    print_error "Service failed to start"
    print_info "Check logs: journalctl -u cloudflared -n 50"
    exit 1
fi

print_header "Cloudflare Tunnel Setup Complete!"

echo ""
print_success "Guacamole is now accessible at: https://$TUNNEL_DOMAIN/guacamole/"
echo ""
print_info "Configuration summary:"
echo "  • Tunnel name: $TUNNEL_NAME"
echo "  • Tunnel ID: $TUNNEL_ID"
echo "  • Public URL: https://$TUNNEL_DOMAIN/guacamole/"
echo "  • Local service: http://localhost:8080"
echo "  • Service status: Active"
echo ""

print_warning "SECURITY RECOMMENDATIONS:"
echo "  1. Enable Cloudflare Access for additional authentication"
echo "  2. Configure firewall to block direct access to port 8080"
echo "  3. Enable Cloudflare WAF rules"
echo "  4. Set up rate limiting"
echo ""

print_info "Firewall configuration (optional but recommended):"
echo "  # Block external access to Guacamole port"
echo "  sudo ufw delete allow 8080/tcp"
echo "  sudo ufw allow from 127.0.0.1 to any port 8080"
echo ""

print_info "Useful commands:"
echo "  • Check tunnel status: cloudflared tunnel info $TUNNEL_NAME"
echo "  • View tunnel logs: journalctl -u cloudflared -f"
echo "  • Stop tunnel: sudo systemctl stop cloudflared"
echo "  • Start tunnel: sudo systemctl start cloudflared"
echo "  • Restart tunnel: sudo systemctl restart cloudflared"
echo ""

print_success "Setup complete! Test by accessing: https://$TUNNEL_DOMAIN/guacamole/"
##### END_SETUP_CLOUDFLARE_TUNNEL #####

##### BEGIN_README_DESKTOP #####
================================================================================
                    DESKTOP VM USER GUIDE
================================================================================

Welcome to the Remote Desktop System!

This document explains how to use the shared desktop environment with
pre-configured Chrome browser sessions.

================================================================================
ACCESSING THE DESKTOP
================================================================================

1. Open your web browser and navigate to:
   https://your-domain.com/guacamole/

2. Log in with your provided username and password

3. You'll see a list of desktop VMs you have access to

4. Click on a desktop to connect

5. The remote desktop will load in your browser

================================================================================
USING CHROME BROWSER
================================================================================

LAUNCHING CHROME:
-----------------
You'll find a "Chrome (Shared Config)" icon on the desktop.
Double-click it to launch Chrome with pre-configured accounts.

WHAT'S PRE-CONFIGURED:
---------------------
• Gmail/Google Workspace accounts
• Salesforce
• Slack
• Other business applications
• Browser extensions
• Bookmarks

YOU ALREADY LOGGED IN:
---------------------
When you open Chrome, you'll be automatically logged into all configured
accounts. No need to enter passwords!

YOUR SESSION IS PRIVATE:
-----------------------
• Your tabs are yours alone - other users can't see them
• Your browsing history is separate
• Your downloads are isolated
• Your current work is private

SHARED ACROSS SESSIONS:
----------------------
• Account logins (Gmail, Salesforce, etc.)
• Bookmarks
• Saved passwords
• Browser extensions
• Preferences

CONCURRENT ACCESS:
-----------------
Multiple users can work on the SAME desktop VM at the same time!

Example:
• You open Chrome and access Gmail
• A coworker also connects to the same desktop
• They also open Chrome and access the SAME Gmail account
• You both work independently without conflicts

================================================================================
BEST PRACTICES
================================================================================

DO:
---
• Use the desktop as you normally would
• Open Chrome from the desktop shortcut
• Save your important work frequently
• Log out when finished for the day

DON'T:
------
• Don't try to log out of shared accounts (Gmail, Salesforce, etc.)
• Don't change browser settings that affect other users
• Don't delete shared bookmarks
• Don't uninstall shared extensions

================================================================================
KEYBOARD SHORTCUTS
================================================================================

Within the remote desktop:
• Ctrl+C / Ctrl+V: Copy and paste
• Alt+Tab: Switch between windows
• Windows Key: Open applications menu

Guacamole special keys:
• Ctrl+Alt+Shift: Open Guacamole menu
  - From here you can:
    - Copy/paste between your local computer and remote desktop
    - Adjust display settings
    - Disconnect session

================================================================================
TROUBLESHOOTING
================================================================================

CHROME WON'T START:
------------------
• Make sure you're using the "Chrome (Shared Config)" desktop shortcut
• If Chrome crashes, close it completely and restart
• Contact administrator if problems persist

NOT LOGGED INTO ACCOUNTS:
------------------------
• This usually means the master profile needs updating
• Contact your administrator
• They will need to refresh the account logins

SLOW PERFORMANCE:
----------------
• Check your internet connection
• Close unused applications on the remote desktop
• Contact administrator if issue persists

CAN'T ACCESS A DESKTOP:
----------------------
• Verify you have permission to access that desktop
• Contact your administrator to request access

================================================================================
FILE MANAGEMENT
================================================================================

UPLOADING FILES:
---------------
1. Press Ctrl+Alt+Shift to open Guacamole menu
2. Click "Devices"
3. Enable file sharing
4. Drag files from your computer to the remote desktop

DOWNLOADING FILES:
-----------------
1. Save file to the remote desktop
2. Press Ctrl+Alt+Shift
3. Click "Shared Drive"
4. Download files from there to your local computer

================================================================================
SUPPORT
================================================================================

For technical support, contact your system administrator.

Include the following information:
• Your username
• Which desktop VM you're accessing
• Description of the issue
• Any error messages

================================================================================
SECURITY REMINDERS
================================================================================

• Never share your login credentials
• Always log out when finished
• Don't save sensitive personal data on shared desktops
• Report any suspicious activity to your administrator
• Use strong, unique passwords

================================================================================

Thank you for using the Remote Desktop System!

================================================================================
##### END_README_DESKTOP #####

##### BEGIN_README_ADMIN #####
================================================================================
                    ADMINISTRATOR GUIDE
================================================================================

This guide covers system maintenance, troubleshooting, and common
administrative tasks for the multi-user remote desktop system.

================================================================================
SYSTEM ARCHITECTURE
================================================================================

COMPONENTS:
-----------
1. Guacamole Server (Gateway)
   - Web-based remote access
   - User authentication & authorization
   - Connection broker
   - Location: /opt/guacamole

2. Desktop VMs (Ubuntu Desktop + XRDP)
   - Host user sessions
   - Shared Chrome configuration
   - Multiple concurrent connections
   - User: shared-desktop

3. Cloudflare Tunnel
   - Secure internet access
   - HTTPS encryption
   - DDoS protection

================================================================================
DAILY MAINTENANCE TASKS
================================================================================

CHECK SYSTEM STATUS:
-------------------
# Check Guacamole services
cd /opt/guacamole
./manage-guacamole.sh status

# Check Cloudflare Tunnel
sudo systemctl status cloudflared

# Check desktop VM XRDP service (on each VM)
sudo systemctl status xrdp

MONITOR LOGS:
------------
# Guacamole logs
./manage-guacamole.sh logs

# Cloudflare Tunnel logs
sudo journalctl -u cloudflared -f

# XRDP logs (on desktop VMs)
tail -f /var/log/xrdp.log

# Chrome session logs (on desktop VMs)
tail -f /var/log/chrome-sessions/*.log

BACKUP DATABASE:
---------------
# Backup Guacamole configuration
cd /opt/guacamole
./manage-guacamole.sh backup

# Automated daily backups (recommended):
sudo crontab -e
# Add: 0 2 * * * /opt/guacamole/manage-guacamole.sh backup

================================================================================
USER MANAGEMENT
================================================================================

ADD NEW USER:
------------
1. Log into Guacamole as admin
2. Settings → Users → New User
3. Set username and password
4. Assign to appropriate group (admins or regular-users)
5. Go to Settings → Connections
6. For each desktop VM they need access to:
   - Click connection → Permissions tab
   - Add user → Check "Read"

REMOVE USER:
-----------
1. Settings → Users
2. Click username
3. Uncheck "Login enabled" (soft delete)
   OR
4. Delete user (hard delete - loses history)

RESET USER PASSWORD:
-------------------
1. Settings → Users → [username]
2. Enter new password
3. Save

CHANGE USER PERMISSIONS:
-----------------------
1. Settings → Connections → [Desktop VM]
2. Permissions tab
3. Add/remove users
4. Check/uncheck "Read" permission

================================================================================
DESKTOP VM MANAGEMENT
================================================================================

ADD NEW DESKTOP VM:
------------------
1. Create new VM in Proxmox
   - 4 CPU cores minimum
   - 8GB RAM minimum
   - 50GB disk minimum

2. Install Ubuntu 22.04 Desktop

3. Run setup script:
   sudo ./setup-desktop-vm.sh

4. Copy Chrome scripts:
   sudo cp launch-chrome.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/launch-chrome.sh
   cp setup-chrome-master.sh /home/shared-desktop/
   sudo cp cleanup-chrome-sessions.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/cleanup-chrome-sessions.sh

5. Configure master Chrome profile:
   su - shared-desktop
   ./setup-chrome-master.sh
   # Log into all required accounts

6. Add connection in Guacamole:
   - Settings → Connections → New Connection
   - Name: [Descriptive name]
   - Protocol: RDP
   - Hostname: [VM IP]
   - Username: shared-desktop
   - Password: [password]

7. Assign permissions to users/groups

CLONE DESKTOP VM:
----------------
(After one VM is fully configured)

1. In Proxmox, right-click VM → Clone
2. Choose "Full Clone"
3. Give it a new VM ID and name
4. Start the cloned VM
5. Change hostname:
   sudo hostnamectl set-hostname new-desktop-name
6. Change IP address (if using static IPs)
7. Add connection in Guacamole with new IP

UPDATE MASTER CHROME PROFILE:
-----------------------------
(When you need to add new accounts or change configurations)

1. Connect to desktop VM as shared-desktop
2. Run: ./setup-chrome-master.sh
3. Log into new accounts or make changes
4. Close Chrome
5. Changes will apply to all new sessions

CLEAN UP OLD CHROME SESSIONS:
-----------------------------
# Manual cleanup (on each desktop VM)
sudo /usr/local/bin/cleanup-chrome-sessions.sh

# View what would be deleted (dry run)
sudo /usr/local/bin/cleanup-chrome-sessions.sh --dry-run

# Cleanup sessions older than 3 days
sudo /usr/local/bin/cleanup-chrome-sessions.sh --days 3

# Automated cleanup (recommended)
sudo crontab -e
# Add: 0 3 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 7

================================================================================
GUACAMOLE MANAGEMENT
================================================================================

START/STOP/RESTART:
------------------
cd /opt/guacamole
./manage-guacamole.sh start
./manage-guacamole.sh stop
./manage-guacamole.sh restart

BACKUP & RESTORE:
----------------
# Create backup
./manage-guacamole.sh backup

# Restore from backup
./manage-guacamole.sh restore

UPDATE GUACAMOLE:
----------------
# Updates to latest version
./manage-guacamole.sh update

VIEW LOGS:
---------
./manage-guacamole.sh logs

CHECK STATUS:
------------
./manage-guacamole.sh status

================================================================================
TROUBLESHOOTING
================================================================================

PROBLEM: User can't connect to desktop VM
SOLUTION:
---------
1. Verify VM is running (in Proxmox)
2. Test XRDP: telnet [VM-IP] 3389
3. Check user has permission in Guacamole
4. Check Guacamole connection settings
5. Verify shared-desktop password is correct
6. Check XRDP logs on desktop VM: /var/log/xrdp.log

PROBLEM: Chrome not launching or not logged in
SOLUTION:
---------
1. Check if master profile exists:
   ls -la /opt/chrome-master-profile/Default/
2. Verify launch script is executable:
   ls -l /usr/local/bin/launch-chrome.sh
3. Check Chrome session logs:
   tail -f /var/log/chrome-sessions/*.log
4. Re-run master profile setup:
   su - shared-desktop
   ./setup-chrome-master.sh
5. Restart XRDP:
   sudo systemctl restart xrdp

PROBLEM: Chrome profiles conflict (locking issues)
SOLUTION:
---------
1. Each session should have unique profile directory
2. Check session directories:
   ls -la /opt/chrome-sessions/
3. Clean up old sessions:
   sudo /usr/local/bin/cleanup-chrome-sessions.sh
4. Verify launch script is creating unique session IDs
5. Check for zombie Chrome processes:
   ps aux | grep chrome

PROBLEM: Guacamole won't start
SOLUTION:
---------
1. Check Docker status:
   sudo systemctl status docker
2. Check container status:
   docker ps -a
3. Check logs:
   cd /opt/guacamole
   ./manage-guacamole.sh logs
4. Restart services:
   ./manage-guacamole.sh restart
5. Check database connection:
   docker exec -it guacamole-postgres psql -U guacamole_user -d guacamole_db

PROBLEM: Cloudflare Tunnel not working
SOLUTION:
---------
1. Check service status:
   sudo systemctl status cloudflared
2. Check tunnel status:
   cloudflared tunnel list
3. View logs:
   sudo journalctl -u cloudflared -n 50
4. Restart service:
   sudo systemctl restart cloudflared
5. Verify DNS settings in Cloudflare dashboard

PROBLEM: Slow performance
SOLUTION:
---------
1. Check CPU/RAM usage on desktop VMs
2. Reduce concurrent sessions per VM
3. Optimize XRDP settings:
   - Edit /etc/xrdp/xrdp.ini
   - Increase max_bpp or adjust compression
4. Check network bandwidth
5. Add more desktop VMs to distribute load

PROBLEM: Too many Chrome sessions filling disk
SOLUTION:
---------
1. Run cleanup script immediately:
   sudo /usr/local/bin/cleanup-chrome-sessions.sh --days 1
2. Check disk usage:
   du -sh /opt/chrome-sessions/*
3. Set up automated cleanup (if not already):
   sudo crontab -e
   0 3 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 3
4. Consider reducing cleanup days threshold
5. Add monitoring for disk space

================================================================================
SECURITY HARDENING
================================================================================

FIREWALL CONFIGURATION:
----------------------
# On Guacamole server (after Cloudflare Tunnel setup)
sudo ufw delete allow 8080/tcp
sudo ufw allow from 127.0.0.1 to any port 8080

# On Desktop VMs
sudo ufw allow from [Guacamole-IP] to any port 3389
sudo ufw deny 3389/tcp  # Block from elsewhere

REGULAR UPDATES:
---------------
# Update all systems monthly
sudo apt update && sudo apt upgrade -y

# Update Guacamole
cd /opt/guacamole
./manage-guacamole.sh update

# Update Chrome on desktop VMs
sudo apt update && sudo apt upgrade google-chrome-stable

ENABLE CLOUDFLARE ACCESS:
------------------------
1. Go to Cloudflare Zero Trust dashboard
2. Create Access application for your domain
3. Add authentication methods (Google, Microsoft, etc.)
4. Require MFA for admin users

MONITOR AUTHENTICATION LOGS:
---------------------------
# Guacamole authentication attempts
docker exec guacamole cat /var/log/syslog | grep guac

# Failed XRDP logins (on desktop VMs)
grep "failed" /var/log/auth.log

SESSION RECORDING (Optional):
----------------------------
1. Edit desktop connection in Guacamole
2. Go to "Recording" tab
3. Set recording path: /record
4. Set naming: ${GUAC_USERNAME}-${GUAC_DATE}-${GUAC_TIME}
5. Recordings stored in Docker volume: guacd-record

================================================================================
MONITORING & ALERTS
================================================================================

DISK SPACE MONITORING:
---------------------
# Check Guacamole server
df -h /opt/guacamole
df -h /var/lib/docker

# Check desktop VMs
df -h /opt/chrome-sessions
df -h /opt/chrome-master-profile

RESOURCE MONITORING:
-------------------
# CPU and memory usage
htop

# Docker container resources
docker stats

# Per-user XRDP sessions
ps aux | grep xrdp

AUTOMATED MONITORING:
--------------------
# Set up simple email alerts (example with cron + mail)
# Add to crontab:
0 */6 * * * df -h | grep -E '9[0-9]%|100%' && echo "Disk space critical" | mail -s "Alert: Disk Space" admin@example.com

================================================================================
BACKUP & DISASTER RECOVERY
================================================================================

WHAT TO BACKUP:
--------------
1. Guacamole database (automated with manage script)
2. Guacamole configuration: /opt/guacamole/
3. Chrome master profiles: /opt/chrome-master-profile/ (on each VM)
4. Cloudflare tunnel config: ~/.cloudflared/

BACKUP SCHEDULE:
---------------
• Daily: Guacamole database
• Weekly: Full system snapshots (Proxmox)
• Monthly: Chrome master profiles
• After changes: Configuration files

DISASTER RECOVERY:
-----------------
1. Restore Proxmox VMs from snapshots
2. Restore Guacamole database:
   cd /opt/guacamole
   ./manage-guacamole.sh restore
3. Restore Chrome master profiles (if needed)
4. Verify all services are running
5. Test user connectivity

================================================================================
PERFORMANCE TUNING
================================================================================

XRDP OPTIMIZATION:
-----------------
Edit /etc/xrdp/xrdp.ini:

tcp_nodelay=true
tcp_keepalive=true
max_bpp=32
use_fastpath=both

CHROME OPTIMIZATION:
-------------------
Add flags to launch-chrome.sh:

--disable-gpu-vsync
--disable-features=VizDisplayCompositor
--enable-features=VaapiVideoDecoder

DOCKER OPTIMIZATION:
-------------------
Edit /opt/guacamole/docker-compose.yml:

Add to guacamole service:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G

================================================================================
USEFUL COMMANDS REFERENCE
================================================================================

GUACAMOLE:
---------
./manage-guacamole.sh status
./manage-guacamole.sh logs
./manage-guacamole.sh backup
./manage-guacamole.sh restart

DOCKER:
-------
docker ps
docker logs guacamole
docker exec -it guacamole bash
docker system prune  # Clean up unused containers/images

XRDP (on desktop VMs):
---------------------
sudo systemctl status xrdp
sudo systemctl restart xrdp
tail -f /var/log/xrdp.log

CHROME SESSIONS (on desktop VMs):
---------------------------------
ls -la /opt/chrome-sessions/
du -sh /opt/chrome-sessions/*
sudo /usr/local/bin/cleanup-chrome-sessions.sh

CLOUDFLARE TUNNEL:
-----------------
cloudflared tunnel list
cloudflared tunnel info [tunnel-name]
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f

================================================================================
CONTACT & SUPPORT
================================================================================

For issues not covered in this guide:
• Check DEPLOYMENT-GUIDE.md for detailed procedures
• Review component logs for error messages
• Consult Guacamole documentation: https://guacamole.apache.org/doc/
• Cloudflare Tunnel docs: https://developers.cloudflare.com/cloudflare-one/

================================================================================
##### END_README_ADMIN #####

##### BEGIN_DEPLOYMENT_GUIDE #####
# Multi-User Remote Desktop System - Deployment Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Proxmox VM Creation](#phase-1-proxmox-vm-creation)
4. [Phase 2: Desktop VM Template Setup](#phase-2-desktop-vm-template-setup)
5. [Phase 3: Guacamole Installation](#phase-3-guacamole-installation)
6. [Phase 4: Cloudflare Tunnel Setup](#phase-4-cloudflare-tunnel-setup)
7. [Phase 5: Testing & Validation](#phase-5-testing--validation)
8. [Phase 6: Maintenance Procedures](#phase-6-maintenance-procedures)
9. [Troubleshooting](#troubleshooting)

---

## Introduction

This deployment guide walks you through setting up a complete multi-user remote desktop environment with the following capabilities:

- **Web-based access** via Apache Guacamole
- **Concurrent user sessions** on the same desktop VM
- **Shared browser configuration** with isolated browsing sessions
- **Secure internet access** via Cloudflare Tunnel
- **Centralized user management**

### Architecture Overview

```
Internet Users
      ↓
Cloudflare Tunnel (HTTPS)
      ↓
Guacamole Server (Authentication & Connection Broker)
      ↓
Desktop VMs (XRDP) → Shared Chrome Config + Isolated Sessions
```

### Expected Timeline

- Phase 1 (VM Creation): 1-2 hours
- Phase 2 (Desktop Template): 2-3 hours
- Phase 3 (Guacamole): 1-2 hours
- Phase 4 (Cloudflare): 30 minutes
- Phase 5 (Testing): 1 hour
- **Total**: 5-8 hours for initial setup

---

## Prerequisites

### Required Resources

**Proxmox Host:**
- Sufficient CPU cores (4+ per VM)
- Sufficient RAM (16GB+ available)
- Sufficient storage (100GB+ per desktop VM)

**Network:**
- Static IP or DHCP reservations for VMs
- Internal network connectivity between Guacamole and Desktop VMs
- Internet access for all VMs

**Accounts:**
- Cloudflare account (free or paid)
- Domain managed by Cloudflare
- Email accounts/services to configure in Chrome

### Required Knowledge

- Basic Linux administration
- Proxmox VM management
- Basic networking concepts
- Web browser usage

---

## Phase 1: Proxmox VM Creation

### 1.1 Create Guacamole Server VM

**Specifications:**
- **OS**: Ubuntu 22.04 LTS Server
- **CPU**: 2-4 cores
- **RAM**: 4-8 GB
- **Disk**: 32 GB
- **Network**: Bridged or NAT

**Steps:**

1. In Proxmox, click "Create VM"
2. Configure VM:
   - VM ID: (e.g., 100)
   - Name: guacamole-server
   - ISO: ubuntu-22.04-live-server-amd64.iso
3. System settings: Leave defaults (BIOS, q35 machine)
4. Disks: 32GB, VirtIO SCSI
5. CPU: 2-4 cores
6. Memory: 4096-8192 MB
7. Network: VirtIO, vmbr0 (or your bridge)
8. Start VM and install Ubuntu Server
   - Choose "Ubuntu Server (minimized)" if available
   - Configure network (DHCP or static IP)
   - Create admin user
   - Install OpenSSH server
   - No additional packages needed

9. After installation, note the IP address:
   ```bash
   ip addr show
   ```

### 1.2 Create Desktop VM Template

**Specifications:**
- **OS**: Ubuntu 22.04 LTS Desktop
- **CPU**: 4-6 cores
- **RAM**: 8-16 GB
- **Disk**: 50-100 GB
- **Network**: Bridged or NAT

**Steps:**

1. Create VM in Proxmox:
   - VM ID: (e.g., 200)
   - Name: desktop-template
   - ISO: ubuntu-22.04-desktop-amd64.iso
   - System: BIOS, q35
   - Disk: 50-100GB, VirtIO SCSI
   - CPU: 4-6 cores
   - Memory: 8192-16384 MB
   - Network: VirtIO, vmbr0

2. Start VM and install Ubuntu Desktop:
   - Choose "Minimal installation"
   - Download updates during installation
   - Install third-party software
   - Create user: `shared-desktop` (remember password!)
   - Set hostname: desktop-template

3. After installation, update system:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo reboot
   ```

4. Install Proxmox guest agent (optional but recommended):
   ```bash
   sudo apt install qemu-guest-agent
   sudo systemctl enable qemu-guest-agent
   sudo systemctl start qemu-guest-agent
   ```

5. Note the IP address for later use

---

## Phase 2: Desktop VM Template Setup

### 2.1 Extract Deployment Scripts

On your local machine, save the main deployment package and extract scripts:

```bash
# Save this entire file as: multi-user-desktop-deployment.sh
chmod +x multi-user-desktop-deployment.sh
./multi-user-desktop-deployment.sh
```

This will create a `remote-desktop-deployment/` directory with all scripts.

### 2.2 Transfer Scripts to Desktop VM

From your local machine:

```bash
cd remote-desktop-deployment
scp setup-desktop-vm.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp launch-chrome.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp setup-chrome-master.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp cleanup-chrome-sessions.sh shared-desktop@[DESKTOP-VM-IP]:~/
```

### 2.3 Run Desktop VM Setup

SSH into the desktop VM:

```bash
ssh shared-desktop@[DESKTOP-VM-IP]
```

Run the setup script:

```bash
chmod +x setup-desktop-vm.sh
sudo ./setup-desktop-vm.sh
```

**Expected output:**
- System packages updated
- XRDP installed and configured
- Google Chrome installed
- Directory structure created
- Firewall configured

**Verification:**
```bash
# Check XRDP is running
sudo systemctl status xrdp

# Check Chrome is installed
google-chrome --version

# Check directories exist
ls -la /opt/chrome-master-profile
ls -la /opt/chrome-sessions
```

### 2.4 Install Chrome Scripts

```bash
# Install launch script
sudo cp launch-chrome.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/launch-chrome.sh

# Install cleanup script
sudo cp cleanup-chrome-sessions.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/cleanup-chrome-sessions.sh

# Verify installation
ls -l /usr/local/bin/launch-chrome.sh
ls -l /usr/local/bin/cleanup-chrome-sessions.sh
```

### 2.5 Create Chrome Desktop Shortcut

```bash
# Create desktop shortcut for shared user
cat > ~/Desktop/Chrome-Shared.desktop <<'EOF'
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

# Make executable
chmod +x ~/Desktop/Chrome-Shared.desktop

# Trust the desktop file
gio set ~/Desktop/Chrome-Shared.desktop metadata::trusted true
```

### 2.6 Configure Master Chrome Profile

This is where you log into all the accounts that will be shared across users.

```bash
# Run the master profile setup script