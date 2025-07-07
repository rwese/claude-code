#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

echo "Starting Squid proxy..."
# Start Squid proxy in the background
sudo squid -d 1 &
SQUID_PID=$!

# Setup proxy environment variables
/usr/local/bin/setup-proxy-env.sh

# Wait for Squid to start
sleep 3
if ! pgrep -f squid >/dev/null; then
    echo "ERROR: Failed to start Squid proxy"
    exit 1
fi
echo "Squid proxy started successfully"

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Allow localhost (essential for proxy communication)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow DNS (needed by proxy for domain resolution)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
echo "Host network detected as: $HOST_NETWORK"

# Allow communication with host network (for SSH, etc.)
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

# Allow ONLY outbound HTTPS (443) and HTTP (80) traffic - proxy will handle filtering
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "Firewall configuration complete"
echo "Verifying proxy functionality..."

# Test that proxy blocks unauthorized domains
response=$(curl --proxy http://localhost:3128 --connect-timeout 5 -s http://example.com 2>&1)
if echo "$response" | grep -q "Access Denied"; then
    echo "Proxy verification passed - example.com properly blocked"
elif echo "$response" | grep -q "ERR_ACCESS_DENIED"; then
    echo "Proxy verification passed - example.com properly blocked"
else
    echo "ERROR: Proxy verification failed - was able to reach example.com"
    echo "Response: $response"
    kill $SQUID_PID 2>/dev/null || true
    exit 1
fi

# Test that proxy allows authorized domains
if ! curl --proxy http://localhost:3128 --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: Proxy verification failed - unable to reach api.github.com"
    kill $SQUID_PID 2>/dev/null || true
    exit 1
else
    echo "Proxy verification passed - able to reach api.github.com as expected"
fi

echo "Firewall and proxy setup complete!"