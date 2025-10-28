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

# Save original directory and script directory
ORIGINAL_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create installation directory
print_info "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
print_success "Installation directory created: $INSTALL_DIR"

# Copy docker-compose.yml to installation directory
print_info "Locating docker-compose.yml..."

# Try to find docker-compose.yml in multiple locations
DOCKER_COMPOSE_SRC=""
POSSIBLE_LOCATIONS=(
    "$SCRIPT_DIR/docker-compose.yml"      # Same directory as script
    "$ORIGINAL_DIR/docker-compose.yml"    # Original working directory
    "$HOME/docker-compose.yml"            # Home directory
    "/root/docker-compose.yml"            # Root home directory
    "./docker-compose.yml"                # Current directory
)

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [[ -f "$location" ]]; then
        DOCKER_COMPOSE_SRC="$location"
        print_success "Found docker-compose.yml at: $location"
        break
    fi
done

if [[ -n "$DOCKER_COMPOSE_SRC" ]]; then
    cp "$DOCKER_COMPOSE_SRC" "$INSTALL_DIR/docker-compose.yml"
    chmod 644 "$INSTALL_DIR/docker-compose.yml"
    print_success "Docker Compose file copied to: $INSTALL_DIR/docker-compose.yml"
else
    print_error "docker-compose.yml not found in any of these locations:"
    for location in "${POSSIBLE_LOCATIONS[@]}"; do
        echo "  • $location"
    done
    print_warning "Please ensure docker-compose.yml is in the same directory as this script, or copy it manually to: $INSTALL_DIR/"
    exit 1
fi

# Copy management scripts to installation directory (if they exist in script directory)
print_info "Copying management scripts..."
MANAGEMENT_SCRIPTS=("manage-guacamole.sh" "configure-guacamole.sh")

for script in "${MANAGEMENT_SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        cp "$SCRIPT_DIR/$script" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$script"
        print_success "Copied $script to installation directory"
    elif [[ -f "$ORIGINAL_DIR/$script" ]]; then
        cp "$ORIGINAL_DIR/$script" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$script"
        print_success "Copied $script to installation directory"
    else
        print_warning "$script not found, skipping (can be copied manually later)"
    fi
done

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

# Start Guacamole stack
print_info "Starting Guacamole stack..."
cd "$INSTALL_DIR"

# Verify docker-compose.yml exists in installation directory
if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
    print_error "docker-compose.yml not found in $INSTALL_DIR"
    print_error "Cannot start Guacamole stack without docker-compose.yml"
    exit 1
fi

print_info "Using docker-compose.yml from: $INSTALL_DIR/docker-compose.yml"
docker compose up -d >> "$LOG_FILE" 2>&1
DOCKER_EXIT_CODE=$?

if [[ $DOCKER_EXIT_CODE -ne 0 ]]; then
    print_error "Docker Compose failed with exit code: $DOCKER_EXIT_CODE"
    print_info "Checking logs..."
    docker compose logs >> "$LOG_FILE" 2>&1
    print_warning "See log file for details: $LOG_FILE"
    exit $DOCKER_EXIT_CODE
fi

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
