#!/bin/bash
# Configure WiFi adapter as AP using environment variables
ip addr flush dev ${NETWORK_INTERFACE_AP}
ip addr add ${IP_ADDRESS}/24 dev ${NETWORK_INTERFACE_AP}
ip link set ${NETWORK_INTERFACE_AP} up

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
