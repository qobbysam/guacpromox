# Detailed Guide: Adding RDP Connection in Guacamole Dashboard

This guide provides step-by-step instructions for adding an RDP connection to your desktop VM in the Guacamole web interface.

> **📘 Comprehensive Options Reference:**  
> - **Dashboard Guide:** `DASHBOARD-CONFIGURATION-GUIDE.md` - Complete guide to all tabs and options you see in the dashboard
> - **Options PDF:** `guacoption.pdf` - Detailed parameter reference with all descriptions

---

## Prerequisites

Before adding the connection, ensure:
- ✅ Guacamole is running and accessible at `http://[guac-server-ip]:8080/guacamole/`
- ✅ Desktop VM is running and has XRDP configured
- ✅ You know the Desktop VM IP address
- ✅ You know the `shared-desktop` user password
- ✅ You have admin access to Guacamole (guacadmin account)

---

## Step-by-Step Instructions

### Step 1: Access Guacamole Dashboard

1. Open a web browser
2. Navigate to: `http://[GUAC-SERVER-IP]:8080/guacamole/`
   - Replace `[GUAC-SERVER-IP]` with your actual Guacamole server IP
   - Example: `http://192.168.1.100:8080/guacamole/`

3. Log in with administrator credentials:
   - **Username:** `guacadmin`
   - **Password:** `guacadmin` (or your changed password)

---

### Step 2: Navigate to Connections

1. **Click** on **"Settings"** in the top menu bar
   - Located at the top-right of the Guacamole interface

2. In the Settings page, **click** on **"Connections"** in the left sidebar
   - This will show all existing connections (if any)

3. **Click** the **"New Connection"** button
   - Usually located at the top-right of the connections list

---

### Step 3: Configure Basic Connection Settings

A form will appear with multiple tabs. Fill in the **"General"** tab first:

#### General Tab

| Field | Value | Description |
|-------|-------|-------------|
| **Name** | `Desktop-1` | Descriptive name for the connection (you can change this) |
| **Protocol** | `RDP` | Select RDP from the dropdown menu |
| **Parent Group** | `ROOT` | Keep as ROOT (or select a connection group if you created one) |

**Minimum Required Fields:**
- ✅ **Name:** `Desktop-1` (or any name you prefer)
- ✅ **Protocol:** Select `RDP`

**Click "Save" at the bottom** to create the connection skeleton first.

---

### Step 4: Configure Network Settings

After saving, click on the connection name to edit it. Go to the **"Network"** section:

#### Network Settings

| Field | Value | Description |
|-------|-------|-------------|
| **Hostname** | `[DESKTOP-VM-IP]` | IP address of your desktop VM<br>Example: `192.168.1.50` |
| **Port** | `3389` | Standard RDP port (default is 3389) |
| **Domain** | *(leave empty)* | Not needed for this setup |
| **Server Layout** | `en-us-qwerty` | Keyboard layout (default usually works) |

**Important:**
- The **Hostname** must be the IP address of your desktop VM
- To find the Desktop VM IP:
  ```bash
  ssh shared-desktop@[desktop-vm]
  ip addr show | grep "inet "
  ```

---

### Step 5: Configure Authentication

Navigate to the **"Authentication"** section:

#### Authentication Settings

| Field | Value | Description |
|-------|-------|-------------|
| **Username** | `shared-desktop` | The shared user account on the desktop VM |
| **Password** | `[password]` | Password for the shared-desktop user<br>(This is set in setup-desktop-vm.sh) |
| **Domain** | *(leave empty)* | Not needed |

**Important:**
- The username **must** be `shared-desktop` (unless you changed it during VM setup)
- Enter the password that was set during desktop VM setup
- Default password from `setup-desktop-vm.sh` is `ChangeMe123!`

**Security Note:** Consider using Guacamole's parameter tokens for password security (see advanced options below).

---

### Step 6: Configure Display Settings (Recommended)

Navigate to the **"Display"** section:

> **📘 For complete details on all display options**, see `guacoption.pdf` section on RDP display parameters.

#### Display Settings

| Field | Recommended Value | Description |
|-------|-------------------|-------------|
| **Color Depth** | `32` | Full color depth for best quality |
| **Width** | `1920` | Screen width in pixels |
| **Height** | `1080` | Screen height in pixels |
| **DPI** | `96` | Default DPI (usually works) |
| **Desktop Scale** | `100%` | Scale factor |

**Multi-monitor Support:**
- **Enable multi-monitor:** Check if you have multiple monitors
- **Remote Desktop Scale:** Leave at default or adjust for your needs

**Performance Options:**
- **Enable wallpaper:** Uncheck for better performance
- **Enable font smoothing:** Check for better text quality
- **Enable window contents:** Uncheck for better performance
- **Enable desktop composition:** Uncheck for better performance

---

