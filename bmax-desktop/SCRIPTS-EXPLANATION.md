# Detailed Explanation of bmax-desktop Scripts

This document provides a comprehensive explanation of each script in the `bmax-desktop` folder, including their purpose, configuration options, usage, and detailed parameters.

---

## Overview

The `bmax-desktop` package provides a complete solution for setting up Ubuntu Desktop VMs that support:
- Multiple concurrent XRDP users on the same VM
- Shared Chrome browser configuration (accounts, extensions, bookmarks)
- Isolated browsing sessions per user (history, tabs, downloads)
- Automatic cleanup of old sessions

---

## Script 1: `setup-desktop-vm.sh`

### Purpose
Main initialization script that sets up the Ubuntu Desktop VM with XRDP and prepares the environment for multi-user Chrome sessions.

### Configuration Variables (Lines 25-31)

```bash
SHARED_USER="shared-desktop"           # Username for all XRDP connections
SHARED_USER_PASSWORD="ChangeMe123!"    # Initial password (CHANGE THIS!)
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"  # Master profile location
CHROME_SESSIONS_DIR="/opt/chrome-sessions"         # Per-session profiles
CHROME_LAUNCHER="/usr/local/bin/launch-chrome.sh"  # Chrome launcher location
LOG_FILE="/var/log/desktop-vm-setup.log"           # Setup log file
```

### What It Does

1. **System Updates** (Lines 70-74)
   - Updates package lists
   - Upgrades all installed packages

2. **XRDP Installation** (Lines 76-79)
   - Installs XRDP server for remote desktop connections

3. **XRDP Configuration for Concurrent Sessions** (Lines 81-162)
   - Configures `/etc/xrdp/xrdp.ini` for multiple sessions
   - Key settings:
     - `MaxSessions=50` - Allows up to 50 concurrent sessions
     - `KillDisconnected=false` - Keeps sessions alive when disconnected
     - `IdleTimeLimit=0` - No automatic timeout for idle sessions
     - `DisconnectedTimeLimit=0` - No timeout for disconnected sessions
   - Configures `/etc/xrdp/sesman.ini` for session management

4. **Google Chrome Installation** (Lines 164-170)
   - Adds Google's repository
   - Installs `google-chrome-stable`

5. **Additional Dependencies** (Lines 172-175)
   - Installs `rsync` (for profile syncing)
   - Installs `jq` (JSON processing, if needed)

6. **Shared User Account Creation** (Lines 177-186)
   - Creates `shared-desktop` user if it doesn't exist
   - Sets initial password (must be changed!)

7. **Directory Structure** (Lines 188-201)
   - Creates master profile directory: `/opt/chrome-master-profile`
   - Creates sessions directory: `/opt/chrome-sessions`
   - Creates log directory: `/var/log/chrome-sessions`
   - Sets proper ownership and permissions

8. **Firewall Configuration** (Lines 209-212)
   - Opens port 3389 (RDP) for XRDP connections

### Usage

```bash
sudo ./setup-desktop-vm.sh
```

### Customization Options

**Change the shared username:**
```bash
# Edit line 26 in the script
SHARED_USER="your-username"
```

**Change the initial password:**
```bash
# Edit line 27 in the script
SHARED_USER_PASSWORD="YourSecurePassword123!"
```

**Change directory locations:**
```bash
# Edit lines 28-29 in the script
CHROME_MASTER_PROFILE="/custom/path/master"
CHROME_SESSIONS_DIR="/custom/path/sessions"
```

**Adjust XRDP session limits:**
```bash
# Edit line 146 in sesman.ini section
MaxSessions=100  # Increase if needed
```

### Important Notes
- This script must be run as root/sudo
- The initial password should be changed immediately after setup
- Backups original XRDP configs before modifying

---

## Script 2: `setup-chrome-master.sh`

### Purpose
Interactive script that launches Chrome with the master profile so administrators can:
- Log into all required accounts (Gmail, Salesforce, Slack, etc.)
- Install browser extensions
- Configure bookmarks
- Set preferences

The master profile will be cloned for each user session.

### Configuration Variables (Lines 21-23)

```bash
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"  # Master profile location
CHROME_BIN="/usr/bin/google-chrome-stable"          # Chrome binary path
SHARED_USER="shared-desktop"                        # Expected user to run as
```

### What It Does

