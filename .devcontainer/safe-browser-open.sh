#!/bin/bash
# Container-side browser launcher that communicates with host
# This script will be installed as /usr/local/bin/safe-browser-open in the container

set -euo pipefail
IFS=$'\n\t'

# Configuration
HOST_SCRIPT="/usr/local/bin/devcontainer-browser-launcher.sh"
LOG_FILE="/tmp/browser-requests.log"
SSH_KEY_PATH="/home/node/.ssh/devcontainer_host_key"
SSH_CONFIG="/home/node/.ssh/config"
TUNNEL_CONTROL_DIR="/tmp/ssh-tunnels"
DEFAULT_HOST_USER="${DEVCONTAINER_HOST_USER:-$(whoami)}"

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# URL validation (basic client-side validation)
validate_url() {
    local url="$1"
    
    # Basic URL format check
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Error: URL must start with http:// or https://" >&2
        return 1
    fi
    
    # Check for dangerous patterns
    if [[ "$url" =~ (javascript:|data:|file:) ]]; then
        echo "Error: Dangerous URL scheme detected" >&2
        return 1
    fi
    
    return 0
}

# Check if SSH tunnel is needed and available
check_ssh_setup() {
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_action "WARNING" "SSH key not found at $SSH_KEY_PATH"
        return 1
    fi
    
    if [[ ! -f "$SSH_CONFIG" ]]; then
        log_action "WARNING" "SSH config not found at $SSH_CONFIG"
        return 1
    fi
    
    return 0
}

# Setup SSH tunnel for debug port forwarding
setup_debug_tunnel() {
    local debug_port="$1"
    local tunnel_name="devcontainer-debug-$debug_port"
    local control_path="$TUNNEL_CONTROL_DIR/$tunnel_name"
    
    mkdir -p "$TUNNEL_CONTROL_DIR"
    
    # Check if tunnel already exists
    if ssh -O check -S "$control_path" devcontainer-host 2>/dev/null; then
        log_action "INFO" "Debug tunnel already active on port $debug_port"
        return 0
    fi
    
    # Create SSH tunnel
    log_action "INFO" "Creating SSH tunnel for debug port $debug_port"
    ssh -f -N -M -S "$control_path" \
        -L "$debug_port:localhost:$debug_port" \
        devcontainer-host
    
    if [[ $? -eq 0 ]]; then
        log_action "INFO" "SSH tunnel established for port $debug_port"
        return 0
    else
        log_action "ERROR" "Failed to establish SSH tunnel for port $debug_port"
        return 1
    fi
}

# Cleanup SSH tunnel
cleanup_debug_tunnel() {
    local debug_port="$1"
    local tunnel_name="devcontainer-debug-$debug_port"
    local control_path="$TUNNEL_CONTROL_DIR/$tunnel_name"
    
    if ssh -O check -S "$control_path" devcontainer-host 2>/dev/null; then
        log_action "INFO" "Cleaning up SSH tunnel for port $debug_port"
        ssh -O exit -S "$control_path" devcontainer-host 2>/dev/null || true
    fi
}

# Execute browser launch via SSH
execute_via_ssh() {
    local url="$1"
    local debug_mode="$2"
    local debug_port="$3"
    local force_mode="$4"
    
    if ! check_ssh_setup; then
        echo "Error: SSH not configured for host communication" >&2
        return 1
    fi
    
    log_action "INFO" "Executing browser launch via SSH: $url"
    
    # Execute host script via SSH
    local ssh_result
    if [[ "$debug_mode" == "true" ]]; then
        if [[ "$force_mode" == "true" ]]; then
            ssh_result=$(ssh devcontainer-host "$HOST_SCRIPT" --force "$url" "$debug_mode" "$debug_port" 2>&1)
        else
            ssh_result=$(ssh devcontainer-host "$HOST_SCRIPT" "$url" "$debug_mode" "$debug_port" 2>&1)
        fi
    else
        if [[ "$force_mode" == "true" ]]; then
            ssh_result=$(ssh devcontainer-host "$HOST_SCRIPT" --force "$url" 2>&1)
        else
            ssh_result=$(ssh devcontainer-host "$HOST_SCRIPT" "$url" 2>&1)
        fi
    fi
    
    local ssh_exit_code=$?
    
    if [[ $ssh_exit_code -eq 0 ]]; then
        log_action "INFO" "Browser launch successful via SSH"
        
        # If debug mode, setup tunnel and extract debug port
        if [[ "$debug_mode" == "true" ]]; then
            local actual_debug_port=$(echo "$ssh_result" | grep "Debug port:" | cut -d: -f2 | tr -d ' ')
            if [[ -n "$actual_debug_port" ]]; then
                setup_debug_tunnel "$actual_debug_port"
                echo "Browser launched with debug port $actual_debug_port (tunneled to container)"
                echo "Connect DevTools to: http://localhost:$actual_debug_port"
            fi
        else
            echo "Browser launched successfully"
        fi
        return 0
    else
        log_action "ERROR" "SSH browser launch failed: $ssh_result"
        echo "Error: $ssh_result" >&2
        return 1
    fi
}

