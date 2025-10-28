# LLM Prompt: Multi-User Remote Desktop System with Shared Browser Sessions

## System Requirements

Create a complete automation system for deploying a multi-user remote desktop environment on Proxmox with the following architecture:

### Architecture Overview
- **Proxmox Host**: Running multiple Ubuntu Desktop VMs
- **Guacamole Server**: Web-based remote access gateway (separate Ubuntu Server VM)
- **Desktop VMs**: Ubuntu Desktop with XRDP for concurrent user access
- **Access Method**: Cloudflare Tunnel exposing Guacamole to internet

### Core Functionality Requirements

**1. Shared Browser Configuration with Concurrent Access:**
- Administrator configures Chrome browser ONCE in a "master profile" (logs into Gmail, Salesforce, Slack, etc.)
- Multiple users connect simultaneously via XRDP to the same VM/account
- Each user gets their own isolated Chrome session BUT with all logins already active
- User A opens Chrome → Already logged into all accounts → Works independently
- User B opens Chrome (at same time) → Also already logged into same accounts → Works independently
- Both users can use the same email/web accounts concurrently without interfering with each other
- Browser state (tabs, history, current browsing) is isolated per user
- Saved passwords, cookies, login sessions, bookmarks, and extensions are shared from master profile

**2. User Management in Guacamole:**
- Admin users: Can view and access ALL desktop VMs
- Regular users: Can only access their assigned desktop VMs
- Multiple concurrent XRDP sessions per desktop VM must work
- Single "shared-desktop" user account per VM (not separate Linux accounts per user)

**3. Desktop VM Organization:**
- Multiple desktop VMs for different purposes (Marketing Desktop, Development Desktop, Sales Desktop, etc.)
- Each VM can handle multiple concurrent XRDP connections
- Chrome launcher script ensures each XRDP session gets isolated Chrome profile with shared configuration

**4. Network Architecture:**
- Guacamole VM hosted locally on Proxmox
- Desktop VMs on same local network as Guacamole
- Guacamole exposed to internet via Cloudflare Tunnel (not cloud-hosted)
- Low latency: Guacamole → Desktop VMs communication stays on local network

## Technical Implementation Requirements

### Chrome Session Isolation Mechanism
Create a launcher script that:
1. Stores master Chrome profile in `/opt/chrome-master-profile`
2. On each XRDP session start, creates unique profile in `/opt/chrome-sessions/session-{unique-id}`
3. Syncs these items FROM master profile TO session profile:
   - Login cookies (so users are auto-logged in)
   - Saved passwords
   - Bookmarks
   - Extensions
   - Browser preferences
   - Session cookies for web apps
4. Syncs these items BACK to master profile on session close:
   - Updated bookmarks
   - Updated preferences (optional)
5. Each Chrome instance uses `--user-data-dir` flag to use session-specific profile
6. Automatic cleanup of old session profiles (7+ days old)

### Desktop VM Setup Script
Generate a bash script that:
- Installs Ubuntu Desktop (assumes already installed)
- Installs and configures XRDP for concurrent sessions
- Installs Google Chrome
- Creates shared user account (e.g., "shared-desktop")
- Creates directory structure for master profile and session profiles
- Installs Chrome launcher script at `/usr/local/bin/launch-chrome.sh`
- Creates desktop shortcut for "Chrome (Shared Config)"
- Creates helper script for administrator to setup master profile
- Configures automatic session cleanup via cron
- Sets appropriate permissions
- Provides README with instructions

### Guacamole Setup Script
Generate a bash script that:
- Installs Docker and Docker Compose
- Deploys Guacamole using Docker containers (guacd, PostgreSQL, Guacamole)
- Initializes PostgreSQL database with Guacamole schema
- Exposes Guacamole on port 8080
- Creates management scripts (start, stop, restart, backup, logs, update)
- Provides configuration guide for:
  - Creating user groups (admins, regular-users)
  - Creating RDP connections to desktop VMs
  - Assigning permissions to users/groups
  - Changing default passwords
