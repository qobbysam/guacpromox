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
