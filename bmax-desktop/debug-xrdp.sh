#!/bin/bash

################################################################################
# XRDP DEBUG SCRIPT
# 
# This script diagnoses XRDP desktop issues by checking:
# - XFCE4 installation
# - startwm.sh configuration
# - X server status
# - Session logs
# - Permissions
#
# USAGE: sudo ./debug-xrdp.sh
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header "XRDP Diagnostic Tool"

# 1. Check XFCE4 installation
print_header "1. Checking XFCE4 Installation"
if dpkg -l | grep -q "^ii.*xfce4[^-]"; then
    print_success "XFCE4 is installed"
    echo ""
    echo "Installed XFCE4 packages:"
    dpkg -l | grep xfce4 | head -10
else
    print_error "XFCE4 is NOT installed"
    echo ""
    print_warning "Run: sudo ./fix-xrdp-desktop.sh to install XFCE4"
fi

# Check for XFCE4 binaries
echo ""
print_info "Checking for XFCE4 binaries:"
if command -v startxfce4 >/dev/null 2>&1; then
    print_success "startxfce4 found: $(which startxfce4)"
else
    print_error "startxfce4 NOT found"
fi

if command -v xfce4-session >/dev/null 2>&1; then
    print_success "xfce4-session found: $(which xfce4-session)"
else
    print_error "xfce4-session NOT found"
fi

# 2. Check startwm.sh configuration
print_header "2. Checking startwm.sh Configuration"
if [ -f /etc/xrdp/startwm.sh ]; then
    print_success "startwm.sh exists"
    echo ""
    print_info "File permissions:"
    ls -la /etc/xrdp/startwm.sh
    echo ""
    print_info "File contents:"
    echo "---"
    head -20 /etc/xrdp/startwm.sh
    echo "---"
    echo ""
    
    if grep -q "xfce" /etc/xrdp/startwm.sh; then
        print_success "startwm.sh references XFCE"
    else
        print_error "startwm.sh does NOT reference XFCE"
    fi
else
    print_error "startwm.sh does NOT exist"
fi

# 3. Check X server
print_header "3. Checking X Server"
if command -v Xorg >/dev/null 2>&1; then
    print_success "Xorg found: $(which Xorg)"
    Xorg -version 2>&1 | head -3
else
    print_error "Xorg NOT found"
fi

# Check X server packages
echo ""
print_info "X server packages:"
dpkg -l | grep -E "(xserver-xorg|xorg-core)" | head -5

# 4. Check XRDP services
print_header "4. Checking XRDP Services"
if systemctl is-active --quiet xrdp; then
    print_success "xrdp service is running"
else
    print_error "xrdp service is NOT running"
fi

if systemctl is-active --quiet xrdp-sesman; then
    print_success "xrdp-sesman service is running"
else
    print_error "xrdp-sesman service is NOT running"
fi

echo ""
print_info "Service status:"
systemctl status xrdp --no-pager -l | head -10
echo ""
systemctl status xrdp-sesman --no-pager -l | head -10

# 5. Check recent session logs
print_header "5. Recent Session Logs"
echo ""
print_info "Last 20 lines of xrdp-sesman log:"
if [ -f /var/log/xrdp-sesman.log ]; then
    tail -20 /var/log/xrdp-sesman.log
elif [ -f /var/log/xrdp/xrdp-sesman.log ]; then
    tail -20 /var/log/xrdp/xrdp-sesman.log
else
    print_warning "xrdp-sesman.log not found"
    echo "Checking journalctl:"
    journalctl -u xrdp-sesman -n 20 --no-pager
fi

echo ""
print_info "Last 10 lines of xrdp log:"
if [ -f /var/log/xrdp/xrdp.log ]; then
    tail -10 /var/log/xrdp/xrdp.log
else
    print_warning "xrdp.log not found"
fi

# 6. Check directories and permissions
print_header "6. Checking Directories and Permissions"
echo ""
print_info "XRDP directories:"
ls -la /var/log/xrdp 2>/dev/null || print_error "/var/log/xrdp does not exist"
ls -la /run/xrdp 2>/dev/null || print_error "/run/xrdp does not exist"

echo ""
print_info "X11 socket directories:"
ls -la /tmp/.X11-unix/ 2>/dev/null | head -5 || print_warning "/tmp/.X11-unix/ empty or missing"
ls -la /tmp/.ICE-unix/ 2>/dev/null | head -5 || print_warning "/tmp/.ICE-unix/ empty or missing"

# 7. Check user configuration
print_header "7. Checking User Configuration"
SHARED_USER="shared-desktop"
if id "$SHARED_USER" &>/dev/null; then
    print_success "User $SHARED_USER exists"
    echo ""
    print_info "User info:"
    id "$SHARED_USER"
    echo ""
    print_info "Home directory:"
    ls -la /home/$SHARED_USER/ 2>/dev/null | head -10 || print_warning "Cannot access home directory"
    
    echo ""
    print_info "Checking user's .xsession-errors:"
    if [ -f /home/$SHARED_USER/.xsession-errors ]; then
        tail -20 /home/$SHARED_USER/.xsession-errors
    else
        print_warning ".xsession-errors not found"
    fi
else
    print_error "User $SHARED_USER does NOT exist"
fi

# 8. Check for Xorg session logs
print_header "8. Checking for Xorg Session Logs"
XORG_LOGS=$(find /home/$SHARED_USER -name ".xorgxrdp.*.log" -o -name ".Xorg*.log" 2>/dev/null | head -3)
if [ -n "$XORG_LOGS" ]; then
    print_info "Found Xorg logs:"
    for log in $XORG_LOGS; do
        echo "  $log"
        tail -15 "$log" | grep -i error || true
    done
else
    print_warning "No Xorg session logs found"
fi

# 9. Test startwm.sh manually (dry run check)
print_header "9. Testing startwm.sh Syntax"
if [ -f /etc/xrdp/startwm.sh ]; then
    if bash -n /etc/xrdp/startwm.sh 2>&1; then
        print_success "startwm.sh syntax is valid"
    else
        print_error "startwm.sh has syntax errors:"
        bash -n /etc/xrdp/startwm.sh
    fi
fi

# 10. Check for common issues
print_header "10. Common Issues Check"
echo ""

# Check if dbus is running
if pgrep -x dbus-daemon >/dev/null; then
    print_success "dbus-daemon is running"
else
    print_warning "dbus-daemon is NOT running (may cause issues)"
fi

# Check polkit
if [ -f /etc/polkit-1/localauthority/50-local.d/02-allow-colord.pkla ]; then
    print_success "Polkit configuration exists"
else
    print_warning "Polkit configuration missing (may cause authentication errors)"
fi

# Check XDG_RUNTIME_DIR setup
if grep -q "XDG_RUNTIME_DIR" /etc/xrdp/startwm.sh; then
    print_success "XDG_RUNTIME_DIR is configured in startwm.sh"
else
    print_warning "XDG_RUNTIME_DIR not configured (may cause issues)"
fi

print_header "Diagnostic Complete"
echo ""
print_info "Summary of Issues:"
echo ""
echo "If XFCE4 is not installed, run: sudo ./fix-xrdp-desktop.sh"
echo "If services are down, run: sudo systemctl restart xrdp xrdp-sesman"
echo "Check full logs: sudo journalctl -u xrdp-sesman -n 100"
echo ""

