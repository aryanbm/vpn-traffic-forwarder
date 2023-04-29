#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Prompt for necessary variables
read -p "Enter Iran's server IP address: " IRAN_SERVER_IP
read -p "Enter External server IP address: " EXTERNAL_SERVER_IP
read -p "Enter VPN port: " VPN_PORT

# Prompt for server selection
echo "Select the server to configure:"
echo "1) Iran's server"
echo "2) External server"
read -p "Enter the number (1 or 2): " SERVER_SELECTION

if [ "$SERVER_SELECTION" -eq 1 ]; then
    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # Set up iptables rules
    sudo iptables -t nat -A PREROUTING -s $EXTERNAL_SERVER_IP -p tcp --dport 80 -j DNAT --to-destination $IRAN_SERVER_IP:$VPN_PORT
    sudo iptables -t nat -A PREROUTING -s $EXTERNAL_SERVER_IP -p tcp --dport 443 -j DNAT --to-destination $IRAN_SERVER_IP:$VPN_PORT
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # Save iptables rules
    sudo sh -c 'iptables-save > /etc/iptables/rules.v4'

    echo "Iran's server configuration completed."
elif [ "$SERVER_SELECTION" -eq 2 ]; then
    # Update default gateway
    sudo ip route add default via $IRAN_SERVER_IP

    echo "External server configuration completed."
else
    echo "Invalid selection. Please enter 1 or 2."
    exit 1
fi
