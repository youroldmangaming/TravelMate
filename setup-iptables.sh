#!/bin/bash
# Setup NAT for internet sharing using environment variables
iptables -t nat -A POSTROUTING -o ${NETWORK_INTERFACE_INTERNET} -j MASQUERADE
iptables -A FORWARD -i ${NETWORK_INTERFACE_INTERNET} -o ${NETWORK_INTERFACE_AP} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ${NETWORK_INTERFACE_AP} -o ${NETWORK_INTERFACE_INTERNET} -j ACCEPT