1. **User Verification** (Lines 30-75)
   - Checks if running as root (auto-switches to `shared-desktop` user)
   - Warns if not running as the correct user
   - Prevents Chrome from running as root (security)

2. **Permission Fixes** (Lines 91-135)
   - Verifies master profile directory ownership
   - Fixes permissions if needed
   - Removes Chrome lock files that might prevent startup:
     - `SingletonLock`
     - `SingletonCookie`
     - `SingletonSocket`

3. **Chrome Launch** (Lines 172-201)
   - Launches Chrome with master profile using:
     - `--user-data-dir=/opt/chrome-master-profile`
     - `--no-first-run` - Skips first-run wizard
     - `--no-default-browser-check` - Skips default browser prompt

4. **Profile Verification** (Lines 212-256)
   - Checks if profile was created successfully
   - Verifies important files:
     - Cookies file (indicates logged-in accounts)
     - Bookmarks file
     - Extensions directory

### Usage

```bash
# As shared-desktop user (recommended)
su - shared-desktop
./setup-chrome-master.sh

# Or from root (will auto-switch)
sudo ./setup-chrome-master.sh
```

### Chrome Launch Flags Used

```bash
--user-data-dir=/opt/chrome-master-profile  # Use master profile
--no-first-run                              # Skip first-run wizard
--no-default-browser-check                  # Skip default browser prompt
```

### Workflow

1. Run the script
2. Chrome opens with a blank master profile
3. Log into all required accounts:
   - Gmail/Google Workspace
   - Salesforce
   - Slack
   - Any other web applications
4. Install required extensions
5. Add bookmarks
6. Configure preferences
7. Close Chrome normally
8. The profile is saved and will be cloned for all future sessions

### Customization Options

**Change Chrome binary location:**
```bash
# If Chrome is installed elsewhere, edit line 23
CHROME_BIN="/usr/bin/google-chrome"
```

**Add additional Chrome flags:**
```bash
# Edit lines 174-178 in the script
CHROME_FLAGS=(
    "--user-data-dir=$CHROME_MASTER_PROFILE"
    "--no-first-run"
    "--no-default-browser-check"
    "--disable-extensions"  # Example: disable extensions
)
```

### Important Notes
- Must be run in a graphical environment (not SSH without X11 forwarding)
- Chrome cannot run as root for security reasons
- Master profile must be configured before users can access shared accounts

---

## Script 3: `launch-chrome.sh`

### Purpose
Launches Chrome with a unique, isolated profile for each XRDP session while inheriting configurations from the master profile.

### Key Feature: Session Isolation
Each user gets their own Chrome profile that:
- **Shares**: Account logins, bookmarks, extensions, preferences
- **Isolates**: Browsing history, open tabs, downloads, cache

### Configuration Variables (Lines 21-31)

```bash
CHROME_MASTER_PROFILE="/opt/chrome-master-profile"   # Source profile
CHROME_SESSIONS_DIR="/opt/chrome-sessions"           # Session profiles
LOG_DIR="/var/log/chrome-sessions"                   # Session logs
CHROME_BIN="/usr/bin/google-chrome-stable"          # Chrome binary
```

**Session ID Generation:**
```bash
DISPLAY_NUM=$(echo "$DISPLAY" | tr -cd '0-9')        # Extract display number
SESSION_ID="session-${DISPLAY_NUM}-$(date +%s)-$$"   # Unique ID per session
```

### What It Does

1. **Session ID Generation** (Lines 28-31)
   - Creates unique ID: `session-{display}-{timestamp}-{pid}`
   - Example: `session-10-1698589200-12345`
   - Based on X11 display number, timestamp, and process ID

2. **Master Profile Check** (Lines 45-51)
   - Verifies master profile exists before proceeding

3. **Profile Syncing** (Lines 53-92)
   - Creates unique session profile directory
   - Syncs specific items from master profile:
     ```
     Default/Cookies              # Account login sessions
     Default/Login Data          # Saved passwords
     Default/Preferences         # Settings
     Default/Bookmarks           # Bookmarks
     Default/Extensions          # Installed extensions
     Default/Local Extension Settings
     Default/Sync Extension Settings
     Default/Web Data            # Autofill data
     Local State                 # Chrome state
     First Run                   # First-run flag
     ```
   - Uses `rsync` for directories, `cp` for files

