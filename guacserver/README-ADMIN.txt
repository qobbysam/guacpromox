================================================================================
                    ADMINISTRATOR GUIDE
================================================================================

This guide covers system maintenance, troubleshooting, and common
administrative tasks for the multi-user remote desktop system.

================================================================================
SYSTEM ARCHITECTURE
================================================================================

COMPONENTS:
-----------
1. Guacamole Server (Gateway)
   - Web-based remote access
   - User authentication & authorization
   - Connection broker
   - Location: /opt/guacamole

2. Desktop VMs (Ubuntu Desktop + XRDP)
   - Host user sessions
   - Shared Chrome configuration
   - Multiple concurrent connections
   - User: shared-desktop

3. Cloudflare Tunnel
   - Secure internet access
   - HTTPS encryption
   - DDoS protection

================================================================================
GUACAMOLE MANAGEMENT
================================================================================

START/STOP/RESTART:
------------------
cd /opt/guacamole
./manage-guacamole.sh start
./manage-guacamole.sh stop
./manage-guacamole.sh restart

BACKUP & RESTORE:
----------------
# Create backup
./manage-guacamole.sh backup

# Restore from backup
./manage-guacamole.sh restore

UPDATE GUACAMOLE:
----------------
# Updates to latest version
./manage-guacamole.sh update

VIEW LOGS:
---------
./manage-guacamole.sh logs

CHECK STATUS:
------------
./manage-guacamole.sh status

================================================================================
TROUBLESHOOTING
================================================================================

PROBLEM: Guacamole won't start
SOLUTION:
---------
1. Check Docker status:
   sudo systemctl status docker
2. Check container status:
   docker ps -a
3. Check logs:
   cd /opt/guacamole
   ./manage-guacamole.sh logs
4. Restart services:
   ./manage-guacamole.sh restart

PROBLEM: Cloudflare Tunnel not working
SOLUTION:
---------
1. Check service status:
   sudo systemctl status cloudflared
2. Check tunnel status:
   cloudflared tunnel list
3. View logs:
   sudo journalctl -u cloudflared -n 50
4. Restart service:
   sudo systemctl restart cloudflared

================================================================================
SECURITY HARDENING
================================================================================

FIREWALL CONFIGURATION:
----------------------
# On Guacamole server (after Cloudflare Tunnel setup)
sudo ufw delete allow 8080/tcp
sudo ufw allow from 127.0.0.1 to any port 8080

# On Desktop VMs
sudo ufw allow from [Guacamole-IP] to any port 3389
sudo ufw deny 3389/tcp  # Block from elsewhere

REGULAR UPDATES:
---------------
# Update all systems monthly
sudo apt update && sudo apt upgrade -y

# Update Guacamole
cd /opt/guacamole
./manage-guacamole.sh update

================================================================================
USEFUL COMMANDS REFERENCE
================================================================================

GUACAMOLE:
---------
./manage-guacamole.sh status
./manage-guacamole.sh logs
./manage-guacamole.sh backup
./manage-guacamole.sh restart

DOCKER:
-------
docker ps
docker logs guacamole
docker exec -it guacamole bash

CLOUDFLARE TUNNEL:
-----------------
cloudflared tunnel list
cloudflared tunnel info [tunnel-name]
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f

================================================================================
