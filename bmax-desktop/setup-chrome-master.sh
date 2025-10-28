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
