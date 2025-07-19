#!/bin/bash
# Browser Session Manager for DevContainer
# Manages browser processes, debug sessions, and cleanup

set -euo pipefail
IFS=$'\n\t'

# Configuration
SESSION_DIR="/tmp/browser-sessions"
PID_FILE_PREFIX="$SESSION_DIR/browser-session"
TUNNEL_MANAGER="/usr/local/bin/debug-tunnel-manager"
MAX_SESSIONS=5
SESSION_TIMEOUT=3600  # 1 hour

# Source security validation functions
source /usr/local/bin/security-validation.sh 2>/dev/null || true

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
    
    # Use security logging if available
    if command -v log_security_event >/dev/null 2>&1; then
        log_security_event "SESSION_MANAGER" "$message"
    fi
}

# Initialize session management
init_session_manager() {
    mkdir -p "$SESSION_DIR"
    chmod 700 "$SESSION_DIR"
    log_action "INFO" "Session manager initialized"
}

# Generate unique session ID
generate_session_id() {
    local session_id="session-$(date +%s)-$$"
    echo "$session_id"
}

# Record browser session
record_session() {
    local session_id="$1"
    local browser_pid="$2"
    local url="$3"
    local debug_port="${4:-none}"
    local tunnel_pids="${5:-}"
    
    local session_file="$PID_FILE_PREFIX-$session_id"
    
    cat > "$session_file" << EOF
SESSION_ID=$session_id
BROWSER_PID=$browser_pid
URL=$url
DEBUG_PORT=$debug_port
TUNNEL_PIDS=$tunnel_pids
START_TIME=$(date +%s)
USER=$USER
STATUS=active
EOF
    
    log_action "INFO" "Recorded session: $session_id (PID: $browser_pid)"
}

# List active sessions
list_sessions() {
    local show_details="${1:-false}"
    
    if [[ ! -d "$SESSION_DIR" ]]; then
        echo "No active sessions"
        return 0
    fi
    
    local active_count=0
    
    for session_file in "$SESSION_DIR"/browser-session-*; do
        [[ -f "$session_file" ]] || continue
        
        # Load session data
        source "$session_file"
        
        # Check if browser process is still running
        if kill -0 "$BROWSER_PID" 2>/dev/null; then
            active_count=$((active_count + 1))
            
            if [[ "$show_details" == "true" ]]; then
                local duration=$(($(date +%s) - START_TIME))
                echo "Session: $SESSION_ID"
                echo "  PID: $BROWSER_PID"
                echo "  URL: $URL"
                echo "  Debug Port: $DEBUG_PORT"
                echo "  Duration: ${duration}s"
                echo "  User: $USER"
                echo ""
            else
                echo "$SESSION_ID (PID: $BROWSER_PID)"
            fi
        else
            # Clean up stale session file
            log_action "INFO" "Cleaning up stale session: $SESSION_ID"
            rm -f "$session_file"
        fi
    done
    
    if [[ $active_count -eq 0 ]]; then
        echo "No active sessions"
    fi
    
    return 0
}

# Stop specific session
stop_session() {
    local session_id="$1"
    local session_file="$PID_FILE_PREFIX-$session_id"
    
    if [[ ! -f "$session_file" ]]; then
        echo "Session not found: $session_id" >&2
        return 1
    fi
    
    # Load session data
    source "$session_file"
    
    log_action "INFO" "Stopping session: $session_id"
    
    # Stop browser process
    if kill -0 "$BROWSER_PID" 2>/dev/null; then
        log_action "INFO" "Terminating browser process: $BROWSER_PID"
        kill -TERM "$BROWSER_PID" 2>/dev/null || true
        
        # Give it time to exit gracefully
        sleep 2
        
        # Force kill if still running
        if kill -0 "$BROWSER_PID" 2>/dev/null; then
            log_action "WARNING" "Force killing browser process: $BROWSER_PID"
            kill -KILL "$BROWSER_PID" 2>/dev/null || true
        fi
    fi
    
    # Stop debug tunnels if any
    if [[ "$DEBUG_PORT" != "none" && -n "$TUNNEL_PIDS" ]]; then
        log_action "INFO" "Stopping debug tunnel on port: $DEBUG_PORT"
        if command -v "$TUNNEL_MANAGER" >/dev/null 2>&1; then
            "$TUNNEL_MANAGER" destroy "$DEBUG_PORT" 2>/dev/null || true
        fi
        
        # Kill tunnel processes
        for pid in $TUNNEL_PIDS; do
            kill -TERM "$pid" 2>/dev/null || true
        done
    fi
    
    # Remove session file
    rm -f "$session_file"
    
    log_action "INFO" "Session stopped: $session_id"
}

# Stop all sessions
stop_all_sessions() {
    log_action "INFO" "Stopping all browser sessions"
    
    local stopped_count=0
    
    for session_file in "$SESSION_DIR"/browser-session-*; do
        [[ -f "$session_file" ]] || continue
        
        local session_id=$(basename "$session_file" | sed 's/browser-session-//')
        stop_session "$session_id"
        stopped_count=$((stopped_count + 1))
    done
    
    log_action "INFO" "Stopped $stopped_count sessions"
}

