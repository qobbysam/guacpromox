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

# Determine which Docker Compose command to use
DOCKER_COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    print_success "Using Docker Compose plugin (docker compose)"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    print_success "Using Docker Compose standalone (docker-compose)"
else
    print_info "Docker Compose not found, installing standalone version..."
    # Install docker-compose standalone
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="aarch64"
    fi
    curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-${OS}-${ARCH}" -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        print_success "Docker Compose installed"
    else
        print_error "Failed to install Docker Compose"
        exit 1
    fi
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
    DOCKER_COMPOSE_FILE="$DOCKER_COMPOSE_SRC"
    COMPOSE_DIR=$(dirname "$DOCKER_COMPOSE_FILE")
    print_success "Using docker-compose.yml from: $DOCKER_COMPOSE_FILE"
else
    print_error "docker-compose.yml not found in any of these locations:"
    for location in "${POSSIBLE_LOCATIONS[@]}"; do
        echo "  • $location"
    done
    print_warning "Please ensure docker-compose.yml is in the same directory as this script"
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
# Create initdb.sql in the same directory as docker-compose.yml so relative paths work
# According to Apache Guacamole docs, use --postgresql flag (not --postgres)
print_info "Running initdb.sh to generate PostgreSQL schema..."
# Run initdb.sh and capture both stdout and stderr, but only save stdout to initdb.sql
docker run --rm guacamole/guacamole:$GUACAMOLE_VERSION /opt/guacamole/bin/initdb.sh --postgresql > "$COMPOSE_DIR/initdb.sql" 2>> "$LOG_FILE"
DOCKER_INIT_EXIT_CODE=$?

if [[ $DOCKER_INIT_EXIT_CODE -ne 0 ]]; then
    print_error "Failed to generate database initialization script (exit code: $DOCKER_INIT_EXIT_CODE)"
    print_info "Check log file for details: $LOG_FILE"
    exit 1
fi

# Verify the initdb.sql file was created and contains SQL (not error messages)
if [[ ! -s "$COMPOSE_DIR/initdb.sql" ]]; then
    print_error "initdb.sql is empty"
    exit 1
fi

# Check if it contains SQL statements (should start with -- or CREATE)
if ! head -n 5 "$COMPOSE_DIR/initdb.sql" | grep -qE "^(--|CREATE|INSERT|GRANT)"; then
    print_error "initdb.sql appears to contain errors instead of SQL"
    print_info "First few lines of initdb.sql:"
    head -n 10 "$COMPOSE_DIR/initdb.sql"
    exit 1
fi

# Also keep a copy in INSTALL_DIR for reference
cp "$COMPOSE_DIR/initdb.sql" "$INSTALL_DIR/initdb.sql"
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

# Verify docker-compose.yml still exists
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    print_error "docker-compose.yml not found at: $DOCKER_COMPOSE_FILE"
    print_error "Cannot start Guacamole stack without docker-compose.yml"
    exit 1
fi

# Change to directory containing docker-compose.yml to ensure relative paths work
cd "$COMPOSE_DIR"

print_info "Using docker-compose.yml from: $DOCKER_COMPOSE_FILE"

# Verify initdb.sql exists (required by docker-compose.yml)
if [[ ! -f "$COMPOSE_DIR/initdb.sql" ]]; then
    print_error "initdb.sql not found in $COMPOSE_DIR"
    print_error "This file is required by docker-compose.yml"
    exit 1
fi

# Verify .env file exists
if [[ ! -f "$INSTALL_DIR/.env" ]]; then
    print_error ".env file not found at $INSTALL_DIR/.env"
    exit 1
fi

# Copy .env file to compose directory so docker compose can find it automatically
# Docker Compose automatically looks for .env in the same directory as docker-compose.yml
cp "$INSTALL_DIR/.env" "$COMPOSE_DIR/.env"
chmod 600 "$COMPOSE_DIR/.env"
print_info "Environment file ready: $COMPOSE_DIR/.env"

# Check if containers are already running (might need cleanup if database failed to initialize)
if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
    print_warning "Some containers are already running"
    print_info "If database initialization previously failed, you may need to remove volumes:"
    print_info "  docker compose -f $DOCKER_COMPOSE_FILE down -v"
    print_info "Then re-run this script."
fi

# Test docker compose command first
print_info "Validating docker-compose.yml syntax..."
if ! $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" config > /dev/null 2>&1; then
    print_error "Docker Compose configuration validation failed"
    print_info "Running config check with output:"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" config
    exit 1
fi

# Explicitly specify the compose file path (docker compose will auto-load .env from same directory)
print_info "Starting Docker containers..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d 2>&1 | tee -a "$LOG_FILE"
DOCKER_EXIT_CODE=${PIPESTATUS[0]}

if [[ $DOCKER_EXIT_CODE -ne 0 ]]; then
    print_error "Docker Compose failed with exit code: $DOCKER_EXIT_CODE"
    print_info "Checking container status..."
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps 2>&1 | tee -a "$LOG_FILE"
    print_info "Checking logs..."
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs --tail=50 2>&1 | tee -a "$LOG_FILE"
    print_warning "See full log file for details: $LOG_FILE"
    exit $DOCKER_EXIT_CODE
fi

# Wait for services to be healthy
print_info "Waiting for services to start (this may take 30-60 seconds)..."
sleep 10

# Check if containers are running
CONTAINERS_RUNNING=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps | grep -c "Up")
if [[ $CONTAINERS_RUNNING -ge 3 ]]; then
    print_success "All containers started successfully"
else
    print_warning "Some containers may not be running properly"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps
fi

# Configure firewall
print_info "Configuring firewall..."
ufw allow 8080/tcp >> "$LOG_FILE" 2>&1
print_success "Firewall configured (port 8080 open)"

# Create systemd service for auto-start
print_info "Creating systemd service..."

# Determine the full path for docker compose command in systemd
# .env file will be in same directory as docker-compose.yml, so docker compose will auto-load it
if [[ "$DOCKER_COMPOSE_CMD" == "docker compose" ]]; then
    COMPOSE_START="/usr/bin/docker compose -f $DOCKER_COMPOSE_FILE up -d"
    COMPOSE_STOP="/usr/bin/docker compose -f $DOCKER_COMPOSE_FILE down"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_PATH=$(which docker-compose)
    COMPOSE_START="$COMPOSE_PATH -f $DOCKER_COMPOSE_FILE up -d"
    COMPOSE_STOP="$COMPOSE_PATH -f $DOCKER_COMPOSE_FILE down"
else
    COMPOSE_START="/usr/local/bin/docker-compose -f $DOCKER_COMPOSE_FILE up -d"
    COMPOSE_STOP="/usr/local/bin/docker-compose -f $DOCKER_COMPOSE_FILE down"
fi

cat > /etc/systemd/system/guacamole.service <<EOF
[Unit]
Description=Guacamole Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$COMPOSE_DIR
ExecStart=$COMPOSE_START
ExecStop=$COMPOSE_STOP
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
