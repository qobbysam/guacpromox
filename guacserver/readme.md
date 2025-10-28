# Guacamole Server Setup Package

This directory contains all scripts and documentation needed to set up Apache Guacamole as a web-based remote desktop gateway.

## Files in this package

- **docker-compose.yml** - Docker Compose configuration for Guacamole stack
- **setup-guacamole.sh** - Installation script for Guacamole
- **manage-guacamole.sh** - Management script for Guacamole operations
- **configure-guacamole.sh** - Interactive configuration guide
- **setup-cloudflare-tunnel.sh** - Cloudflare Tunnel setup for internet access
- **README-ADMIN.txt** - Administrator maintenance guide

## Quick Start

1. **Copy files to the Guacamole server VM:**
   ```bash
   scp docker-compose.yml root@[GUAC-SERVER-IP]:/root/
   scp setup-guacamole.sh root@[GUAC-SERVER-IP]:/root/
   scp manage-guacamole.sh root@[GUAC-SERVER-IP]:/root/
   scp configure-guacamole.sh root@[GUAC-SERVER-IP]:/root/
   scp setup-cloudflare-tunnel.sh root@[GUAC-SERVER-IP]:/root/
   ```

2. **Run the setup script:**
   ```bash
   ssh root@[GUAC-SERVER-IP]
   chmod +x setup-guacamole.sh
   chmod +x manage-guacamole.sh
   chmod +x configure-guacamole.sh
   chmod +x setup-cloudflare-tunnel.sh
   
   sudo ./setup-guacamole.sh
   ```

3. **Access Guacamole:**
   - Open browser: http://[GUAC-SERVER-IP]:8080/guacamole/
   - Login: guacadmin / guacadmin
   - Change password immediately!

4. **Configure Guacamole:**
   ```bash
   ./configure-guacamole.sh
   ```

5. **Set up Cloudflare Tunnel (optional):**
   ```bash
   sudo ./setup-cloudflare-tunnel.sh
   ```

## Architecture

```
Internet Users
      ↓
Cloudflare Tunnel (HTTPS) [Optional]
      ↓
Guacamole Server (Authentication & Connection Broker)
      ↓
Desktop VMs (XRDP) with Shared Chrome Config
```

## Management Commands

```bash
# Start/Stop/Restart
./manage-guacamole.sh start
./manage-guacamole.sh stop
./manage-guacamole.sh restart

# Check status
./manage-guacamole.sh status

# View logs
./manage-guacamole.sh logs

# Backup database
./manage-guacamole.sh backup

# Update Guacamole
./manage-guacamole.sh update
```

## Configuration Steps

1. **Change default password** (Security critical!)
2. **Create user groups** (admins, regular-users)
3. **Create RDP connections** to desktop VMs
4. **Assign permissions** to users/groups
5. **Test concurrent access**

See README-ADMIN.txt for detailed instructions.

## Next Steps

After basic setup:
1. Create at least 2 user groups (admins and regular-users)
2. Add RDP connections for each desktop VM
3. Test with multiple concurrent users
4. Set up Cloudflare Tunnel for secure internet access
5. Configure automated backups

## For more information

- Administrator guide: README-ADMIN.txt
- Desktop VM setup: See bmax-desktop directory
- Full deployment guide: DEPLOYMENT-GUIDE.md
