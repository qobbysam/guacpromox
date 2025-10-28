# Comprehensive Desktop VM Setup Guide

This guide explains how to set up an Ubuntu Desktop VM for multi-user XRDP access with shared Chrome browser sessions. This setup is optimized for Proxmox VMs and includes all necessary fixes and configurations.

## Overview

This solution enables:
- **Multiple concurrent RDP connections** to the same VM
- **Shared Chrome authentication** - all users logged into the same accounts
- **Isolated browsing sessions** - each user has their own tabs, history, and downloads
- **Automatic session cleanup** - old Chrome sessions are automatically removed

## Architecture

```
Multiple RDP Clients (Windows, Linux, Mac)
           ↓
    XRDP Server (Ubuntu VM)
           ↓
    XFCE4 Desktop Environment
           ↓
    Shared Chrome Sessions (isolated profiles)
```

## Prerequisites

1. **Ubuntu 22.04 LTS** (Desktop or Server) installed on a VM
2. **Root/sudo access** to the VM
3. **Internet connection** for package downloads
4. **VM Environment** (Proxmox, VirtualBox, VMware, etc.)

## Quick Setup (All-in-One)

### Step 1: Transfer Scripts to VM

On your local machine, transfer all scripts to the VM:

```bash
# Replace VM_IP with your VM's IP address
VM_IP="192.168.100.110"

# Transfer all scripts
scp setup-desktop-vm-new.sh user@$VM_IP:~/
scp launch-chrome.sh user@$VM_IP:~/
scp cleanup-chrome-sessions.sh user@$VM_IP:~/
scp setup-chrome-master.sh user@$VM_IP:~/
```

### Step 2: Run the Comprehensive Setup

SSH into your VM and run the setup script:

```bash
ssh user@$VM_IP
chmod +x setup-desktop-vm-new.sh
sudo ./setup-desktop-vm-new.sh
```

**What this script does:**
1. Updates system packages
2. Installs XRDP
3. Creates required directories with proper permissions
4. Installs XFCE4 desktop environment
5. Installs Xorg virtualization drivers (fixes crashes in VMs)
6. Configures Xorg to use dummy driver (prevents hardware detection issues)
7. Configures XRDP with logging and concurrent sessions
8. Sets up window manager to launch XFCE4
9. Installs build tools and dependencies
10. Configures polkit authentication
11. Installs Google Chrome
12. Creates shared user account
13. Sets up Chrome directories
14. Installs Chrome helper scripts
15. Configures firewall

The script takes **15-20 minutes** to complete depending on your internet speed.

### Step 3: Change Default Password

After setup, change the default password:

```bash
sudo passwd shared-desktop
```

### Step 4: Configure Master Chrome Profile

Switch to the shared user and configure the master Chrome profile:

```bash
sudo -u shared-desktop /home/shared-desktop/setup-chrome-master.sh
```

**What to do when Chrome opens:**
1. Log into all required accounts:
   - Gmail/Google Workspace
   - Salesforce
   - Slack
   - Any other web applications
2. Install required Chrome extensions
3. Set up bookmarks
4. Configure preferences
5. Close Chrome when finished

This profile will be shared with all RDP users, but each user will have their own isolated session.

### Step 5: Test RDP Connection

From another machine on the same network, connect via RDP:

**Windows:**
- Open Remote Desktop Connection
- Enter: `VM_IP` or hostname
- Username: `shared-desktop`
- Password: [the password you set]

**Linux/Mac:**
```bash
# Install xfreerdp or remmina
sudo apt install freerdp2-x11  # Debian/Ubuntu
brew install freerdp  # macOS

# Connect
xfreerdp /v:VM_IP /u:shared-desktop /p:password
```

### Step 6: Verify Desktop Works

After connecting, you should see:
- XFCE4 desktop environment
- Chrome shortcut on desktop (if scripts were installed)
- Ability to launch applications

If you see a blank screen or errors, see the Troubleshooting section below.

## What's Included (All Fixes Applied)

The `setup-desktop-vm-new.sh` script includes **all fixes** from this conversation:

### ✅ Fix 1: XRDP Logging
- Creates `/var/log/xrdp` and `/run/xrdp` directories
- Adds `[Logging]` section to `xrdp.ini`
- Sets proper permissions

### ✅ Fix 2: Desktop Environment
- Installs XFCE4 desktop environment
- Configures `startwm.sh` to launch XFCE4
- Sets up XDG environment variables
- Creates XDG_RUNTIME_DIR with proper permissions

