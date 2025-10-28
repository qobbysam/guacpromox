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
