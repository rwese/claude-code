#!/bin/bash
# DevContainer Browser Launcher for Host System
# This script should be installed as /usr/local/bin/devcontainer-browser-launcher.sh on the host

set -euo pipefail
IFS=$'\n\t'

# Configuration
LOG_FILE="/var/log/devcontainer-browser.log"
RATE_LIMIT_FILE="/tmp/devcontainer-browser-rate"
MAX_REQUESTS_PER_MINUTE=10
DEBUG_PORT_RANGE="9200-9299"
ALLOWED_DOMAINS=(
    "localhost"
    "127.0.0.1"
    "::1"
    "*.localhost"
    "*.local"
    "github.com"
    "*.github.com"
    "stackoverflow.com"
    "*.stackoverflow.com"
    "developer.mozilla.org"
    "docs.flutter.dev"
    "pub.dev"
)

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Rate limiting check
check_rate_limit() {
    local current_time=$(date +%s)
    local window_start=$((current_time - 60))
    
    # Clean old entries and count recent requests
    if [[ -f "$RATE_LIMIT_FILE" ]]; then
        local recent_count=$(awk -v start="$window_start" '$1 >= start' "$RATE_LIMIT_FILE" | wc -l)
        if [[ $recent_count -ge $MAX_REQUESTS_PER_MINUTE ]]; then
            log_action "ERROR" "Rate limit exceeded: $recent_count requests in last minute"
            return 1
        fi
    fi
    
    # Record this request
    echo "$current_time" >> "$RATE_LIMIT_FILE"
    
    # Clean old entries
    awk -v start="$window_start" '$1 >= start' "$RATE_LIMIT_FILE" > "${RATE_LIMIT_FILE}.tmp" || true
    mv "${RATE_LIMIT_FILE}.tmp" "$RATE_LIMIT_FILE" 2>/dev/null || true
    
    return 0
}

# URL validation
validate_url() {
    local url="$1"
    
    # Block dangerous schemes
    if [[ "$url" =~ ^(file|ftp|data|javascript): ]]; then
        log_action "ERROR" "Blocked dangerous URL scheme: $url"
        return 1
    fi
    
    # Require http/https for external URLs
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_action "ERROR" "Invalid URL scheme: $url"
        return 1
    fi
    
    # Extract domain for validation
    local domain=$(echo "$url" | sed -n 's#^https\?://\([^/]*\).*#\1#p' | cut -d: -f1)
    
    # Check against allowed domains
    local allowed=false
    for pattern in "${ALLOWED_DOMAINS[@]}"; do
        if [[ "$pattern" == *"*"* ]]; then
            # Wildcard matching
            local regex=$(echo "$pattern" | sed 's/\*/[^.]*/g')
            if [[ "$domain" =~ ^${regex}$ ]]; then
                allowed=true
                break
            fi
        else
            # Exact matching
            if [[ "$domain" == "$pattern" ]]; then
                allowed=true
                break
            fi
        fi
    done
    
    if [[ "$allowed" != "true" ]]; then
        log_action "ERROR" "Domain not in allowlist: $domain"
        return 1
    fi
    
    return 0
}

# Find available debug port
find_debug_port() {
    for port in $(seq 9222 9299); do
        if ! netstat -tuln | grep -q ":$port "; then
            echo "$port"
            return 0
        fi
    done
    echo "9222"  # fallback
}

