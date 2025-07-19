#!/bin/bash
# Security Validation and Logging Library for DevContainer Browser Launcher
# Provides common security functions and logging utilities

set -euo pipefail
IFS=$'\n\t'

# Configuration
SECURITY_LOG_FILE="/var/log/devcontainer-security.log"
RATE_LIMIT_DIR="/tmp/devcontainer-rate-limits"
MAX_LOG_SIZE="50M"
LOG_RETENTION_DAYS="30"

# Security validation functions
validate_url_scheme() {
    local url="$1"
    
    # Allow only HTTP and HTTPS
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    fi
    
    log_security_event "BLOCKED" "Invalid URL scheme: $url"
    return 1
}

validate_url_domain() {
    local url="$1"
    local allowed_domains=("${@:2}")
    
    # Extract domain from URL
    local domain=$(echo "$url" | sed -n 's#^https\?://\([^/]*\).*#\1#p' | cut -d: -f1)
    
    if [[ -z "$domain" ]]; then
        log_security_event "BLOCKED" "Could not extract domain from URL: $url"
        return 1
    fi
    
    # Check against allowed domains
    for pattern in "${allowed_domains[@]}"; do
        if [[ "$pattern" == *"*"* ]]; then
            # Wildcard matching
            local regex=$(echo "$pattern" | sed 's/\*/[^.]*/g' | sed 's/\./\\./g')
            if [[ "$domain" =~ ^${regex}$ ]]; then
                log_security_event "ALLOWED" "Domain matched pattern $pattern: $domain"
                return 0
            fi
        else
            # Exact matching
            if [[ "$domain" == "$pattern" ]]; then
                log_security_event "ALLOWED" "Domain exact match: $domain"
                return 0
            fi
        fi
    done
    
    log_security_event "BLOCKED" "Domain not in allowlist: $domain"
    return 1
}

validate_url_path() {
    local url="$1"
    
    # Extract path from URL
    local path=$(echo "$url" | sed -n 's#^https\?://[^/]*\(.*\)#\1#p')
    
    # Block dangerous path patterns
    local dangerous_patterns=(
        "\\.\\./\\.\\./"  # Directory traversal
        "/etc/"          # System files
        "/proc/"         # Process files
        "/sys/"          # System files
        "\\.ssh/"        # SSH keys
        "\\.env"         # Environment files
        "\\.git/"        # Git repository
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
            log_security_event "BLOCKED" "Dangerous path pattern detected: $path"
            return 1
        fi
    done
    
    return 0
}

validate_port_number() {
    local port="$1"
    local min_port="${2:-1024}"
    local max_port="${3:-65535}"
    
    # Check if port is numeric
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        log_security_event "BLOCKED" "Invalid port format: $port"
        return 1
    fi
    
    # Check port range
    if [[ $port -lt $min_port || $port -gt $max_port ]]; then
        log_security_event "BLOCKED" "Port out of allowed range: $port (range: $min_port-$max_port)"
        return 1
    fi
    
    return 0
}

# Rate limiting functions
init_rate_limiting() {
    mkdir -p "$RATE_LIMIT_DIR"
    chmod 700 "$RATE_LIMIT_DIR"
}

check_rate_limit() {
    local identifier="$1"
    local max_requests="${2:-10}"
    local window_seconds="${3:-60}"
    local rate_file="$RATE_LIMIT_DIR/$identifier"
    
    local current_time=$(date +%s)
    local window_start=$((current_time - window_seconds))
    
    # Clean old entries and count recent requests
    local recent_count=0
    if [[ -f "$rate_file" ]]; then
        # Count recent requests
        while IFS= read -r timestamp; do
            if [[ $timestamp -ge $window_start ]]; then
                recent_count=$((recent_count + 1))
            fi
        done < "$rate_file"
        
        # Clean old entries
        awk -v start="$window_start" '$1 >= start' "$rate_file" > "${rate_file}.tmp" || true
        mv "${rate_file}.tmp" "$rate_file" 2>/dev/null || true
    fi
    
    # Check rate limit
    if [[ $recent_count -ge $max_requests ]]; then
        log_security_event "RATE_LIMITED" "Rate limit exceeded for $identifier: $recent_count/$max_requests in ${window_seconds}s"
        return 1
    fi
    
    # Record this request
    echo "$current_time" >> "$rate_file"
    
    return 0
}

# Logging functions
log_security_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local pid=$$
    local user="${USER:-unknown}"
    
    # Ensure log file exists
    if [[ ! -f "$SECURITY_LOG_FILE" ]]; then
        touch "$SECURITY_LOG_FILE" 2>/dev/null || true
    fi
    
    # Format: TIMESTAMP [LEVEL] USER:PID MESSAGE
    local log_entry="$timestamp [$level] $user:$pid $message"
    
    # Write to log file
    echo "$log_entry" >> "$SECURITY_LOG_FILE" 2>/dev/null || true
    
    # Also output to stderr for immediate visibility
    echo "$log_entry" >&2
}

log_browser_request() {
    local url="$1"
    local debug_mode="${2:-false}"
    local debug_port="${3:-none}"
    local result="${4:-unknown}"
    
    local message="Browser request: URL=$url DEBUG=$debug_mode PORT=$debug_port RESULT=$result"
    log_security_event "BROWSER_REQUEST" "$message"
}

log_tunnel_event() {
    local action="$1"
    local port="$2"
    local result="${3:-success}"
    
    local message="Tunnel $action: PORT=$port RESULT=$result"
    log_security_event "TUNNEL" "$message"
}

