# Desktop VM Setup Package

This directory contains all scripts and documentation needed to set up Ubuntu Desktop VMs for multi-user remote desktop access with shared Chrome browser sessions.

## Files in this package

- **setup-desktop-vm.sh** - Main setup script for configuring Ubuntu Desktop VM with XRDP and Chrome
- **launch-chrome.sh** - Chrome launcher with session isolation for concurrent users
- **setup-chrome-master.sh** - Helper script for configuring the master Chrome profile
- **cleanup-chrome-sessions.sh** - Automatic cleanup script for old Chrome sessions
- **README-DESKTOP.txt** - User guide for end users

## Quick Start

1. **Transfer scripts to the Ubuntu Desktop VM:**
   ```bash
   scp setup-desktop-vm.sh shared-desktop@[VM-IP]:~/
   scp launch-chrome.sh shared-desktop@[VM-IP]:~/
   scp setup-chrome-master.sh shared-desktop@[VM-IP]:~/
   scp cleanup-chrome-sessions.sh shared-desktop@[VM-IP]:~/
   ```

2. **Run the setup script:**
   ```bash
   ssh shared-desktop@[VM-IP]
   chmod +x setup-desktop-vm.sh
   sudo ./setup-desktop-vm.sh
   ```

3. **Install the Chrome scripts:**
   ```bash
   sudo cp launch-chrome.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/launch-chrome.sh
   
   sudo cp cleanup-chrome-sessions.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/cleanup-chrome-sessions.sh
   
   cp setup-chrome-master.sh /home/shared-desktop/
   ```

4. **Configure the master Chrome profile:**
   ```bash
   cd ~/
   ./setup-chrome-master.sh
   # Log into all required accounts (Gmail, Salesforce, etc.)
   # Close Chrome when done
   ```

5. **Create desktop shortcut:**
   ```bash
   cat > ~/Desktop/Chrome-Shared.desktop <<'EOF'
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=Chrome (Shared Config)
   Comment=Launch Chrome with shared configuration
   Exec=/usr/local/bin/launch-chrome.sh
   Icon=google-chrome
   Terminal=false
   Categories=Network;WebBrowser;
   EOF
   
   chmod +x ~/Desktop/Chrome-Shared.desktop
   gio set ~/Desktop/Chrome-Shared.desktop metadata::trusted true
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
