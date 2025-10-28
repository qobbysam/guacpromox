# Complete Guacamole Dashboard Configuration Guide

This guide explains how to configure **all available options** when creating or editing a connection in the Guacamole web dashboard. The options are organized by tabs/sections as they appear in the interface.

> **📘 For detailed descriptions of each option**, see `guacoption.pdf` which contains exhaustive documentation of every parameter.

---

## Accessing Connection Configuration

1. **Log in** to Guacamole: `http://[server-ip]:8080/guacamole/`
2. **Settings** → **Connections**
3. **New Connection** (or click existing connection to edit)
4. Configure options in the tabs below

---

## Tab 1: General

Basic connection identification and protocol selection.

| Option | Description | Example Value |
|--------|-------------|---------------|
| **Name** | Display name for the connection | `Desktop-1` |
| **Parent Group** | Organize connection in a group | `ROOT` or `Desktop VMs` |
| **Protocol** | Connection protocol type | `RDP`, `VNC`, `SSH`, `Telnet` |
| **Balance** | Load balancing group (if configured) | Leave empty |

**Required:** Name and Protocol

---

## Tab 2: Parameters

Protocol-specific connection parameters. These vary by protocol.

### For RDP Connections

#### Network Parameters

| Parameter | Description | Recommended Value | Required |
|-----------|-------------|-------------------|----------|
| `hostname` | Desktop VM IP address | `192.168.1.50` | ✅ Yes |
| `port` | RDP port | `3389` | ✅ Yes |
| `domain` | Windows domain (usually empty) | *(leave empty)* | No |
| `server-layout` | Keyboard layout | `en-us-qwerty` | No |

#### Authentication & Security

| Parameter | Description | Recommended Value | Required |
|-----------|-------------|-------------------|----------|
| `username` | Login username | `shared-desktop` | ✅ Yes |
| `password` | Login password | `[your-password]` | ✅ Yes |
| `security` | Security mode | `rdp`, `tls`, `nla`, `any` | No |
| `ignore-cert` | Ignore certificate errors | `true` or `false` | No |
| `gateway-hostname` | RD Gateway hostname | *(if using gateway)* | No |
| `gateway-port` | RD Gateway port | `443` (if using gateway) | No |
| `gateway-domain` | RD Gateway domain | *(if using gateway)* | No |
| `gateway-username` | RD Gateway username | *(if using gateway)* | No |
| `gateway-password` | RD Gateway password | *(if using gateway)* | No |

#### Display Settings

| Parameter | Description | Recommended Value |
|-----------|-------------|-------------------|
| `width` | Screen width in pixels | `1920` |
| `height` | Screen height in pixels | `1080` |
| `dpi` | Dots per inch | `96` |
| `color-depth` | Color bit depth | `8`, `16`, `24`, `32` |
| `scale` | Desktop scale factor | `100` |
| `resolution` | Screen resolution preset | `1024x768`, `1920x1080`, etc. |

#### Performance Settings

| Parameter | Description | Recommended Value |
|-----------|-------------|-------------------|
| `enable-wallpaper` | Show desktop wallpaper | `false` (better performance) |
| `enable-theming` | Enable visual themes | `false` (better performance) |
| `enable-font-smoothing` | Smooth fonts | `true` (better readability) |
| `enable-full-window-drag` | Show window content while dragging | `false` |
| `enable-desktop-composition` | Enable Aero effects | `false` |
| `enable-menu-animations` | Animate menus | `false` |
| `bitmap-caching` | Enable bitmap caching | `true` |
| `offscreen-caching` | Cache offscreen bitmaps | `true` |
| `glyph-caching` | Cache text glyphs | `true` |
| `preconnection-id` | Preconnection ID for load balancing | *(if needed)* |

#### Session Settings

| Parameter | Description | Recommended Value |
|-----------|-------------|-------------------|
| `timeout` | Connection timeout (milliseconds) | `30000` (30 seconds) |
| `read-only` | Read-only mode (no input allowed) | `false` |
| `recording-path` | Path to store session recordings | `/path/to/recordings` |
| `recording-name` | Recording filename pattern | `recording-{TIMESTAMP}` |
| `create-recording-path` | Auto-create recording directory | `true` |

**Important for Multi-User Access:**
```yaml
timeout: 0  # No timeout (unlimited connection time)
```

#### Device Redirection