# Browser launcher functions
launch_browser() {
    local url="$1"
    local debug_mode="$2"
    local debug_port="$3"
    local profile_dir=""
    
    # Create isolated profile for debug sessions
    if [[ "$debug_mode" == "true" ]]; then
        profile_dir="/tmp/devcontainer-chrome-debug-$$"
        mkdir -p "$profile_dir"
    fi
    
    log_action "INFO" "Launching browser: URL=$url, DEBUG=$debug_mode, PORT=$debug_port"
    
    # Determine browser command
    local browser_cmd=""
    if command -v google-chrome >/dev/null; then
        browser_cmd="google-chrome"
    elif command -v chromium-browser >/dev/null; then
        browser_cmd="chromium-browser"
    elif command -v chromium >/dev/null; then
        browser_cmd="chromium"
    else
        log_action "ERROR" "No supported browser found"
        return 1
    fi
    
    # Build browser arguments
    local args=(
        "--no-first-run"
        "--no-default-browser-check"
        "--disable-default-apps"
        "--disable-extensions"
        "--disable-plugins"
        "--disable-background-timer-throttling"
        "--disable-backgrounding-occluded-windows"
        "--disable-renderer-backgrounding"
    )
    
    if [[ "$debug_mode" == "true" ]]; then
        args+=(
            "--remote-debugging-port=$debug_port"
            "--user-data-dir=$profile_dir"
            "--disable-web-security"
            "--disable-features=VizDisplayCompositor"
        )
    fi
    
    # Launch browser in background
    nohup "$browser_cmd" "${args[@]}" "$url" </dev/null >/dev/null 2>&1 &
    local browser_pid=$!
    
    log_action "INFO" "Browser launched with PID: $browser_pid"
    
    # For debug mode, wait a moment and verify the debug port is listening
    if [[ "$debug_mode" == "true" ]]; then
        sleep 2
        if netstat -tuln | grep -q ":$debug_port "; then
            log_action "INFO" "Debug port $debug_port is active"
            echo "$debug_port"  # Return the port for tunnel setup
        else
            log_action "ERROR" "Debug port $debug_port failed to activate"
            return 1
        fi
    fi
    
    return 0
}

# Main execution
main() {
    local force_mode="false"
    local url=""
    local debug_mode="false"
    local requested_port=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode="true"
                shift
                ;;
            *)
                if [[ -z "$url" ]]; then
                    url="$1"
                elif [[ -z "$debug_mode" || "$debug_mode" == "false" ]]; then
                    debug_mode="$1"
                elif [[ -z "$requested_port" ]]; then
                    requested_port="$1"
                fi
                shift
                ;;
        esac
    done
    
    log_action "INFO" "Browser launch request: $url (debug=$debug_mode, force=$force_mode)"
    
    # Rate limiting
    if ! check_rate_limit; then
        echo "Rate limit exceeded" >&2
        exit 1
    fi
    
    # URL validation (skip if force mode)
    if [[ "$force_mode" != "true" ]]; then
        if ! validate_url "$url"; then
            echo "URL validation failed" >&2
            exit 1
        fi
    else
        log_action "WARNING" "Force mode enabled - skipping URL validation for: $url"
    fi
    
    # Determine debug port
    local debug_port=""
    if [[ "$debug_mode" == "true" ]]; then
        if [[ -n "$requested_port" ]]; then
            debug_port="$requested_port"
        else
            debug_port=$(find_debug_port)
        fi
    fi
    
    # Launch browser
    if launch_browser "$url" "$debug_mode" "$debug_port"; then
        log_action "INFO" "Browser launch successful"
        if [[ "$debug_mode" == "true" ]]; then
            echo "Debug port: $debug_port"
        fi
        exit 0
    else
        log_action "ERROR" "Browser launch failed"
        exit 1
    fi
}

# Usage information
usage() {
    cat << 'EOF'
Usage: devcontainer-browser-launcher.sh [--force] <url> [debug] [port]

Arguments:
  --force - Skip URL validation (DANGEROUS)
  url     - URL to open (must be http/https and in allowlist unless --force)
  debug   - 'true' to enable remote debugging (optional)
  port    - specific debug port to use (optional)

Examples:
  devcontainer-browser-launcher.sh "http://localhost:3000"
  devcontainer-browser-launcher.sh "http://localhost:8080" true
  devcontainer-browser-launcher.sh "http://localhost:4000" true 9223
  devcontainer-browser-launcher.sh --force "file:///path/to/file.html"
EOF
}

# Check arguments
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

# Create log file if it doesn't exist
sudo touch "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE" 2>/dev/null || true

# Execute main function
main "$@"