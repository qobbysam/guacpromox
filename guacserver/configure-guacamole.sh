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

# Summary
print_header "Configuration Complete!"

echo -e "${GREEN}Basic Guacamole configuration is complete!${NC}"
echo ""
echo "For detailed configuration steps including:"
echo "  • Creating user groups"
echo "  • Creating RDP connections"
echo "  • Assigning permissions"
echo "  • Testing concurrent access"
echo ""
echo "See README-ADMIN.txt for complete instructions."

exit 0