- Creates systemd service for auto-start

### Cloudflare Tunnel Setup
Generate instructions/script for:
- Installing cloudflared on Guacamole VM
- Authenticating with Cloudflare
- Creating tunnel configuration
- Routing domain to Guacamole (http://localhost:8080)
- Installing as system service

### Deployment Guide
Generate a comprehensive markdown guide that includes:
1. **Phase 1**: Proxmox VM creation (specs for Guacamole VM and Desktop VMs)
2. **Phase 2**: Desktop VM template setup
   - Running setup script
   - Configuring master Chrome profile (step-by-step)
   - Testing XRDP concurrent connections
   - Verifying Chrome session isolation
   - Cloning template for multiple desktop VMs
3. **Phase 3**: Guacamole installation and configuration
   - Running setup script
   - Changing default passwords
   - Creating user groups
   - Creating RDP connections for each desktop VM
   - Assigning permissions
4. **Phase 4**: Cloudflare Tunnel setup
5. **Phase 5**: Testing and validation
6. **Phase 6**: Maintenance procedures

## Expected Outputs

Generate the following files:

1. **setup-desktop-vm.sh** - Complete desktop VM configuration script
2. **launch-chrome.sh** - Chrome launcher with session isolation
3. **setup-chrome-master.sh** - Helper script for admin to configure master profile
4. **cleanup-chrome-sessions.sh** - Cleanup script for old sessions
5. **setup-guacamole.sh** - Guacamole installation and setup script
6. **manage-guacamole.sh** - Management script for Guacamole operations
7. **configure-guacamole.sh** - Interactive guide for Guacamole configuration
8. **docker-compose.yml** - Docker Compose file for Guacamole stack
9. **setup-cloudflare-tunnel.sh** - Cloudflare Tunnel installation and configuration
10. **DEPLOYMENT-GUIDE.md** - Complete step-by-step deployment guide
11. **README-DESKTOP.txt** - Instructions for desktop VM users
12. **README-ADMIN.txt** - Administrator maintenance guide

## Key Technical Constraints

- Ubuntu 22.04 LTS for all VMs
- XRDP must support multiple concurrent sessions to same user account
- Chrome launcher must handle concurrent access without profile locking conflicts
- Master profile cookies must remain valid when copied to session profiles
- Session profiles must be truly isolated (separate processes, separate data directories)
- No browser storage APIs (localStorage, sessionStorage) limitations apply - this is native Chrome
- Guacamole must be deployed via Docker for easier management
- All scripts must include error handling and logging
- Security best practices (firewall rules, password changes, permission settings)

## Success Criteria

The system is successful when:
- Administrator can configure Chrome once with all logins
- Multiple users can connect simultaneously to same desktop VM
- Each user gets their own Chrome window with all accounts already logged in
- Users can browse independently without seeing each other's tabs/history
- All users can use the same web accounts (email, CRM, etc.) concurrently
- Guacamole correctly shows different desktop connections based on user permissions
- System is accessible from internet via Cloudflare Tunnel
- Everything is automated via provided scripts

## Additional Considerations

- Include logging for debugging (Chrome launcher logs, XRDP logs)
- Provide troubleshooting section in deployment guide
- Include backup/restore procedures for Guacamole database
- Document how to add new desktop VMs to existing setup
- Explain how to update master Chrome profile after initial setup
- Security hardening recommendations (MFA, Cloudflare Access, firewall rules)
- Performance tuning options (XRDP optimization, Chrome flags)

---

## Output Format

Provide all scripts with:
- Comprehensive comments explaining each section
- Color-coded output for better readability
- Error handling and validation
- Status messages during execution
- Clear next steps at completion

Provide deployment guide with:
- Clear section headers
- Command examples with expected output
- Screenshots descriptions where helpful
- Troubleshooting section for common issues
- Testing/validation procedures