# Log maintenance functions
rotate_logs() {
    local log_file="$1"
    local max_size="$2"
    
    if [[ -f "$log_file" ]]; then
        local current_size=$(stat -c%s "$log_file" 2>/dev/null || echo "0")
        local max_bytes=$(echo "$max_size" | sed 's/M/*1024*1024/' | bc 2>/dev/null || echo "52428800")
        
        if [[ $current_size -gt $max_bytes ]]; then
            log_security_event "MAINTENANCE" "Rotating log file: $log_file"
            
            # Keep last few rotations
            for i in {9..1}; do
                local old_file="${log_file}.$i"
                local new_file="${log_file}.$((i+1))"
                [[ -f "$old_file" ]] && mv "$old_file" "$new_file" 2>/dev/null || true
            done
            
            # Rotate current log
            mv "$log_file" "${log_file}.1" 2>/dev/null || true
            touch "$log_file" 2>/dev/null || true
        fi
    fi
}

cleanup_old_logs() {
    local retention_days="$1"
    
    # Clean up old log rotations
    find "$(dirname "$SECURITY_LOG_FILE")" -name "$(basename "$SECURITY_LOG_FILE").*" -type f -mtime +$retention_days -delete 2>/dev/null || true
    
    # Clean up old rate limit files
    find "$RATE_LIMIT_DIR" -type f -mtime +1 -delete 2>/dev/null || true
    
    log_security_event "MAINTENANCE" "Cleaned up logs older than $retention_days days"
}

# Process validation functions
validate_process_environment() {
    # Check for suspicious environment variables
    local suspicious_vars=(
        "LD_PRELOAD"
        "LD_LIBRARY_PATH"
        "DYLD_INSERT_LIBRARIES"
        "DYLD_LIBRARY_PATH"
    )
    
    for var in "${suspicious_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_security_event "WARNING" "Suspicious environment variable detected: $var=${!var}"
        fi
    done
}

validate_file_permissions() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_security_event "ERROR" "File not found: $file"
        return 1
    fi
    
    # Check if file is writable by others
    if [[ -w "$file" ]] && [[ $(stat -c %a "$file") =~ [0-9][0-9][2367] ]]; then
        log_security_event "WARNING" "File is world-writable: $file"
    fi
    
    # Check ownership
    local file_owner=$(stat -c %U "$file")
    if [[ "$file_owner" != "root" && "$file_owner" != "$USER" ]]; then
        log_security_event "WARNING" "File has unexpected owner: $file (owner: $file_owner)"
    fi
    
    return 0
}

# System security checks
check_system_security() {
    log_security_event "SECURITY_CHECK" "Starting system security validation"
    
    # Check critical files
    local critical_files=(
        "/usr/local/bin/safe-browser-open"
        "/usr/local/bin/debug-tunnel-manager"
        "/etc/sudoers.d/node-browser"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            validate_file_permissions "$file"
        fi
    done
    
    # Check process environment
    validate_process_environment
    
    # Check for suspicious processes
    if pgrep -f "(nc|netcat|telnet|ssh).*-l" >/dev/null; then
        log_security_event "WARNING" "Suspicious listening process detected"
    fi
    
    log_security_event "SECURITY_CHECK" "System security validation completed"
}

# Initialize security logging
init_security_logging() {
    # Create log directory if needed
    local log_dir=$(dirname "$SECURITY_LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true
    
    # Initialize rate limiting
    init_rate_limiting
    
    # Rotate logs if needed
    rotate_logs "$SECURITY_LOG_FILE" "$MAX_LOG_SIZE"
    
    # Clean up old logs
    cleanup_old_logs "$LOG_RETENTION_DAYS"
    
    log_security_event "INIT" "Security logging initialized"
}

# Main security validation function
validate_browser_request() {
    local url="$1"
    local debug_mode="${2:-false}"
    local debug_port="${3:-}"
    local user_id="${4:-$USER}"
    
    # Initialize if not already done
    init_security_logging
    
    log_security_event "VALIDATION_START" "Validating browser request from user: $user_id"
    
    # Rate limiting check
    if ! check_rate_limit "browser_$user_id" 10 60; then
        log_browser_request "$url" "$debug_mode" "$debug_port" "RATE_LIMITED"
        return 1
    fi
    
    # URL scheme validation
    if ! validate_url_scheme "$url"; then
        log_browser_request "$url" "$debug_mode" "$debug_port" "INVALID_SCHEME"
        return 1
    fi
    
    # URL path validation
    if ! validate_url_path "$url"; then
        log_browser_request "$url" "$debug_mode" "$debug_port" "DANGEROUS_PATH"
        return 1
    fi
    
    # Debug port validation
    if [[ "$debug_mode" == "true" && -n "$debug_port" ]]; then
        if ! validate_port_number "$debug_port" 9200 9299; then
            log_browser_request "$url" "$debug_mode" "$debug_port" "INVALID_PORT"
            return 1
        fi
    fi
    
    log_browser_request "$url" "$debug_mode" "$debug_port" "VALIDATED"
    log_security_event "VALIDATION_SUCCESS" "Browser request validation passed"
    return 0
}

# Export functions for use by other scripts
export -f log_security_event
export -f log_browser_request
export -f log_tunnel_event
export -f validate_url_scheme
export -f validate_url_domain
export -f validate_port_number
export -f check_rate_limit
export -f validate_browser_request