#!/bin/bash
# proxy.sh - Install and configure Squid proxy with a separate ACL file for blocked sites

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo "Updating package list..."
apt-get update

echo "Installing Squid..."
apt-get install -y squid


SQUID_CONF="/etc/squid/squid.conf"
BACKUP_CONF="/etc/squid/squid.conf.bak"
BLOCKED_CONF="/etc/squid/blocked-sites.conf"


if [ ! -f "$BACKUP_CONF" ]; then
  cp "$SQUID_CONF" "$BACKUP_CONF"
  echo "Backup of original Squid config created at $BACKUP_CONF"
fi


cat > "$BLOCKED_CONF" << 'EOF'
# Blocked sites ACL
acl blocked_sites dstdomain .facebook.com 
EOF

echo "Blocked sites configuration written to $BLOCKED_CONF"


cat > "$SQUID_CONF" << 'EOF'

# Squid Main Configuration File

http_port 3128


include /etc/squid/blocked-sites.conf


http_access deny blocked_sites
http_access allow all


cache_mem 256 MB
maximum_object_size_in_memory 512 KB
cache_dir ufs /var/spool/squid 100 16 256
access_log /var/log/squid/access.log squid
EOF

echo "Squid main configuration updated."

echo "Restarting Squid service..."
systemctl restart squid

echo "Proxy server setup completed."