4. **Chrome Launch** (Lines 97-116)
   - Launches Chrome with session-specific profile
   - Flags used:
     ```bash
     --user-data-dir=/opt/chrome-sessions/session-XXX
     --no-first-run
     --no-default-browser-check
     --disable-session-crashed-bubble
     --disable-infobars
     --disable-features=TranslateUI
     --disk-cache-dir=/tmp/chrome-cache-{SESSION_ID}
     --disk-cache-size=104857600  # 100MB cache per session
     ```

5. **Cleanup on Exit** (Lines 118-142)
   - Syncs bookmarks back to master profile (if changed)
   - Removes temporary cache directory
   - Logs cleanup actions

### Usage

```bash
# Typically launched from desktop shortcut
/usr/local/bin/launch-chrome.sh

# Or from command line
launch-chrome.sh
```

### Sync Behavior

**From Master → Session (on launch):**
- Cookies (account logins)
- Saved passwords
- Bookmarks
- Extensions
- Preferences
- Autofill data

**From Session → Master (on exit):**
- Bookmarks (if modified)

**NOT synced (per-session isolation):**
- Browsing history
- Open tabs
- Downloads
- Cache files
- Session storage

### Chrome Flags Explained

```bash
--user-data-dir=XXX              # Use session-specific profile
--no-first-run                  # Skip first-run wizard
--no-default-browser-check      # Skip default browser prompt
--disable-session-crashed-bubble  # Don't show crash recovery bubble
--disable-infobars              # Hide info bars (translations, etc.)
--disable-features=TranslateUI   # Disable translation UI
--disk-cache-dir=/tmp/chrome-cache-XXX  # Session-specific cache
--disk-cache-size=104857600     # 100MB cache limit per session
```

### Customization Options

**Change cache size:**
```bash
# Edit line 106
--disk-cache-size=209715200  # 200MB instead of 100MB
```

**Add/remove Chrome flags:**
```bash
# Edit lines 98-107
CHROME_FLAGS=(
    "--user-data-dir=$SESSION_PROFILE"
    "--no-first-run"
    "--your-custom-flag"  # Add custom flags
)
```

**Disable bookmark sync:**
```bash
# Comment out lines 122-129 to prevent bookmark sync
# BOOKMARKS_SRC="$SESSION_PROFILE/Default/Bookmarks"
# ...
```

### Important Notes
- Must be run from within an XRDP session (has DISPLAY set)
- Creates a new profile for each unique DISPLAY session
- Profiles accumulate in `/opt/chrome-sessions` (use cleanup script)

---

## Script 4: `post-setup-desktop-vm.sh`

### Purpose
Post-setup script that installs Chrome-related scripts and creates the desktop shortcut after `setup-desktop-vm.sh` has been run.

### Configuration Variables (Lines 27-30)

```bash
CHROME_LAUNCHER="/usr/local/bin/launch-chrome.sh"
CLEANUP_SCRIPT="/usr/local/bin/cleanup-chrome-sessions.sh"
SHARED_USER="shared-desktop"
```

### What It Does

1. **Script Verification** (Lines 70-88)
   - Checks for required scripts in current directory:
     - `launch-chrome.sh`
     - `cleanup-chrome-sessions.sh`
     - `setup-chrome-master.sh`

2. **Install Chrome Launcher** (Lines 93-110)
   - Copies `launch-chrome.sh` to `/usr/local/bin/`
   - Makes it executable
   - Sets ownership to `shared-desktop` user

3. **Install Cleanup Script** (Lines 112-129)
   - Copies `cleanup-chrome-sessions.sh` to `/usr/local/bin/`
   - Makes it executable
   - Sets ownership to `shared-desktop` user

4. **Copy Master Setup Script** (Lines 131-145)
   - Copies `setup-chrome-master.sh` to user's home directory
   - Makes it executable

5. **Create Desktop Shortcut** (Lines 147-201)
   - Creates `Chrome-Shared.desktop` file on Desktop
   - Configures to launch `/usr/local/bin/launch-chrome.sh`
   - Sets icon and metadata
   - Marks as trusted (executable)

### Usage

```bash
# From directory containing all scripts
./post-setup-desktop-vm.sh

# Can run as root or shared-desktop user
sudo ./post-setup-desktop-vm.sh
```

### Desktop Shortcut Details

**File:** `~/Desktop/Chrome-Shared.desktop`