| Parameter | Description | Recommended Value |
|-----------|-------------|-------------------|
| `enable-drive` | Enable drive redirection (file sharing) | `true` |
| `drive-path` | Path to shared drive | `/tmp/guacamole` |
| `create-drive-path` | Auto-create drive path | `true` |
| `enable-printer` | Enable printer redirection | `false` |
| `enable-sound` | Enable audio redirection | `false` |
| `sound-scheme` | Audio scheme | `rdp`, `pulse`, etc. |
| `enable-microphone` | Enable microphone | `false` |
| `enable-camera` | Enable webcam redirection | `false` |

#### RemoteApp (Advanced)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `remote-app` | RemoteApp program to launch | `notepad.exe` |
| `remote-app-dir` | Working directory for RemoteApp | `C:\Users` |
| `remote-app-args` | Arguments for RemoteApp | `filename.txt` |

---

## Tab 3: Network

Network connection settings and timeouts.

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Preconnection** | Preconnect before user opens connection | `Enable` for faster access |
| **Maximum connection count** | Max concurrent connections | `0` (unlimited) |
| **Maximum connections per user** | Max per individual user | `0` (unlimited) |

---

## Tab 4: Session

Session duration and behavior settings.

| Option | Description | Recommended Value | Notes |
|--------|-------------|-------------------|-------|
| **Maximum connection time** | Max session duration | `0` (unlimited) | Required for long sessions |
| **Maximum idle time** | Max idle before disconnect | `0` (unlimited) | Allow users to stay idle |
| **Disconnect timeout** | Time after disconnect before session ends | `0` (unlimited) | For concurrent access |

**Critical for Multi-User Desktop VMs:**
- Set **all timeouts to `0`** (unlimited)
- This allows multiple users to connect and stay connected indefinitely

---

## Tab 5: Display

Display and performance optimization settings.

### Display Options

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Color depth** | Bits per pixel | `32` (best quality) |
| **Width** | Screen width (pixels) | `1920` |
| **Height** | Screen height (pixels) | `1080` |
| **DPI** | Dots per inch | `96` (standard) |
| **Desktop scale** | Scale percentage | `100%` |

### Performance Options

| Option | Description | Recommended Value | Impact |
|--------|-------------|-------------------|--------|
| **Enable wallpaper** | Show desktop background | ❌ Unchecked | Faster |
| **Enable font smoothing** | Smooth text rendering | ✅ Checked | Better readability |
| **Enable window contents** | Show content while dragging | ❌ Unchecked | Faster |
| **Enable desktop composition** | Enable visual effects | ❌ Unchecked | Faster |
| **Enable menu animations** | Animate menus | ❌ Unchecked | Faster |

### Cache Settings

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Bitmap caching** | Cache images | ✅ Enabled |
| **Offscreen caching** | Cache offscreen graphics | ✅ Enabled |
| **Glyph caching** | Cache text characters | ✅ Enabled |

---

## Tab 6: Performance

Connection performance and optimization.

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Enable preconnection** | Connect before user opens | ✅ Enabled |
| **Read-only connection** | Prevent user input | ❌ Disabled |
| **Recording path** | Where to save recordings | *(optional)* |

---

## Tab 7: Security

Security and authentication options.

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Connection timeout** | Time to wait for connection (ms) | `30000` (30 seconds) |
| **Ignore server certificate** | Don't validate SSL certs | ❌ Unchecked |
| **Enable SFTP** | Enable file transfer | ✅ Enabled |
| **SFTP Root Directory** | Base directory for file access | `/home/shared-desktop` |

---

## Tab 8: Restrictions

Connection and access restrictions.

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Maximum connections** | Total concurrent connections | `0` (unlimited) |
| **Maximum connections per user** | Per-user limit | `0` (unlimited) |
| **Start date** | First date connection is available | *(leave empty)* |
| **End date** | Last date connection is available | *(leave empty)* |
| **Start time** | Daily start time (HH:MM) | `00:00` (all day) |
| **End time** | Daily end time (HH:MM) | `23:59` (all day) |
| **Days allowed** | Days of week allowed | All days checked |

---

## Tab 9: Sharing

Connection sharing and clipboard settings.

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| **Disable clipboard** | Prevent clipboard access | ❌ Disabled |
| **Disable download** | Prevent file downloads | ❌ Disabled |
| **Disable upload** | Prevent file uploads | ❌ Disabled |
| **Disable printing** | Prevent printing | ❌ Disabled |

---

## Recommended Configuration for Shared Desktop VMs

### Quick Setup Template

