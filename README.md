# Multi-User Remote Desktop System

A complete solution for deploying a multi-user remote desktop environment with shared Chrome browser sessions.

## Project Structure

```
guacproject/
├── README.md                    # This file
├── bmax-desktop/                 # Desktop VM components
│   ├── setup-desktop-vm.sh      # VM setup script
│   ├── launch-chrome.sh         # Chrome launcher with session isolation
│   ├── setup-chrome-master.sh   # Master profile configuration
│   ├── cleanup-chrome-sessions.sh # Session cleanup
│   ├── README-DESKTOP.txt       # User guide
│   └── README.md                # Desktop VM documentation
└── guacserver/                   # Guacamole server components
    ├── docker-compose.yml        # Guacamole stack configuration
    ├── setup-guacamole.sh        # Guacamole installation
    ├── manage-guacamole.sh       # Management script
    ├── configure-guacamole.sh    # Configuration guide
    ├── setup-cloudflare-tunnel.sh # Cloudflare setup
    ├── README-ADMIN.txt          # Admin guide
    ├── DEPLOYMENT-GUIDE.md       # Complete deployment guide
    └── README.md                # Server documentation
```

## Quick Start

### 1. Desktop VM Setup

```bash
cd bmax-desktop
# Transfer scripts to Ubuntu Desktop VM
# Run: sudo ./setup-desktop-vm.sh
# Configure master Chrome profile
```

See `bmax-desktop/README.md` for detailed instructions.

### 2. Guacamole Server Setup

```bash
cd guacserver
# Transfer scripts to Ubuntu Server VM
# Run: sudo ./setup-guacamole.sh
# Configure Guacamole via web interface
```

See `guacserver/README.md` for detailed instructions.

### 3. Configuration

Follow the complete deployment guide:
- `guacserver/DEPLOYMENT-GUIDE.md` - Step-by-step instructions
- `guacserver/README-ADMIN.txt` - Administrator maintenance guide

## How It Works

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

### Key Features

**Shared Browser Configuration:**
- Admin configures Chrome once with all accounts (Gmail, Salesforce, etc.)
- Multiple users access the same VM simultaneously
- Each user gets isolated browsing session
- All users already logged into shared accounts

**Concurrent Access:**
- Multiple users can connect to same desktop VM
- Each XRDP session gets unique Chrome profile
- Shared authentication, isolated browsing history
- No conflicts between users

**User Management:**
- Admin users: Access to all desktop VMs
- Regular users: Access to assigned desktop VMs only
- Web-based management via Guacamole

## Components

### Desktop VM (`bmax-desktop`)
- Ubuntu 22.04 Desktop with XRDP
- Google Chrome with session isolation
- Shared user account for concurrent access
- Automatic session cleanup

### Guacamole Server (`guacserver`)
- Web-based remote access gateway
- PostgreSQL database for configuration
- Docker-based deployment
- Cloudflare Tunnel integration (optional)

## Prerequisites

- Proxmox host with VMs
- Ubuntu 22.04 (Desktop and Server)
- Root/sudo access on VMs
- Internet connection
- Optional: Cloudflare account for internet access

## Deployment Steps

1. **Phase 1**: Create VMs in Proxmox (Guacamole server + Desktop template)
2. **Phase 2**: Set up Desktop VM with XRDP and Chrome
3. **Phase 3**: Install and configure Guacamole
4. **Phase 4**: Configure users, groups, and connections
5. **Phase 5**: Test concurrent access
6. **Phase 6**: Set up Cloudflare Tunnel (optional)

See `guacserver/DEPLOYMENT-GUIDE.md` for complete instructions.

## Documentation

- **Deployment Guide**: `guacserver/DEPLOYMENT-GUIDE.md`
- **Admin Guide**: `guacserver/README-ADMIN.txt`
- **User Guide**: `bmax-desktop/README-DESKTOP.txt`
- **Desktop VM Setup**: `bmax-desktop/README.md`
- **Server Setup**: `guacserver/README.md`

## Support

For issues or questions:
- Check the troubleshooting sections in the deployment guide
- Review component logs
- Consult Guacamole documentation: https://guacamole.apache.org/doc/

## License

This project is provided as-is for deployment purposes.