**Contents:**
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome (Shared Config)
Comment=Launch Chrome with shared configuration
Exec=/usr/local/bin/launch-chrome.sh
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
```

### Customization Options

**Change installation paths:**
```bash
# Edit lines 28-29
CHROME_LAUNCHER="/custom/path/launch-chrome.sh"
CLEANUP_SCRIPT="/custom/path/cleanup-chrome-sessions.sh"
```

**Customize desktop shortcut:**
```bash
# Edit lines 170-180
Name=My Custom Chrome Name
Icon=chromium  # Use different icon
```

### Important Notes
- Must be run after `setup-desktop-vm.sh`
- Requires all three scripts in the same directory
- Creates executable desktop shortcut (users can double-click)

---

## Script 5: `cleanup-chrome-sessions.sh`

### Purpose
Automated cleanup script to remove old Chrome session profiles to free disk space. Designed to be run via cron.

### Configuration Variables (Lines 16-20)

```bash
CHROME_SESSIONS_DIR="/opt/chrome-sessions"          # Session profiles location
LOG_DIR="/var/log/chrome-sessions"                  # Log files location
CLEANUP_LOG="/var/log/chrome-sessions-cleanup.log"  # Cleanup log file
DEFAULT_DAYS=7                                       # Default retention period
```

### Command-Line Options

```bash
--days N      # Delete sessions older than N days (default: 7)
--dry-run     # Show what would be deleted without deleting
```

### What It Does

1. **Argument Parsing** (Lines 22-42)
   - Parses `--days` and `--dry-run` options
   - Validates arguments

2. **Find Old Sessions** (Lines 61-69)
   - Uses `find` to locate session directories older than specified days
   - Counts sessions to delete

3. **Delete Old Sessions** (Lines 77-102)
   - For each old session:
     - Shows size and age
     - Deletes directory (unless dry-run)
     - Logs success/failure

4. **Clean Up Old Logs** (Lines 104-117)
   - Finds log files older than retention period
   - Deletes old log files

5. **Space Reporting** (Lines 119-123)
   - Reports directory size before and after cleanup

### Usage

```bash
# Default: Delete sessions older than 7 days
sudo cleanup-chrome-sessions.sh

# Delete sessions older than 14 days
sudo cleanup-chrome-sessions.sh --days 14

# See what would be deleted (dry run)
sudo cleanup-chrome-sessions.sh --dry-run

