#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

echo "Starting simplified proxy firewall configuration..."

# Configuration: Additional CIDR:port combinations for direct access (bypassing proxy)
# Format: "CIDR:PORT" - add one per line
# NOTE: Only IP addresses/CIDR blocks are supported, NOT hostnames (DNS resolution disabled)
DIRECT_ACCESS_RULES=(
    "0.0.0.0/0:80"     # Allow all HTTP traffic
    "0.0.0.0/0:443"    # Allow all HTTPS traffic
    "0.0.0.0/0:22"     # Allow all SSH traffic
    "0.0.0.0/0:25"     # Allow all SMTP traffic
    "0.0.0.0/0:587"    # Allow all SMTP submission traffic
    "0.0.0.0/0:993"    # Allow all IMAP over SSL traffic
    "0.0.0.0/0:995"    # Allow all POP3 over SSL traffic
    "0.0.0.0/0:3000"   # Allow common dev port
    "0.0.0.0/0:8000"   # Allow common dev port
    "0.0.0.0/0:8080"   # Allow common dev port
    "0.0.0.0/0:4000"   # Allow common dev port
    "0.0.0.0/0:5000"   # Allow common dev port
    "0.0.0.0/0:9000"   # Allow common dev port
)

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
iptables -A INPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

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

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow direct access to specific CIDR:port combinations (bypassing proxy)
for rule in "${DIRECT_ACCESS_RULES[@]}"; do
    if [[ -n "$rule" && ! "$rule" =~ ^[[:space:]]*# ]]; then
        cidr=$(echo "$rule" | cut -d: -f1)
        port=$(echo "$rule" | cut -d: -f2)
        
        echo "Adding direct access rule: $cidr:$port"
        iptables -A OUTPUT -d "$cidr" -p tcp --dport "$port" -j ACCEPT
    fi
done

# Allow UDP traffic for common services
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT # NTP
iptables -A OUTPUT -p udp --dport 161 -j ACCEPT # SNMP
iptables -A OUTPUT -p udp --dport 162 -j ACCEPT # SNMP trap

# Log blocked traffic with detailed information
iptables -A INPUT -j LOG --log-prefix "FW-PROXY-BLOCKED-IN: " --log-level 4 --log-tcp-options --log-tcp-sequence --log-ip-options
iptables -A OUTPUT -j LOG --log-prefix "FW-PROXY-BLOCKED-OUT: " --log-level 4 --log-tcp-options --log-tcp-sequence --log-ip-options

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "Firewall configuration complete with permissive proxy rules and detailed logging"
echo "Logging is enabled for all blocked traffic with prefix FW-PROXY-BLOCKED-IN/OUT"
echo "Monitor logs with: dmesg | grep FW-PROXY-BLOCKED"
echo "Or with: journalctl -f | grep FW-PROXY-BLOCKED"

# Skip verification tests in permissive mode
echo "Firewall and proxy setup complete - permissive mode enabled!"