### Step 7: Configure Performance Settings

Navigate to the **"Performance"** section:

> **📘 For complete details on performance tuning options**, see `guacoption.pdf` section on performance parameters.

#### Performance Settings

| Setting | Recommended Value | Description |
|---------|-------------------|-------------|
| **Enable preconnection** | ✓ (checked) | Preconnects for faster startup |
| **Read-only connection** | ✗ (unchecked) | Users need full access |
| **Recording Path** | *(optional)* | Leave empty unless recording sessions |

**RDP-Specific Settings:**
- **Disable bitmap caching:** ✗ (unchecked) - Better performance
- **Disable offscreen caching:** ✗ (unchecked) - Better performance
- **Disable glyph caching:** ✗ (unchecked) - Better performance

---

### Step 8: Configure Session Settings (Important for Concurrent Access)

Navigate to the **"Session"** section:

#### Session Settings

| Setting | Recommended Value | Description |
|---------|-------------------|-------------|
| **Maximum connection time** | `0` | Unlimited connection time (0 = unlimited) |
| **Maximum idle time** | `0` | Unlimited idle time (0 = unlimited) |
| **Disconnect timeout** | `0` | No timeout for disconnection (0 = unlimited) |

**Important for Multi-User Access:**
- Setting these to `0` allows multiple users to stay connected indefinitely
- This is necessary for concurrent access to the same VM

---

### Step 9: Configure Security Settings

Navigate to the **"Security"** section:

#### Security Settings

| Setting | Recommended Value | Description |
|---------|-------------------|-------------|
| **Connection timeout** | `30000` | 30 seconds (30000 milliseconds) |
| **Ignore server certificate** | ✗ (unchecked) | For security, verify certificates |
| **Enable SFTP** | ✓ (optional) | Enable file transfer if needed |
| **SFTP Root Directory** | `/home/shared-desktop` | Base directory for file access |

---

### Step 10: Save and Test Connection

1. **Scroll to the bottom** of the connection form
2. **Click "Save"** or **"Save and Connect"**

3. **Test the connection:**
   - Click **"Home"** in the top menu
   - You should see your connection named "Desktop-1"
   - **Click on it** to test the connection
   - You should see the desktop VM login screen

---

### Step 11: Configure Permissions (Assign to Users/Groups)

After creating the connection, assign permissions:

1. **Click on "Settings"** in the top menu
2. **Click "Connections"** in the left sidebar
3. **Click on your connection** (Desktop-1) to edit it
4. **Click on "Permissions"** tab

#### Assign Permissions

**Option A: Assign to Groups (Recommended)**

1. Click **"Add Group"** or **"Add User"** button
2. Select a group (e.g., `admins`, `regular-users`)
3. Select permission level:
   - **Read:** Users can connect but not modify the connection
   - **Update:** Users can modify connection settings
   - **Delete:** Users can delete the connection
   - **Admin:** Full control

4. Click **"Save"**

**Option B: Assign to Individual Users**

1. Click **"Add User"** button
2. Select user(s) from the list
3. Select permission level
4. Click **"Save"**

**Recommended Setup:**
- **Admins group:** Admin permissions
- **Regular-users group:** Read permissions (can connect but not modify)

---

## Advanced Configuration Options

### Using Parameter Tokens for Password Security

> **📘 For complete information on parameter tokens and all authentication options**, see `guacoption.pdf`.

Instead of storing the password in plain text, use parameter tokens:

1. Go to **Settings → Parameters**
2. Create a new parameter:
   - **Token:** `${shared-desktop-password}`
   - **Value:** `[actual password]`
3. In the connection settings, use `shared-desktop-password` as the token name
4. Guacamole will substitute the value at connection time

**In the connection's Authentication section:**
- **Username:** `shared-desktop`
- **Password:** `${shared-desktop-password}` (use the token)

### Connection Groups

To organize multiple desktop VMs:

1. **Settings → Connection Groups → New Connection Group**
2. Name: `Desktop VMs`
3. Add connections to this group
4. Assign permissions to the group (inherited by all connections)

### Connection Templates

For multiple similar connections, use templates:

1. Create first connection with all settings
2. Create new connection from template
3. Only change Hostname and Name
4. All other settings are copied

---

## Troubleshooting Connection Issues

### "Connection Refused" or "Cannot Connect"

**Check Desktop VM:**
```bash
# SSH to desktop VM
ssh shared-desktop@[desktop-vm-ip]

# Check if XRDP is running
sudo systemctl status xrdp

# Check if port 3389 is open
sudo ufw status | grep 3389
```

**Check Network:**
```bash
# From Guacamole server, test connectivity
telnet [desktop-vm-ip] 3389

# Or using netcat
nc -zv [desktop-vm-ip] 3389
```

### "Authentication Failed"