# Clean up expired sessions
cleanup_expired_sessions() {
    local current_time=$(date +%s)
    local expired_count=0
    
    for session_file in "$SESSION_DIR"/browser-session-*; do
        [[ -f "$session_file" ]] || continue
        
        # Load session data
        source "$session_file"
        
        # Check if session has expired
        local session_age=$((current_time - START_TIME))
        if [[ $session_age -gt $SESSION_TIMEOUT ]]; then
            log_action "INFO" "Session expired: $SESSION_ID (age: ${session_age}s)"
            stop_session "$SESSION_ID"
            expired_count=$((expired_count + 1))
        fi
    done
    
    if [[ $expired_count -gt 0 ]]; then
        log_action "INFO" "Cleaned up $expired_count expired sessions"
    fi
}

# Check session limits
check_session_limits() {
    local active_sessions=$(list_sessions | grep -c "Session:" 2>/dev/null || echo "0")
    
    if [[ $active_sessions -ge $MAX_SESSIONS ]]; then
        log_action "WARNING" "Maximum sessions reached: $active_sessions/$MAX_SESSIONS"
        return 1
    fi
    
    return 0
}

# Monitor session health
monitor_session_health() {
    log_action "INFO" "Starting session health monitor"
    
    local unhealthy_count=0
    
    for session_file in "$SESSION_DIR"/browser-session-*; do
        [[ -f "$session_file" ]] || continue
        
        # Load session data
        source "$session_file"
        
        # Check browser process health
        if ! kill -0 "$BROWSER_PID" 2>/dev/null; then
            log_action "WARNING" "Unhealthy session detected: $SESSION_ID (browser process dead)"
            rm -f "$session_file"
            unhealthy_count=$((unhealthy_count + 1))
            continue
        fi
        
        # Check debug tunnel health if applicable
        if [[ "$DEBUG_PORT" != "none" ]]; then
            if ! netstat -tuln 2>/dev/null | grep -q ":$DEBUG_PORT "; then
                log_action "WARNING" "Debug tunnel down for session: $SESSION_ID (port: $DEBUG_PORT)"
                # Try to restart tunnel
                if command -v "$TUNNEL_MANAGER" >/dev/null 2>&1; then
                    "$TUNNEL_MANAGER" create "$DEBUG_PORT" 2>/dev/null || true
                fi
            fi
        fi
    done
    
    if [[ $unhealthy_count -gt 0 ]]; then
        log_action "INFO" "Health check cleaned up $unhealthy_count unhealthy sessions"
    fi
}

# Resource usage monitoring
monitor_resource_usage() {
    local total_memory=0
    local total_cpu=0
    local session_count=0
    
    for session_file in "$SESSION_DIR"/browser-session-*; do
        [[ -f "$session_file" ]] || continue
        
        source "$session_file"
        
        if kill -0 "$BROWSER_PID" 2>/dev/null; then
            session_count=$((session_count + 1))
            
            # Get memory usage (in KB)
            local memory=$(ps -o rss= -p "$BROWSER_PID" 2>/dev/null || echo "0")
            total_memory=$((total_memory + memory))
            
            # Get CPU usage
            local cpu=$(ps -o %cpu= -p "$BROWSER_PID" 2>/dev/null || echo "0")
            total_cpu=$(echo "$total_cpu + $cpu" | bc 2>/dev/null || echo "$total_cpu")
        fi
    done
    
    if [[ $session_count -gt 0 ]]; then
        local memory_mb=$((total_memory / 1024))
        log_action "INFO" "Resource usage: $session_count sessions, ${memory_mb}MB memory, ${total_cpu}% CPU"
        
        # Alert if resource usage is high
        if [[ $memory_mb -gt 2048 ]]; then
            log_action "WARNING" "High memory usage detected: ${memory_mb}MB"
        fi
    fi
}

# Usage information
usage() {
    cat << 'EOF'
Usage: browser-session-manager.sh <command> [options]

COMMANDS:
  list [details]          List active browser sessions
  stop <session_id>       Stop specific session
  stop-all               Stop all sessions
  cleanup                Clean up expired sessions
  health                 Check session health
  monitor                Monitor resource usage
  init                   Initialize session manager

OPTIONS:
  -h, --help             Show this help message

EXAMPLES:
  browser-session-manager.sh list                # List active sessions
  browser-session-manager.sh list details        # List with details
  browser-session-manager.sh stop session-123    # Stop specific session
  browser-session-manager.sh stop-all           # Stop all sessions
  browser-session-manager.sh cleanup            # Clean expired sessions
  browser-session-manager.sh health             # Health check

AUTOMATIC CLEANUP:
  - Sessions expire after 1 hour
  - Maximum of 5 concurrent sessions
  - Stale sessions are automatically cleaned
EOF
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        init)
            init_session_manager
            ;;
        
        list)
            init_session_manager
            list_sessions "${2:-false}"
            ;;
        
        stop)
            if [[ $# -lt 2 ]]; then
                echo "Error: session ID required" >&2
                exit 1
            fi
            init_session_manager
            stop_session "$2"
            ;;
        
        stop-all)
            init_session_manager
            stop_all_sessions
            ;;
        
        cleanup)
            init_session_manager
            cleanup_expired_sessions
            ;;
        
        health)
            init_session_manager
            monitor_session_health
            ;;
        
        monitor)
            init_session_manager
            monitor_resource_usage
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
    # Perform final cleanup
    cleanup_expired_sessions 2>/dev/null || true
}

trap cleanup_on_exit EXIT

# Execute main function
main "$@"