Use these settings for optimal multi-user desktop VM access:

```yaml
General:
  Name: Desktop-1
  Protocol: RDP
  Parent Group: ROOT

Parameters:
  hostname: [DESKTOP-VM-IP]
  port: 3389
  username: shared-desktop
  password: [PASSWORD]
  
  # Display
  width: 1920
  height: 1080
  color-depth: 32
  
  # Performance
  enable-wallpaper: false
  enable-theming: false
  enable-font-smoothing: true
  enable-desktop-composition: false
  bitmap-caching: true
  
  # File transfer
  enable-drive: true
  drive-path: /tmp/guacamole

Network:
  Preconnection: Enabled
  Maximum connections: 0 (unlimited)
  Maximum per user: 0 (unlimited)

Session:
  Maximum connection time: 0 (unlimited)
  Maximum idle time: 0 (unlimited)
  Disconnect timeout: 0 (unlimited)

Security:
  Connection timeout: 30000
  Enable SFTP: true
  SFTP Root Directory: /home/shared-desktop
```

---

## Step-by-Step Configuration

### 1. Create Connection

1. Click **Settings** → **Connections**
2. Click **New Connection**
3. Fill in **General** tab:
   - Name: `Desktop-1`
   - Protocol: Select `RDP`
   - Click **Save** (creates connection skeleton)

### 2. Configure Network Connection

1. Click on your connection name to edit
2. In **Parameters** tab, find **Network** section:
   - **hostname:** Enter Desktop VM IP address
   - **port:** `3389` (default RDP port)

### 3. Configure Authentication

1. In **Parameters** tab, find **Authentication** section:
   - **username:** `shared-desktop`
   - **password:** Enter the password

   **Security Tip:** Consider using **Parameter Tokens** instead of plain password:
   - Create token: Settings → Parameters → New Parameter
   - Token: `${shared-desktop-password}`
   - Use token in connection: `${shared-desktop-password}`

### 4. Configure Display

1. In **Parameters** tab, find **Display** section:
   - **width:** `1920`
   - **height:** `1080`
   - **color-depth:** `32`
   - **dpi:** `96`

2. In **Performance** section:
   - Uncheck `enable-wallpaper`
   - Uncheck `enable-desktop-composition`
   - Check `enable-font-smoothing`
   - Check `bitmap-caching`

### 5. Configure Session Duration

1. Go to **Session** tab:
   - **Maximum connection time:** `0` (unlimited)
   - **Maximum idle time:** `0` (unlimited)
   - **Disconnect timeout:** `0` (unlimited)

   **Why unlimited?** Multiple users need to stay connected for long periods. Setting timeouts would disconnect them.

### 6. Enable File Transfer

1. In **Parameters** tab, find **Device Redirection**:
   - Check `enable-drive`
   - **drive-path:** `/tmp/guacamole` (or custom path)
   - Check `create-drive-path`

2. In **Security** tab:
   - Check **Enable SFTP**
   - **SFTP Root Directory:** `/home/shared-desktop`

### 7. Set Permissions

1. Click **Permissions** tab
2. Click **Add Group** or **Add User**
3. Select group/user and permission level:
   - **Read:** Can connect but not modify
   - **Update:** Can modify connection settings
   - **Delete:** Can delete connection
   - **Admin:** Full control

4. Recommended:
   - **admins** group → **Admin** permissions
   - **regular-users** group → **Read** permissions

### 8. Save and Test

1. Click **Save** at bottom of form
2. Go to **Home** page
3. Click on connection name to test
4. Verify connection works correctly

---

## Advanced Configuration Examples

### High-Performance Configuration

For maximum performance over slow networks:

```yaml
Display:
  color-depth: 16  # Reduce from 32
  
Performance:
  enable-wallpaper: false
  enable-theming: false
  enable-desktop-composition: false
  enable-menu-animations: false
  bitmap-caching: true
  offscreen-caching: true
  glyph-caching: true
```

### Security-Focused Configuration

For restricted access:

```yaml
Session:
  Maximum connection time: 480  # 8 hours max
  Maximum idle time: 60  # 1 hour idle timeout

Restrictions:
  Start time: 08:00  # Business hours only
  End time: 18:00
  Days allowed: Monday-Friday only

Sharing:
  Disable clipboard: true
  Disable download: false  # Allow downloads
  Disable upload: true  # Prevent uploads
```

### Multi-Monitor Configuration

For users with multiple monitors:

