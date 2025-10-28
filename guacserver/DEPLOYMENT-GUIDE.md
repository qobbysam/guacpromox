# Multi-User Remote Desktop System - Deployment Guide

Complete step-by-step guide for deploying a multi-user remote desktop environment with shared Chrome browser sessions.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Phase 1: VM Setup](#phase-1-vm-setup)
4. [Phase 2: Desktop VM Configuration](#phase-2-desktop-vm-configuration)
5. [Phase 3: Guacamole Setup](#phase-3-guacamole-setup)
6. [Phase 4: Configuration & Testing](#phase-4-configuration--testing)
7. [Phase 5: Cloudflare Tunnel (Optional)](#phase-5-cloudflare-tunnel-optional)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

This system provides:
- Web-based access via Apache Guacamole
- Concurrent user sessions on the same desktop VM
- Shared browser configuration with isolated browsing sessions
- Secure internet access via Cloudflare Tunnel (optional)
- Centralized user management

### Architecture

```
Internet Users
      ↓
Cloudflare Tunnel (HTTPS)
      ↓
Guacamole Server (Authentication & Connection Broker)
      ↓
Desktop VMs (XRDP) → Shared Chrome Config + Isolated Sessions
```

### Expected Timeline
- Phase 1 (VM Creation): 1-2 hours
- Phase 2 (Desktop Setup): 2-3 hours
- Phase 3 (Guacamole): 1-2 hours
- Phase 4 (Configuration): 1 hour
- Phase 5 (Cloudflare): 30 minutes
- **Total**: 5-8 hours

---

## Prerequisites

### Required Resources

**Proxmox Host:**
- Sufficient CPU cores (4+ per VM)
- Sufficient RAM (16GB+ available)
- Sufficient storage (100GB+ per desktop VM)

**Network:**
- Static IP or DHCP reservations for VMs
- Internal network connectivity between Guacamole and Desktop VMs
- Internet access for all VMs

**Accounts:**
- Cloudflare account (free or paid) - for optional internet access
- Domain managed by Cloudflare
- Email accounts/services to configure in Chrome

### Required Knowledge
- Basic Linux administration
- Proxmox VM management
- Basic networking concepts

---

## Phase 1: VM Setup

### 1.1 Create Guacamole Server VM

**Specifications:**
- OS: Ubuntu 22.04 LTS Server
- CPU: 2-4 cores
- RAM: 4-8 GB
- Disk: 32 GB

**Steps:**
1. In Proxmox, create new VM
2. Install Ubuntu 22.04 Server
3. Configure network (DHCP or static IP)
4. Install OpenSSH server
5. Note the IP address

### 1.2 Create Desktop VM Template

**Specifications:**
- OS: Ubuntu 22.04 LTS Desktop
- CPU: 4-6 cores
- RAM: 8-16 GB
- Disk: 50-100 GB

**Steps:**
1. Create VM in Proxmox
2. Install Ubuntu Desktop (Minimal installation)
3. Create user: `shared-desktop`
4. Update system: `sudo apt update && sudo apt upgrade -y`
5. Note the IP address

---

## Phase 2: Desktop VM Configuration

### 2.1 Transfer Scripts to Desktop VM

From your local machine:
```bash
cd guacproject/bmax-desktop
scp setup-desktop-vm.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp post-setup-desktop-vm.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp launch-chrome.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp setup-chrome-master.sh shared-desktop@[DESKTOP-VM-IP]:~/
scp cleanup-chrome-sessions.sh shared-desktop@[DESKTOP-VM-IP]:~/
```

### 2.2 Run Desktop VM Setup

```bash
ssh shared-desktop@[DESKTOP-VM-IP]
chmod +x setup-desktop-vm.sh
sudo ./setup-desktop-vm.sh
```

**Expected output:**
- System packages updated
- XRDP installed and configured
- Google Chrome installed
- Directory structure created
- Firewall configured

### 2.3 Install Chrome Scripts and Create Desktop Shortcut

Run the post-setup script to automatically install Chrome scripts and create the desktop shortcut:

```bash
chmod +x post-setup-desktop-vm.sh
./post-setup-desktop-vm.sh
```

**What this script does:**
- Installs launch-chrome.sh to `/usr/local/bin/`
- Installs cleanup-chrome-sessions.sh to `/usr/local/bin/`
- Copies setup-chrome-master.sh to home directory
- Creates "Chrome (Shared Config)" desktop shortcut
- Sets proper permissions

**Expected output:**
- All Chrome scripts installed and executable
- Desktop shortcut created and trusted
- Scripts ready to use

### 2.4 Configure Master Chrome Profile

This is where you log into all accounts that will be shared:

```bash
# Ensure you're running as shared-desktop user (script will auto-switch if run as root)
./setup-chrome-master.sh
# Log into Gmail, Salesforce, Slack, etc.
# Install required extensions
# Set bookmarks
# Close Chrome when done
```

**Note:** If you run this script as root, it will automatically switch to the `shared-desktop` user to avoid Chrome sandbox issues. Chrome cannot run as root without the `--no-sandbox` flag (which is not recommended for security).

---

## Phase 3: Guacamole Setup

### 3.1 Transfer Scripts to Guacamole Server

From your local machine:
```bash
cd guacproject/guacserver
scp docker-compose.yml root@[GUAC-SERVER-IP]:/root/
scp setup-guacamole.sh root@[GUAC-SERVER-IP]:/root/
scp manage-guacamole.sh root@[GUAC-SERVER-IP]:/root/
scp configure-guacamole.sh root@[GUAC-SERVER-IP]:/root/
scp setup-cloudflare-tunnel.sh root@[GUAC-SERVER-IP]:/root/
```

### 3.2 Install Guacamole

```bash
ssh root@[GUAC-SERVER-IP]
chmod +x setup-guacamole.sh manage-guacamole.sh
sudo ./setup-guacamole.sh
```

**Expected output:**
- Docker installed
- Guacamole stack started
- Database initialized
- Firewall configured

### 3.3 Verify Installation

```bash
# Check services
cd /opt/guacamole
./manage-guacamole.sh status

# Access web interface
# Open browser: http://[GUAC-SERVER-IP]:8080/guacamole/
# Login: guacadmin / guacadmin
```

---

## Phase 4: Configuration & Testing

### 4.1 Configure Guacamole

**Change default password:**
1. Access Guacamole web interface
2. Login as guacadmin
3. Settings → Users → guacadmin
4. Change password and save

**Create user groups:**
1. Settings → Groups → New Group
2. Group name: `admins`
3. Grant permissions (Create connections, users, etc.)
4. Create second group: `regular-users`

**Create RDP connection to desktop VM:**
1. Settings → Connections → New Connection
2. Name: Desktop-1
3. Protocol: RDP
4. Hostname: [Desktop VM IP]
5. Username: shared-desktop
6. Password: [password]
7. Save

**Assign permissions:**
1. Click on connection → Permissions
2. Add group: admins (Read access)
3. Add group: regular-users (Read access)
4. Save

### 4.2 Test Concurrent Access

1. Connect to desktop via Guacamole as User A
2. Open Chrome and verify accounts are logged in
3. From another computer, connect as User B to SAME desktop
4. User B should also be logged into same accounts
5. Both users can browse independently

---

## Phase 5: Cloudflare Tunnel (Optional)

### 5.1 Prerequisites
- Cloudflare account
- Domain added to Cloudflare

### 5.2 Setup Tunnel

```bash
ssh root@[GUAC-SERVER-IP]
./setup-cloudflare-tunnel.sh
# Follow prompts to authenticate and create tunnel
```

### 5.3 Access via Internet

After setup, Guacamole will be accessible at:
`https://your-domain.com/guacamole/`

---

## Troubleshooting

### Desktop VM Issues

**XRDP not connecting:**
```bash
# Check service status
sudo systemctl status xrdp

# Check logs
tail -f /var/log/xrdp.log

# Restart service
sudo systemctl restart xrdp
```

**Chrome not launching:**
```bash
# Check master profile exists
ls -la /opt/chrome-master-profile/Default/

# Check logs
tail -f /var/log/chrome-sessions/*.log

# Reconfigure master profile
./setup-chrome-master.sh
```

### Guacamole Issues

**Containers not starting:**
```bash
cd /opt/guacamole
./manage-guacamole.sh logs
docker compose ps
./manage-guacamole.sh restart
```

**Connection to desktop VM fails:**
1. Verify desktop VM IP is correct
2. Check XRDP is running on desktop VM
3. Verify shared-desktop password
4. Check firewall rules

### Cloudflare Tunnel Issues

**Tunnel not working:**
```bash
# Check service
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Restart
sudo systemctl restart cloudflared
```

---

## Maintenance

### Regular Tasks

**Weekly:**
- Check disk usage on all VMs
- Review logs for errors
- Backup Guacamole database

**Monthly:**
- Update all systems
- Review user permissions
- Clean up old Chrome sessions

### Backup Procedures

**Guacamole database:**
```bash
cd /opt/guacamole
./manage-guacamole.sh backup
```

**Desktop VM master profile:**
```bash
# Copy Chrome master profile
sudo tar -czf chrome-master-profile-backup.tar.gz /opt/chrome-master-profile/
```

---

## Support

For issues not covered in this guide:
- Check README-ADMIN.txt for detailed maintenance procedures
- Review component logs for error messages
- Consult Guacamole documentation: https://guacamole.apache.org/doc/
