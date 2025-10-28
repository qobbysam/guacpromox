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

# Check if running as root
SHARED_USER="shared-desktop"
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Warning: Running as root${NC}"
    echo -e "${YELLOW}Chrome cannot run as root without --no-sandbox flag.${NC}"
    echo ""
    echo -e "${BLUE}Switching to '$SHARED_USER' user to launch Chrome...${NC}"
    
    # Check if shared-desktop user exists
    if ! id "$SHARED_USER" &>/dev/null; then
        echo -e "${RED}✗ User '$SHARED_USER' does not exist${NC}"
        echo -e "${RED}  Please run setup-desktop-vm.sh first${NC}"
        exit 1
    fi
    
    # Switch to shared-desktop user and re-run script
    # Get script path (portable method)
    if [[ -L "$0" ]]; then
        SCRIPT_PATH="$(readlink "$0")"
        # If readlink doesn't give absolute path, prepend current dir
        if [[ "$SCRIPT_PATH" != /* ]]; then
            SCRIPT_PATH="$(dirname "$0")/$SCRIPT_PATH"
        fi
    else
        SCRIPT_PATH="$0"
    fi
    # Convert to absolute path if relative
    if [[ "$SCRIPT_PATH" != /* ]]; then
        SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$SCRIPT_PATH")"
    fi
    
    echo -e "${BLUE}Executing: sudo -u $SHARED_USER $SCRIPT_PATH${NC}"
    exec sudo -u "$SHARED_USER" "$SCRIPT_PATH"
    exit $?
fi

# Check if running as shared-desktop user
if [[ "$USER" != "$SHARED_USER" ]]; then
    echo -e "${YELLOW}⚠ Warning: This script should be run as '$SHARED_USER' user${NC}"
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

# Fix permissions and clean up lock files
echo -e "${BLUE}ℹ Checking and fixing permissions...${NC}"
CURRENT_USER=$(whoami)

# Check current ownership
CURRENT_OWNER=$(stat -c '%U' "$CHROME_MASTER_PROFILE" 2>/dev/null || echo "unknown")
if [[ "$CURRENT_OWNER" != "$CURRENT_USER" ]]; then
    echo -e "${YELLOW}⚠ Directory owned by $CURRENT_OWNER, fixing ownership...${NC}"
    if [[ $EUID -eq 0 ]]; then
        chown -R "$CURRENT_USER":"$CURRENT_USER" "$CHROME_MASTER_PROFILE"
        echo -e "${GREEN}✓ Ownership fixed to $CURRENT_USER${NC}"
    else
        # Try with sudo if we have permission
        if sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$CHROME_MASTER_PROFILE" 2>/dev/null; then
            echo -e "${GREEN}✓ Ownership fixed to $CURRENT_USER (using sudo)${NC}"
        else
            echo -e "${RED}✗ Cannot fix ownership. Please run: sudo chown -R $CURRENT_USER:$CURRENT_USER $CHROME_MASTER_PROFILE${NC}"
            exit 1
        fi
    fi
fi

# Ensure directory is writable
chmod 755 "$CHROME_MASTER_PROFILE" 2>/dev/null || sudo chmod 755 "$CHROME_MASTER_PROFILE" 2>/dev/null

# Clean up any existing Chrome lock files that might prevent startup
LOCK_FILES=(
    "$CHROME_MASTER_PROFILE/SingletonLock"
    "$CHROME_MASTER_PROFILE/SingletonCookie"
    "$CHROME_MASTER_PROFILE/SingletonSocket"
)

for lock_file in "${LOCK_FILES[@]}"; do
    if [[ -f "$lock_file" ]] || [[ -S "$lock_file" ]]; then
        echo -e "${BLUE}ℹ Removing existing lock file: $(basename "$lock_file")${NC}"
        rm -f "$lock_file" 2>/dev/null || sudo rm -f "$lock_file" 2>/dev/null
    fi
done

# Ensure profile subdirectories are writable (if they exist)
if [[ -d "$CHROME_MASTER_PROFILE" ]]; then
    chmod -R u+w "$CHROME_MASTER_PROFILE" 2>/dev/null || sudo chmod -R u+w "$CHROME_MASTER_PROFILE" 2>/dev/null
fi

echo -e "${GREEN}✓ Permissions verified and lock files cleaned${NC}"

echo ""
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

# Set DISPLAY if not set (needed for GUI applications)
if [[ -z "$DISPLAY" ]]; then
    export DISPLAY=:0
    echo -e "${BLUE}Setting DISPLAY=$DISPLAY${NC}"
fi

# Launch Chrome with master profile
# Use no-sandbox if running as root (shouldn't happen after fix above, but safety check)
CHROME_FLAGS=(
    "--user-data-dir=$CHROME_MASTER_PROFILE"
    "--no-first-run"
    "--no-default-browser-check"
)

# Only add --no-sandbox if absolutely necessary (not recommended for security)
# But since we handle root above, this shouldn't be needed
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Adding --no-sandbox flag (not recommended for security)${NC}"
    CHROME_FLAGS+=("--no-sandbox")
fi

# Launch Chrome
if ! "$CHROME_BIN" "${CHROME_FLAGS[@]}"; then
    CHROME_EXIT_CODE=$?
    echo ""
    echo -e "${RED}✗ Chrome exited with error code: $CHROME_EXIT_CODE${NC}"
    
    if [[ $CHROME_EXIT_CODE -eq 1 ]] && [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}This error often occurs when running Chrome as root.${NC}"
        echo -e "${YELLOW}Please run this script as '$SHARED_USER' user instead:${NC}"
        echo -e "${BLUE}  su - $SHARED_USER${NC}"
        echo -e "${BLUE}  ./setup-chrome-master.sh${NC}"
    fi
    
    exit $CHROME_EXIT_CODE
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Master Profile Configuration${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Wait a moment for Chrome to fully close and write profile data
sleep 2

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