# Execute browser launch via Docker socket (fallback method)
execute_via_docker() {
    local url="$1"
    local debug_mode="$2"
    local debug_port="$3"
    local force_mode="$4"
    
    if [[ ! -S /var/run/docker.sock ]]; then
        echo "Error: Docker socket not available" >&2
        return 1
    fi
    
    log_action "INFO" "Executing browser launch via Docker: $url"
    
    # Get host container ID
    local host_container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code-host" | head -1)
    
    if [[ -z "$host_container_id" ]]; then
        echo "Error: Host container not found" >&2
        return 1
    fi
    
    # Execute command in host context
    if [[ "$debug_mode" == "true" ]]; then
        if [[ "$force_mode" == "true" ]]; then
            docker exec "$host_container_id" "$HOST_SCRIPT" --force "$url" "$debug_mode" "$debug_port"
        else
            docker exec "$host_container_id" "$HOST_SCRIPT" "$url" "$debug_mode" "$debug_port"
        fi
    else
        if [[ "$force_mode" == "true" ]]; then
            docker exec "$host_container_id" "$HOST_SCRIPT" --force "$url"
        else
            docker exec "$host_container_id" "$HOST_SCRIPT" "$url"
        fi
    fi
}

# Main execution function
main() {
    local url=""
    local debug_mode="false"
    local debug_port=""
    local flutter_mode="false"
    local force_mode="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                debug_mode="true"
                shift
                ;;
            --debug-port=*)
                debug_port="${1#*=}"
                debug_mode="true"
                shift
                ;;
            --flutter)
                flutter_mode="true"
                debug_mode="true"
                shift
                ;;
            --force)
                force_mode="true"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$url" ]]; then
                    url="$1"
                else
                    echo "Error: Multiple URLs specified" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$url" ]]; then
        echo "Error: URL is required" >&2
        usage
        exit 1
    fi
    
    # URL validation (skip if force mode)
    if [[ "$force_mode" != "true" ]]; then
        if ! validate_url "$url"; then
            exit 1
        fi
    else
        log_action "WARNING" "Force mode enabled - skipping URL validation for: $url"
    fi
    
    # Set default debug port if not specified
    if [[ "$debug_mode" == "true" && -z "$debug_port" ]]; then
        debug_port="9222"
    fi
    
    log_action "INFO" "Browser open request: URL=$url, DEBUG=$debug_mode, PORT=$debug_port, FLUTTER=$flutter_mode, FORCE=$force_mode"
    
    # Try SSH method first, then fallback to Docker
    if execute_via_ssh "$url" "$debug_mode" "$debug_port" "$force_mode"; then
        exit 0
    elif execute_via_docker "$url" "$debug_mode" "$debug_port" "$force_mode"; then
        exit 0
    else
        echo "Error: All browser launch methods failed" >&2
        exit 1
    fi
}

# Usage information
usage() {
    cat << 'EOF'
Usage: safe-browser-open [OPTIONS] <url>

OPTIONS:
  --debug                 Enable remote debugging mode
  --debug-port=PORT      Specify debug port (implies --debug)
  --flutter              Enable Flutter debugging mode (implies --debug)
  --force                Skip URL validation (DANGEROUS)
  --help                 Show this help message

EXAMPLES:
  safe-browser-open "http://localhost:3000"
  safe-browser-open --debug "http://localhost:8080"
  safe-browser-open --debug-port=9223 "http://localhost:4000"
  safe-browser-open --flutter "http://localhost:8080"
  safe-browser-open --force "file:///path/to/file.html"

SECURITY:
  - Only HTTP/HTTPS URLs are allowed (unless --force is used)
  - URLs are validated against host allowlist
  - Rate limiting is enforced
  - All requests are logged
  - --force flag skips URL validation (USE WITH CAUTION)

DEBUG MODE:
  - Creates SSH tunnel for Chrome DevTools access
  - Debug port forwarded to container
  - Connect to http://localhost:PORT for DevTools
EOF
}

# Handle cleanup on exit
cleanup_on_exit() {
    # Clean up any active tunnels
    if [[ -d "$TUNNEL_CONTROL_DIR" ]]; then
        for control_file in "$TUNNEL_CONTROL_DIR"/*; do
            if [[ -f "$control_file" ]]; then
                local port=$(basename "$control_file" | sed 's/devcontainer-debug-//')
                cleanup_debug_tunnel "$port" 2>/dev/null || true
            fi
        done
    fi
}

trap cleanup_on_exit EXIT

# Execute main function
main "$@"