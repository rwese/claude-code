#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

echo "Starting simplified firewall configuration..."

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# Allow localhost (essential)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow DNS (essential for name resolution)
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

# Allow established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow most common outbound ports (more permissive)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT   # HTTP
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT   # SSH
iptables -A OUTPUT -p tcp --dport 25 -j ACCEPT   # SMTP
iptables -A OUTPUT -p tcp --dport 587 -j ACCEPT  # SMTP (submission)
iptables -A OUTPUT -p tcp --dport 993 -j ACCEPT  # IMAP over SSL
iptables -A OUTPUT -p tcp --dport 995 -j ACCEPT  # POP3 over SSL
iptables -A OUTPUT -p tcp --dport 21 -j ACCEPT   # FTP
iptables -A OUTPUT -p tcp --dport 23 -j ACCEPT   # Telnet
iptables -A OUTPUT -p tcp --dport 3389 -j ACCEPT # RDP
iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT # PostgreSQL
iptables -A OUTPUT -p tcp --dport 3306 -j ACCEPT # MySQL
iptables -A OUTPUT -p tcp --dport 1433 -j ACCEPT # MSSQL
iptables -A OUTPUT -p tcp --dport 6379 -j ACCEPT # Redis
iptables -A OUTPUT -p tcp --dport 27017 -j ACCEPT # MongoDB

# Allow development ports
iptables -A OUTPUT -p tcp --dport 3000 -j ACCEPT # Common dev port
iptables -A OUTPUT -p tcp --dport 8000 -j ACCEPT # Common dev port
iptables -A OUTPUT -p tcp --dport 8080 -j ACCEPT # Common dev port
iptables -A OUTPUT -p tcp --dport 4000 -j ACCEPT # Common dev port
iptables -A OUTPUT -p tcp --dport 5000 -j ACCEPT # Common dev port
iptables -A OUTPUT -p tcp --dport 9000 -j ACCEPT # Common dev port

# Allow most UDP traffic (needed for various services)
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT # NTP
iptables -A OUTPUT -p udp --dport 161 -j ACCEPT # SNMP
iptables -A OUTPUT -p udp --dport 162 -j ACCEPT # SNMP trap

# Log blocked traffic with detailed information
iptables -A INPUT -j LOG --log-prefix "FW-BLOCKED-IN: " --log-level 4 --log-tcp-options --log-tcp-sequence --log-ip-options
iptables -A OUTPUT -j LOG --log-prefix "FW-BLOCKED-OUT: " --log-level 4 --log-tcp-options --log-tcp-sequence --log-ip-options

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "Firewall configuration complete with permissive rules and detailed logging"
echo "Logging is enabled for all blocked traffic with prefix FW-BLOCKED-IN/OUT"
echo "Monitor logs with: dmesg | grep FW-BLOCKED"
echo "Or with: journalctl -f | grep FW-BLOCKED"