# Combine options
sudo cleanup-chrome-sessions.sh --days 3 --dry-run
```

### Cron Setup

**Daily cleanup at 2 AM:**
```bash
sudo crontab -e
# Add this line:
0 2 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 7 >> /var/log/chrome-cleanup.log 2>&1
```

**Weekly cleanup (Sundays at 3 AM):**
```bash
0 3 * * 0 /usr/local/bin/cleanup-chrome-sessions.sh --days 7 >> /var/log/chrome-cleanup.log 2>&1
```

### Output Example

```
[2025-10-28 02:00:00] Chrome Sessions Cleanup Starting
[2025-10-28 02:00:00] Delete sessions older than: 7 days
[2025-10-28 02:00:00] Dry run: false
[2025-10-28 02:00:00] Found 15 session(s) to clean up
[2025-10-28 02:00:00] Current sessions directory size: 2.5G
[2025-10-28 02:00:01] Deleting: session-10-1698000000-12345 (Size: 180M, Age: 10 days)
[2025-10-28 02:00:01]   ✓ Deleted successfully
...
[2025-10-28 02:00:15] Sessions directory size after cleanup: 1.2G
[2025-10-28 02:00:15] CLEANUP SUMMARY:
[2025-10-28 02:00:15]   Sessions deleted: 15
[2025-10-28 02:00:15]   Failed deletions: 0
[2025-10-28 02:00:15]   Logs deleted: 15
```

### Customization Options

**Change default retention period:**
```bash
# Edit line 20
DEFAULT_DAYS=14  # Keep sessions for 14 days instead of 7
```

**Change log file location:**
```bash
# Edit line 19
CLEANUP_LOG="/var/log/my-custom-cleanup.log"
```

**Modify find command criteria:**
```bash
# Edit line 62 to change matching pattern
OLD_SESSIONS=$(find "$CHROME_SESSIONS_DIR" -maxdepth 1 -type d -name "session-*" -mtime +$DAYS)
```

### Important Notes
- Safe to run manually or via cron
- Use `--dry-run` first to see what will be deleted
- Active sessions are not affected (only old ones)
- Logs all actions for audit trail

---

## Error File: `errors.txt`

This file contains a common error encountered when running `setup-chrome-master.sh`:

```
Failed to create /opt/chrome-master-profile/SingletonLock: Permission denied
```

**Cause:** Chrome cannot create lock files in the profile directory due to permission issues.

**Solution:** The script automatically fixes this (lines 91-135), but if it persists:
```bash
sudo chown -R shared-desktop:shared-desktop /opt/chrome-master-profile
sudo chmod -R 755 /opt/chrome-master-profile
```

---

## Setup Workflow Summary

1. **Initial Setup:**
   ```bash
   sudo ./setup-desktop-vm.sh              # Configure VM
   ./post-setup-desktop-vm.sh              # Install scripts
   ```

2. **Master Profile Configuration:**
   ```bash
   su - shared-desktop
   ./setup-chrome-master.sh                # Log into accounts, install extensions
   ```

3. **User Access:**
   - Connect via Guacamole/XRDP
   - Double-click "Chrome (Shared Config)" desktop shortcut
   - Chrome opens with shared accounts but isolated session

4. **Maintenance:**
   ```bash
   # Update master profile (re-login to accounts)
   ./setup-chrome-master.sh

   # Clean up old sessions
   sudo cleanup-chrome-sessions.sh --days 7

   # Setup automatic cleanup
   sudo crontab -e
   # Add: 0 2 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 7
   ```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Master Profile                       │
│          /opt/chrome-master-profile                     │
│  • Cookies (account logins)                             │
│  • Bookmarks                                            │
│  • Extensions                                           │
│  • Preferences                                          │
└─────────────────────────────────────────────────────────┘
                        │
                        │ (cloned on launch)
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Session 1   │ │ Session 2   │ │ Session 3   │
│ User A      │ │ User B      │ │ User C      │
├─────────────┤ ├─────────────┤ ├─────────────┤
│ Shared:     │ │ Shared:     │ │ Shared:     │
│ • Logins ✓  │ │ • Logins ✓  │ │ • Logins ✓  │
│ • Bookmarks │ │ • Bookmarks │ │ • Bookmarks │
│ • Extensions│ │ • Extensions│ │ • Extensions│
├─────────────┤ ├─────────────┤ ├─────────────┤
│ Isolated:   │ │ Isolated:   │ │ Isolated:   │
│ • History   │ │ • History   │ │ • History   │
│ • Tabs      │ │ • Tabs      │ │ • Tabs      │
│ • Downloads │ │ • Downloads │ │ • Downloads │
└─────────────┘ └─────────────┘ └─────────────┘
```

---

## Security Considerations

1. **User Permissions:**
   - Master profile owned by `shared-desktop` user
   - Session profiles isolated per user
   - Cleanup script should run as root (to delete any user's old sessions)

2. **Shared Accounts:**
   - All users share the same account logins
   - Users can see each other's activity if they access the same account
   - Consider access control policies

3. **Data Isolation:**
   - Browsing history is per-session
   - Downloads are per-session
   - But account activity is visible to all users

4. **Cleanup:**
   - Old session profiles may contain sensitive data
   - Regular cleanup is recommended
   - Consider secure deletion for sensitive environments

---

## Troubleshooting

### Chrome won't launch from shortcut
- Check file permissions: `ls -l /usr/local/bin/launch-chrome.sh`
- Verify master profile exists: `ls -l /opt/chrome-master-profile`
- Check logs: `tail -f /var/log/chrome-sessions/session-*.log`

### Accounts not logged in
- Master profile needs to be updated: `./setup-chrome-master.sh`
- Verify cookies exist: `ls -l /opt/chrome-master-profile/Default/Cookies`

### Sessions accumulating too fast
- Run cleanup more frequently: `cleanup-chrome-sessions.sh --days 3`
- Set up daily cron job

### Permission denied errors
- Fix ownership: `sudo chown -R shared-desktop:shared-desktop /opt/chrome-*`
- Fix permissions: `sudo chmod -R 755 /opt/chrome-*`

---

## Additional Resources

- User Guide: `README-DESKTOP.txt`
- Setup Instructions: `readme.md`
- Deployment Guide: `../guacserver/DEPLOYMENT-GUIDE.md`