### ✅ Fix 3: Xorg Crash Fix (Proxmox VMs)
- Installs Xorg virtualization drivers (`dummy`, `fbdev`)
- Creates Xorg configuration forcing dummy driver
- Disables hardware auto-detection
- Prevents segmentation faults (signal 11)

### ✅ Fix 4: Build Tools & Dependencies
- Installs all required build tools
- Installs X11 development libraries
- Installs Xorg development packages

### ✅ Fix 5: Polkit Authentication
- Configures polkit to prevent desktop errors
- Allows color management operations
- Prevents authentication dialog loops

### ✅ Fix 6: Chrome Session Isolation
- Sets up master profile directory
- Sets up session directories
- Installs Chrome launcher script
- Installs cleanup script

## Files Created/Modified

**Configuration Files:**
- `/etc/xrdp/xrdp.ini` - XRDP server configuration
- `/etc/xrdp/sesman.ini` - XRDP session manager configuration
- `/etc/xrdp/startwm.sh` - Window manager startup script
- `/etc/X11/xorg.conf.d/10-xrdp.conf` - Xorg configuration for VMs
- `/etc/polkit-1/localauthority/50-local.d/02-allow-colord.pkla` - Polkit rules

**Directories:**
- `/var/log/xrdp/` - XRDP logs
- `/run/xrdp/` - XRDP runtime files
- `/opt/chrome-master-profile/` - Master Chrome profile
- `/opt/chrome-sessions/` - Individual Chrome session profiles
- `/var/log/chrome-sessions/` - Chrome session logs

**Scripts:**
- `/usr/local/bin/launch-chrome.sh` - Chrome launcher
- `/usr/local/bin/cleanup-chrome-sessions.sh` - Session cleanup
- `/home/shared-desktop/setup-chrome-master.sh` - Master profile setup

**User Account:**
- Username: `shared-desktop`
- Default password: `ChangeMe123!` (must be changed)

## Troubleshooting

### Problem: XRDP won't start

**Symptoms:** `systemctl status xrdp` shows failed

**Solution:** The setup script should have fixed this, but if it persists:

```bash
sudo mkdir -p /var/log/xrdp /run/xrdp
sudo chown xrdp:xrdp /var/log/xrdp /run/xrdp
sudo systemctl restart xrdp
```

### Problem: No desktop after login (blank screen)

**Symptoms:** RDP connects, login works, but no desktop appears

**Diagnosis:**
```bash
# Check if XFCE4 is installed
dpkg -l | grep xfce4

# Check window manager script
cat /etc/xrdp/startwm.sh | grep -i xfce

# Check session logs
sudo journalctl -u xrdp-sesman -n 50
```

**Solution:** If XFCE4 is missing, re-run:
```bash
sudo apt install xfce4 xfce4-goodies xfce4-terminal dbus-x11
sudo systemctl restart xrdp
```

### Problem: X server crashes (signal 11)

**Symptoms:** Logs show "X server returned exit code 255 and signal number 11"

**Diagnosis:**
```bash
# Check if dummy driver is installed
dpkg -l | grep xserver-xorg-video-dummy

# Check Xorg config
cat /etc/X11/xorg.conf.d/10-xrdp.conf
```

**Solution:** The setup script should have fixed this. If not:
```bash
sudo apt install xserver-xorg-video-dummy xserver-xorg-video-fbdev
sudo systemctl restart xrdp
```

### Problem: Chrome won't launch

**Symptoms:** Chrome doesn't start or shows errors

**Diagnosis:**
```bash
# Check if master profile exists
ls -la /opt/chrome-master-profile/

# Check launcher script
ls -la /usr/local/bin/launch-chrome.sh

# Try manual launch
sudo -u shared-desktop /usr/local/bin/launch-chrome.sh
```

**Solution:**
```bash
# Re-run master profile setup
sudo -u shared-desktop /home/shared-desktop/setup-chrome-master.sh
```

### Problem: Can't connect via RDP from Windows

**Symptoms:** Connection times out or is refused

**Diagnosis:**
```bash
# Check if XRDP is listening
sudo ss -tlnp | grep 3389

# Check firewall
sudo ufw status

# Check XRDP service
sudo systemctl status xrdp
```

**Solution:**
```bash
# Open firewall port
sudo ufw allow 3389/tcp

# Restart XRDP
sudo systemctl restart xrdp
```

## Maintenance

### Cleanup Old Chrome Sessions

Old Chrome session profiles can accumulate. Clean them up automatically:

```bash
# Manual cleanup (delete sessions older than 7 days)
sudo /usr/local/bin/cleanup-chrome-sessions.sh --days 7

# Dry run (see what would be deleted)
sudo /usr/local/bin/cleanup-chrome-sessions.sh --days 7 --dry-run

# Automatic cleanup via cron (add to crontab)
sudo crontab -e
# Add this line:
0 2 * * * /usr/local/bin/cleanup-chrome-sessions.sh --days 7
```

