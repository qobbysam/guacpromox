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
