#!/bin/bash
# Debug Tunnel Manager for Chrome DevTools and Flutter debugging
# Manages SSH tunnels for browser debugging ports

set -euo pipefail
IFS=$'\n\t'

# Configuration
TUNNEL_CONTROL_DIR="/tmp/ssh-tunnels"
TUNNEL_STATE_FILE="/tmp/debug-tunnels.state"
MAX_TUNNELS=10
DEBUG_PORT_RANGE_START=9200
DEBUG_PORT_RANGE_END=9299

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Create tunnel state directory
init_tunnel_manager() {
    mkdir -p "$TUNNEL_CONTROL_DIR"
    touch "$TUNNEL_STATE_FILE"
    
    # Clean up any stale control files
    find "$TUNNEL_CONTROL_DIR" -name "devcontainer-debug-*" -type s -exec rm -f {} \; 2>/dev/null || true
}

# Find next available port in range
find_available_port() {
    for port in $(seq $DEBUG_PORT_RANGE_START $DEBUG_PORT_RANGE_END); do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! is_port_tunneled "$port"; then
            echo "$port"
            return 0
        fi
    done
    return 1
}

# Check if port is already tunneled
is_port_tunneled() {
    local port="$1"
    local control_path="$TUNNEL_CONTROL_DIR/devcontainer-debug-$port"
    
    if [[ -S "$control_path" ]] && ssh -O check -S "$control_path" devcontainer-host 2>/dev/null; then
        return 0
    fi
    return 1
}

# Create debug tunnel
create_tunnel() {
    local local_port="$1"
    local remote_port="${2:-$local_port}"
    local tunnel_name="devcontainer-debug-$local_port"
    local control_path="$TUNNEL_CONTROL_DIR/$tunnel_name"
    
    # Check if tunnel already exists
    if is_port_tunneled "$local_port"; then
        log_action "INFO" "Tunnel already exists for port $local_port"
        return 0
    fi
    
    # Count existing tunnels
    local tunnel_count=$(list_active_tunnels | wc -l)
    if [[ $tunnel_count -ge $MAX_TUNNELS ]]; then
        log_action "ERROR" "Maximum number of tunnels ($MAX_TUNNELS) reached"
        return 1
    fi
    
    log_action "INFO" "Creating SSH tunnel: $local_port -> $remote_port"
    
    # Create the tunnel
    if ssh -f -N -M -S "$control_path" \
        -L "$local_port:localhost:$remote_port" \
        devcontainer-host 2>/dev/null; then
        
        # Record tunnel state
        echo "$(date +%s):$local_port:$remote_port:active" >> "$TUNNEL_STATE_FILE"
        log_action "INFO" "SSH tunnel created successfully on port $local_port"
        return 0
    else
        log_action "ERROR" "Failed to create SSH tunnel for port $local_port"
        return 1
    fi
}

# Destroy specific tunnel
destroy_tunnel() {
    local port="$1"
    local tunnel_name="devcontainer-debug-$port"
    local control_path="$TUNNEL_CONTROL_DIR/$tunnel_name"
    
    if [[ -S "$control_path" ]]; then
        log_action "INFO" "Destroying SSH tunnel for port $port"
        ssh -O exit -S "$control_path" devcontainer-host 2>/dev/null || true
        
        # Update state file
        grep -v ":$port:" "$TUNNEL_STATE_FILE" > "${TUNNEL_STATE_FILE}.tmp" 2>/dev/null || true
        mv "${TUNNEL_STATE_FILE}.tmp" "$TUNNEL_STATE_FILE" 2>/dev/null || true
        
        log_action "INFO" "SSH tunnel destroyed for port $port"
    else
        log_action "WARNING" "No active tunnel found for port $port"
    fi
}

# List active tunnels
list_active_tunnels() {
    local active_tunnels=()
    
    for control_file in "$TUNNEL_CONTROL_DIR"/devcontainer-debug-*; do
        if [[ -S "$control_file" ]]; then
            local port=$(basename "$control_file" | sed 's/devcontainer-debug-//')
            if ssh -O check -S "$control_file" devcontainer-host 2>/dev/null; then
                active_tunnels+=("$port")
            else
                # Clean up stale control file
                rm -f "$control_file" 2>/dev/null || true
            fi
        fi
    done
    
    printf '%s\n' "${active_tunnels[@]}" | sort -n
}

# Clean up all tunnels
cleanup_all_tunnels() {
    log_action "INFO" "Cleaning up all debug tunnels"
    
    for control_file in "$TUNNEL_CONTROL_DIR"/devcontainer-debug-*; do
        if [[ -S "$control_file" ]]; then
            ssh -O exit -S "$control_file" devcontainer-host 2>/dev/null || true
        fi
    done
    
    # Clean up state and control files
    rm -f "$TUNNEL_STATE_FILE" "${TUNNEL_CONTROL_DIR}"/devcontainer-debug-* 2>/dev/null || true
    
    log_action "INFO" "All debug tunnels cleaned up"
}

