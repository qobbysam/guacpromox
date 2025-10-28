# Desktop VM Setup Package

This directory contains all scripts and documentation needed to set up Ubuntu Desktop VMs for multi-user remote desktop access with shared Chrome browser sessions.

## Files in this package

- **setup-desktop-vm.sh** - Main setup script for configuring Ubuntu Desktop VM with XRDP and Chrome
- **fix-xrdp.sh** - Fix script for xrdp startup issues (missing directories/permissions)
- **post-setup-desktop-vm.sh** - Post-setup script to install Chrome scripts and create desktop shortcut
- **launch-chrome.sh** - Chrome launcher with session isolation for concurrent users
- **setup-chrome-master.sh** - Helper script for configuring the master Chrome profile
- **cleanup-chrome-sessions.sh** - Automatic cleanup script for old Chrome sessions
- **README-DESKTOP.txt** - User guide for end users

## Quick Start

1. **Transfer scripts to the Ubuntu Desktop VM:**
   ```bash
   scp setup-desktop-vm.sh shared-desktop@[VM-IP]:~/
   scp post-setup-desktop-vm.sh shared-desktop@[VM-IP]:~/
   scp launch-chrome.sh shared-desktop@[VM-IP]:~/
   scp setup-chrome-master.sh shared-desktop@[VM-IP]:~/
   scp cleanup-chrome-sessions.sh shared-desktop@[VM-IP]:~/
   ```

2. **Run the main setup script:**
   ```bash
   ssh shared-desktop@[VM-IP]
   chmod +x setup-desktop-vm.sh
   sudo ./setup-desktop-vm.sh
   ```

3. **Run the post-setup script (installs Chrome scripts and creates shortcut):**
   ```bash
   chmod +x post-setup-desktop-vm.sh
   ./post-setup-desktop-vm.sh
   ```

4. **Configure the master Chrome profile:**
   ```bash
   cd ~/
   ./setup-chrome-master.sh
   # Log into all required accounts (Gmail, Salesforce, etc.)
   # Install required extensions
   # Set bookmarks
   # Close Chrome when done
   ```

## How it works

1. **XRDP Configuration**: XRDP is configured to allow multiple concurrent sessions to the same user account
2. **Chrome Session Isolation**: Each XRDP session gets a unique Chrome profile that inherits:
   - Cookies and login sessions
   - Saved passwords
   - Bookmarks
   - Extensions
   - Preferences
3. **Independent Browsing**: While sharing authentication, each user's browsing history, tabs, and downloads are isolated

## Testing Concurrent Access

1. Connect to the VM via XRDP as User A
2. Open Chrome and verify accounts are logged in
3. From another computer, connect as User B to the SAME VM
4. User B should also be logged into the same accounts
5. Both users can browse independently

## Troubleshooting

**XRDP won't start (log errors):**
If xrdp fails to start with "Could not start log" errors, run:
```bash
sudo ./fix-xrdp.sh
```

This script creates the required directories (`/var/log/xrdp` and `/run/xrdp`) and sets proper permissions.

## Maintenance

**Cleanup old sessions:**
```bash
sudo /usr/local/bin/cleanup-chrome-sessions.sh --days 7
```

**Update master Chrome profile:**
```bash
./setup-chrome-master.sh
# Make changes and close Chrome
```

## For more information

See the complete deployment guide in the guacserver directory or the main DEPLOYMENT-GUIDE.md file.
