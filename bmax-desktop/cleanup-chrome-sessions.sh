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
