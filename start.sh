#!/bin/bash
# Process template files with environment variables
envsubst < /etc/samba/smb.conf.template > /etc/samba/smb.conf
envsubst < /etc/exports.template > /etc/exports
envsubst < /etc/hostapd/hostapd.conf.template > /etc/hostapd/hostapd.conf
envsubst < /etc/raspap/hostapd.conf.template > /etc/raspap/hostapd.conf

# Create RaspAP credentials from environment variables
echo "${RASPAP_USERNAME}:$(htpasswd -nb ${RASPAP_USERNAME} ${RASPAP_PASSWORD} | cut -d ':' -f 2)" > /etc/raspap/raspap.users

# Create Samba user and set password from environment variables
(echo "${SMB_PASSWORD}"; echo "${SMB_PASSWORD}") | smbpasswd -a -s ${SMB_USERNAME}

# Set Pi-hole password from environment variable
pihole -a -p "${PIHOLE_PASSWORD}"

# Setup network interfaces
export NETWORK_INTERFACE_AP
export NETWORK_INTERFACE_INTERNET
export IP_ADDRESS
/usr/local/bin/setup-interfaces.sh

# Setup iptables for NAT
export NETWORK_INTERFACE_AP
export NETWORK_INTERFACE_INTERNET
/usr/local/bin/setup-iptables.sh

# Make sure the shared directory exists with correct permissions
mkdir -p /shared
chmod 777 /shared

# Export NFS filesystem
exportfs -a

# Start NFS server
service nfs-kernel-server start

# Ensure RaspAP permissions are correct
chown -R www-data:www-data /var/www/html/raspap
chown -R www-data:www-data /etc/raspap

# Configure lighttpd to work with both Pi-hole and RaspAP
lighttpd-enable-mod fastcgi
lighttpd-enable-mod fastcgi-php

# Copy Pi-hole's dnsmasq settings to prevent conflicts with RaspAP
cp -f /etc/pihole/dnsmasq.conf /etc/dnsmasq.conf

# Join ZeroTier network if network ID is provided
if [ ! -z "${ZEROTIER_NETWORK_ID}" ]; then
  zerotier-cli join ${ZEROTIER_NETWORK_ID}
fi

# Start supervisor to manage all services
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