### Update Master Chrome Profile

To update the master profile (add accounts, extensions, etc.):

```bash
sudo -u shared-desktop /home/shared-desktop/setup-chrome-master.sh
```

### View Logs

```bash
# XRDP logs
sudo journalctl -u xrdp -f
sudo journalctl -u xrdp-sesman -f

# XRDP log files
sudo tail -f /var/log/xrdp/xrdp.log
sudo tail -f /var/log/xrdp/xrdp-sesman.log

# Chrome session logs
sudo tail -f /var/log/chrome-sessions/session-*.log
```

### Check System Status

```bash
# Service status
sudo systemctl status xrdp xrdp-sesman

# Active RDP sessions
who

# X server status
ps aux | grep Xorg

# Chrome processes
ps aux | grep chrome
```

## Advanced Configuration

### Change Default Username

To use a different username instead of `shared-desktop`:

1. Edit `setup-desktop-vm-new.sh`
2. Change: `SHARED_USER="your-username"`
3. Re-run the script (or manually create the user)

### Change Chrome Profile Location

To use different directories for Chrome profiles:

1. Edit `setup-desktop-vm-new.sh`
2. Change:
   ```bash
   CHROME_MASTER_PROFILE="/custom/path/master"
   CHROME_SESSIONS_DIR="/custom/path/sessions"
   ```
3. Re-run the script

### Adjust XRDP Session Limits

Edit `/etc/xrdp/sesman.ini`:

```ini
[Sessions]
MaxSessions=100  # Increase if needed
```

Then restart:
```bash
sudo systemctl restart xrdp-sesman
```

### Enable SSL/TLS for XRDP

For production, consider enabling SSL:

1. Generate certificate:
   ```bash
   sudo openssl req -x509 -newkey rsa:2048 -nodes \
     -keyout /etc/xrdp/key.pem -out /etc/xrdp/cert.pem \
     -days 365
   ```

2. Edit `/etc/xrdp/xrdp.ini`:
   ```ini
   [Globals]
   certificate=/etc/xrdp/cert.pem
   key_file=/etc/xrdp/key.pem
   ```

3. Restart XRDP:
   ```bash
   sudo systemctl restart xrdp
   ```

## Testing Concurrent Access

1. Connect to the VM via RDP as User A
2. Launch Chrome and verify all accounts are logged in
3. Open some tabs
4. From another computer, connect as User B (same credentials)
5. User B should also see Chrome with the same accounts logged in
6. Both users can browse independently
7. Each user's tabs, history, and downloads are separate

## Security Considerations

1. **Change default password immediately** after setup
2. **Use strong passwords** for the shared-desktop user
3. **Enable firewall** and only allow RDP from trusted networks
4. **Consider using VPN** instead of exposing RDP directly to internet
5. **Enable SSL/TLS** for XRDP in production
6. **Regular updates:** `sudo apt update && sudo apt upgrade`
7. **Monitor logs** for suspicious activity

## Support Scripts

This package includes several helper scripts:

- **setup-desktop-vm-new.sh** - Complete setup (use this one)
- **debug-xrdp.sh** - Diagnostic tool for troubleshooting
- **fix-xrdp.sh** - Fix XRDP startup issues
- **fix-xrdp-desktop.sh** - Fix missing desktop issues
- **fix-xrdp-xorg.sh** - Fix Xorg crashes

## Summary

The `setup-desktop-vm-new.sh` script provides a **complete, production-ready setup** that includes:

- ✅ All XRDP fixes and configurations
- ✅ XFCE4 desktop environment
- ✅ Xorg virtualization support
- ✅ Chrome session isolation
- ✅ Automatic cleanup
- ✅ Proper permissions and security
- ✅ Comprehensive logging

**No manual fixes needed** - everything is handled automatically!

## Next Steps

After completing the setup:

1. ✅ Test RDP connection
2. ✅ Configure master Chrome profile
3. ✅ Test with multiple concurrent users
4. ✅ Set up automatic cleanup
5. ✅ Configure monitoring/logging
6. ✅ Document IP addresses and credentials
7. ✅ Set up backups of master Chrome profile

## Questions or Issues?

If you encounter problems:

1. Check the troubleshooting section above
2. Run the diagnostic script: `sudo ./debug-xrdp.sh`
3. Check logs: `sudo journalctl -u xrdp-sesman -n 100`
4. Verify all steps were completed: Review setup log at `/var/log/desktop-vm-setup.log`