1. Verify username: `shared-desktop`
2. Verify password (check `setup-desktop-vm.sh` or reset it):
   ```bash
   sudo passwd shared-desktop
   ```
3. Test login directly from another machine using RDP client

### "Connection Timeout"

1. Check firewall on desktop VM:
   ```bash
   sudo ufw allow 3389/tcp
   sudo ufw reload
   ```

2. Check if XRDP is listening:
   ```bash
   sudo netstat -tlnp | grep 3389
   ```

### "Display Issues" or "Slow Performance"

1. Adjust display settings:
   - Reduce color depth to 16-bit
   - Reduce resolution (e.g., 1280x720)
   - Disable wallpaper and desktop composition

2. Adjust performance settings:
   - Enable bitmap caching
   - Adjust connection timeout

---

## Complete Configuration Summary

Here's a quick reference for all important settings:

```yaml
Connection Name: Desktop-1
Protocol: RDP

Network:
  Hostname: [DESKTOP-VM-IP]
  Port: 3389

Authentication:
  Username: shared-desktop
  Password: [PASSWORD]

Display:
  Color Depth: 32
  Resolution: 1920x1080
  Enable wallpaper: No
  Enable font smoothing: Yes

Performance:
  Enable preconnection: Yes
  Disable bitmap caching: No

Session:
  Maximum connection time: 0 (unlimited)
  Maximum idle time: 0 (unlimited)
  
Security:
  Connection timeout: 30000
  Enable SFTP: Yes (optional)

Permissions:
  admins: Admin
  regular-users: Read
```

---

## Testing the Connection

### Test Single User

1. Log in to Guacamole
2. Click on "Desktop-1" connection
3. Enter credentials if prompted
4. Verify desktop loads
5. Test Chrome by clicking desktop shortcut

### Test Concurrent Users

1. **User A:** Connect to Desktop-1 via Guacamole
2. **User B:** From different browser/computer, connect to Desktop-1
3. Both should see separate desktop sessions
4. Both should be able to open Chrome independently
5. Both should be logged into same accounts in Chrome

### Verify Chrome Configuration

1. Connect via Guacamole
2. Double-click "Chrome (Shared Config)" desktop shortcut
3. Verify accounts are logged in (Gmail, Salesforce, etc.)
4. Verify extensions are installed
5. Verify bookmarks are present

---

## Maintenance

### Changing the Password

If you change the `shared-desktop` password on the VM:

1. **Settings → Connections → Desktop-1**
2. **Authentication tab**
3. Update the password field
4. **Save**

Or use parameter tokens (recommended).

### Adding Additional Desktop VMs

1. Repeat the same process
2. Use different names: Desktop-2, Desktop-3, etc.
3. Use different hostnames (IP addresses)
4. Put in a connection group for organization

### Connection Monitoring

View active connections:
- **Settings → Active Connections**
- See who is connected
- Disconnect sessions if needed

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│ ADDING RDP CONNECTION IN GUACAMOLE             │
├─────────────────────────────────────────────────┤
│ 1. Settings → Connections → New Connection     │
│ 2. Name: Desktop-1                              │
│ 3. Protocol: RDP                                │
│ 4. Network: Hostname = [VM-IP], Port = 3389    │
│ 5. Auth: Username = shared-desktop              │
│ 6. Display: 1920x1080, Color Depth = 32        │
│ 7. Session: All timeouts = 0 (unlimited)       │
│ 8. Permissions: Assign to groups/users         │
│ 9. Save and Test                                │
└─────────────────────────────────────────────────┘
```

---

## Additional Resources

- **📘 Complete Options Reference:** `../guacoption.pdf` - Comprehensive PDF with all Guacamole connection options and detailed descriptions
- **Admin Guide:** `README-ADMIN.txt`
- **Deployment Guide:** `DEPLOYMENT-GUIDE.md`
- **Desktop VM Setup:** `../bmax-desktop/readme.md`
- **Guacamole Documentation:** https://guacamole.apache.org/doc/

### About guacoption.pdf

The `guacoption.pdf` file contains:
- Complete listing of all connection parameters
- Detailed descriptions of each option
- RDP-specific configuration options
- Advanced settings and their effects
- Protocol-specific parameters
- Performance tuning options
- Security configuration details

**When to use this guide vs. the PDF:**
- **This guide** (`GUACAMOLE-RDP-SETUP.md`): Step-by-step walkthrough for setting up a connection with recommended values for the shared-desktop setup
- **guacoption.pdf**: Reference manual for exploring all available options and understanding what each parameter does in detail

---

## Support

If you encounter issues:
1. Check Guacamole logs: `docker compose logs guacamole`
2. Check Desktop VM logs: `/var/log/xrdp-sesman.log`
3. Verify network connectivity
4. Test RDP connection directly (using Windows Remote Desktop or rdesktop)

---

*Last Updated: Based on Guacamole 1.5.4*