```yaml
Display:
  # Set to match your setup
  width: 3840  # If dual 1920x1080 monitors
  height: 1080
  # OR use resolution preset for common multi-monitor setups
```

---

## Parameter Tokens (Advanced)

Instead of hardcoding passwords, use tokens:

### Creating a Token

1. **Settings** → **Parameters** → **New Parameter**
2. **Token:** `shared-desktop-password`
3. **Value:** `[actual password]`
4. **Save**

### Using Token in Connection

1. Edit connection → **Parameters** tab
2. **password:** `${shared-desktop-password}`
3. Guacamole will substitute the value at connection time

**Benefits:**
- Centralized password management
- Easy password updates (change token, not connections)
- More secure (can restrict who can view parameters)

---

## Common Configuration Patterns

### Pattern 1: Standard Desktop Access

```yaml
# For typical desktop VM with file sharing
- Standard RDP (port 3389)
- Full display (1920x1080, 32-bit color)
- Unlimited session time
- Drive redirection enabled
- SFTP enabled
- No restrictions
```

### Pattern 2: Read-Only Terminal

```yaml
# For viewing-only access
- Standard RDP
- Read-only connection: Enabled
- Disable clipboard: Enabled
- Disable download: Enabled
- Disable upload: Enabled
```

### Pattern 3: Time-Restricted Access

```yaml
# Business hours only
- Standard RDP
- Start time: 08:00
- End time: 18:00
- Days: Monday-Friday
- Maximum connection time: 480 (8 hours)
```

### Pattern 4: High Security

```yaml
# Maximum restrictions
- Standard RDP with NLA security
- Time restrictions (business hours)
- Idle timeout: 30 minutes
- Maximum connection time: 8 hours
- All sharing disabled
- Read-only optional
```

---

## Troubleshooting Configuration

### Connection Refused

**Symptom:** Cannot connect to desktop VM

**Check:**
1. **hostname** is correct IP address
2. **port** matches XRDP port (usually 3389)
3. Desktop VM firewall allows port 3389
4. XRDP service is running on desktop VM

**Test:**
```bash
# From Guacamole server, test connectivity
telnet [desktop-vm-ip] 3389
```

### Authentication Failed

**Symptom:** Connection attempts fail with auth error

**Check:**
1. **username** is correct (`shared-desktop`)
2. **password** is correct
3. User exists on desktop VM
4. User has permission to log in via RDP

**Verify on Desktop VM:**
```bash
# Check user exists
id shared-desktop

# Test password
su - shared-desktop
```

### Poor Performance

**Symptom:** Slow, laggy connection

**Optimize:**
1. Reduce **color-depth** to 16-bit
2. Disable **wallpaper**, **theming**, **desktop composition**
3. Enable all **caching** options
4. Reduce **resolution** if network is slow

### Connection Timeouts

**Symptom:** Connection closes after period of time

**Fix:**
1. **Session** tab → Set all timeouts to `0` (unlimited)
2. Check **Restrictions** tab → Verify time windows allow access
3. Check **Network** tab → Increase connection timeout

### File Transfer Not Working

**Symptom:** Cannot upload/download files

**Enable:**
1. **Parameters** → **Device Redirection**:
   - `enable-drive`: `true`
   - `drive-path`: Set valid path
   - `create-drive-path`: `true`
2. **Security** tab:
   - **Enable SFTP:** Checked
   - **SFTP Root Directory:** Set accessible path

---

## Quick Reference Checklist

When creating a new RDP connection, ensure:

- [ ] **General:** Name and Protocol set
- [ ] **Parameters:** hostname, port, username, password
- [ ] **Parameters:** Display settings (resolution, color depth)
- [ ] **Session:** All timeouts set to 0 (unlimited)
- [ ] **Security:** SFTP enabled if file transfer needed
- [ ] **Parameters:** Drive redirection enabled if file sharing needed
- [ ] **Permissions:** Users/groups assigned
- [ ] Connection tested and working

---

## Additional Resources

- **📘 Detailed Parameter Reference:** `../guacoption.pdf` - Every option explained in detail
- **Configuration Reference:** `CONFIGURATION-REFERENCE.md` - Docker/server configuration
- **RDP Setup Guide:** `GUACAMOLE-RDP-SETUP.md` - Step-by-step connection creation
- **Official Docs:** https://guacamole.apache.org/doc/gug/configuring-guacamole.html

---

*Last Updated: Based on Guacamole 1.5.4 Dashboard Interface*