# Get tunnel status
get_tunnel_status() {
    local port="$1"
    
    if is_port_tunneled "$port"; then
        echo "active"
    else
        echo "inactive"
    fi
}

# Auto-cleanup stale tunnels
cleanup_stale_tunnels() {
    local current_time=$(date +%s)
    local max_age=3600  # 1 hour
    
    while IFS=':' read -r timestamp port remote_port status; do
        if [[ -n "$timestamp" && $((current_time - timestamp)) -gt $max_age ]]; then
            if ! is_port_tunneled "$port"; then
                log_action "INFO" "Cleaning up stale tunnel record for port $port"
                grep -v ":$port:" "$TUNNEL_STATE_FILE" > "${TUNNEL_STATE_FILE}.tmp" 2>/dev/null || true
                mv "${TUNNEL_STATE_FILE}.tmp" "$TUNNEL_STATE_FILE" 2>/dev/null || true
            fi
        fi
    done < "$TUNNEL_STATE_FILE" 2>/dev/null || true
}

# Health check for tunnels
health_check() {
    log_action "INFO" "Performing tunnel health check"
    
    local checked=0
    local active=0
    local failed=0
    
    for control_file in "$TUNNEL_CONTROL_DIR"/devcontainer-debug-*; do
        if [[ -S "$control_file" ]]; then
            checked=$((checked + 1))
            local port=$(basename "$control_file" | sed 's/devcontainer-debug-//')
            
            if ssh -O check -S "$control_file" devcontainer-host 2>/dev/null; then
                active=$((active + 1))
                log_action "DEBUG" "Tunnel port $port: healthy"
            else
                failed=$((failed + 1))
                log_action "WARNING" "Tunnel port $port: failed, cleaning up"
                rm -f "$control_file" 2>/dev/null || true
            fi
        fi
    done
    
    log_action "INFO" "Health check complete: $checked checked, $active active, $failed failed"
}

# Usage information
usage() {
    cat << 'EOF'
Usage: debug-tunnel-manager.sh <command> [options]

COMMANDS:
  create <local_port> [remote_port]  Create new debug tunnel
  destroy <port>                     Destroy specific tunnel
  list                              List active tunnels
  status <port>                     Get tunnel status
  cleanup                           Clean up all tunnels
  health                            Health check all tunnels
  auto                              Auto-assign port and create tunnel

OPTIONS:
  -h, --help                        Show this help message

EXAMPLES:
  debug-tunnel-manager.sh create 9222        # Create tunnel on port 9222
  debug-tunnel-manager.sh create 9223 9222   # Create tunnel 9223->9222
  debug-tunnel-manager.sh auto               # Auto-assign available port
  debug-tunnel-manager.sh list               # List all active tunnels
  debug-tunnel-manager.sh destroy 9222       # Destroy tunnel on port 9222
  debug-tunnel-manager.sh cleanup            # Clean up all tunnels

DEBUG TOOLS:
  Chrome DevTools: http://localhost:<port>
  Flutter DevTools: http://localhost:9100
EOF
}

# Main execution
main() {
    local command="${1:-help}"
    
    # Initialize tunnel manager
    init_tunnel_manager
    
    case "$command" in
        create)
            if [[ $# -lt 2 ]]; then
                echo "Error: create command requires port number" >&2
                exit 1
            fi
            local local_port="$2"
            local remote_port="${3:-$local_port}"
            create_tunnel "$local_port" "$remote_port"
            ;;
        
        destroy)
            if [[ $# -lt 2 ]]; then
                echo "Error: destroy command requires port number" >&2
                exit 1
            fi
            destroy_tunnel "$2"
            ;;
        
        list)
            echo "Active debug tunnels:"
            list_active_tunnels | while read -r port; do
                echo "  Port $port: http://localhost:$port"
            done
            ;;
        
        status)
            if [[ $# -lt 2 ]]; then
                echo "Error: status command requires port number" >&2
                exit 1
            fi
            echo "$(get_tunnel_status "$2")"
            ;;
        
        cleanup)
            cleanup_all_tunnels
            ;;
        
        health)
            health_check
            ;;
        
        auto)
            local port
            if port=$(find_available_port); then
                if create_tunnel "$port"; then
                    echo "Auto-created tunnel on port $port"
                    echo "DevTools URL: http://localhost:$port"
                else
                    echo "Failed to create tunnel on port $port" >&2
                    exit 1
                fi
            else
                echo "No available ports in range $DEBUG_PORT_RANGE_START-$DEBUG_PORT_RANGE_END" >&2
                exit 1
            fi
            ;;
        
        help|--help|-h)
            usage
            ;;
        
        *)
            echo "Error: Unknown command '$command'" >&2
            usage
            exit 1
            ;;
    esac
}

# Cleanup on exit
cleanup_on_exit() {
    cleanup_stale_tunnels
}

trap cleanup_on_exit EXIT

# Execute main function
main "$@"