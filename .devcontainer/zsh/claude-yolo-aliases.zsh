# Claude DevContainer Aliases and Functions
# Source this file in your ~/.zshrc: source /path/to/.devcontainer/zsh/claude-yolo-aliases.zsh

# Core claude-yolo aliases
alias cyb='claude-yolo-build'
alias cyu='claude-yolo-up'
alias cyc='claude-yolo-cmd'
alias cysh='claude-yolo-bash'
alias cy='claude-yolo'

# Browser launcher aliases (for use within devcontainer)
alias browser='sudo safe-browser-open'
alias browser-debug='sudo safe-browser-open --debug'
alias browser-flutter='sudo safe-browser-open --flutter'
alias browser-force='sudo safe-browser-open --force'

# Debug tunnel management
alias tunnels='debug-tunnel-manager'
alias tunnel-list='debug-tunnel-manager list'
alias tunnel-create='debug-tunnel-manager create'
alias tunnel-auto='debug-tunnel-manager auto'
alias tunnel-cleanup='debug-tunnel-manager cleanup'

# Flutter development
alias flutter-dev='flutter-debug-helper'
alias flutter-run='flutter-debug-helper run'
alias flutter-build='flutter-debug-helper build'
alias flutter-serve='flutter-debug-helper serve'
alias flutter-doctor='flutter-debug-helper doctor'

# Session management
alias sessions='browser-session-manager'
alias session-list='browser-session-manager list'
alias session-stop='browser-session-manager stop'
alias session-cleanup='browser-session-manager cleanup'
alias session-health='browser-session-manager health'

# Convenience functions for common development workflows
function dev-server() {
    local port=${1:-3000}
    echo "Starting development server on port $port..."
    cyc sudo safe-browser-open "http://localhost:$port"
}

function dev-debug() {
    local port=${1:-3000}
    local debug_port=${2:-9222}
    echo "Starting development server with debugging on port $port (debug: $debug_port)..."
    cyc sudo safe-browser-open --debug-port="$debug_port" "http://localhost:$port"
}

function flutter-dev-start() {
    local project_dir=${1:-.}
    local port=${2:-8080}
    echo "Starting Flutter development session in $project_dir on port $port..."
    cyc flutter-debug-helper run "$project_dir" "$port"
}

# Quick access to logs and debugging (safe version)
function cy-logs-safe() {
    echo "=== Safe Log Overview ==="
    local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
    if [[ -n "$container_id" ]]; then
        echo "Container: $(docker ps --filter "id=$container_id" --format "{{.Names}}")"
        echo "Status: $(docker ps --filter "id=$container_id" --format "{{.Status}}")"
        echo "Resources: $(docker stats "$container_id" --no-stream --format "CPU: {{.CPUPerc}} Memory: {{.MemPerc}}")"
    else
        echo "No container running"
    fi
    echo
    echo "💡 For detailed logs, use: cy-logs-detailed (may affect running processes)"
}

# Detailed logs (potentially invasive)
function cy-logs() {
    echo "=== Detailed Browser Request Logs ==="
    echo "⚠️  WARNING: This function executes commands in the container"
    cyc cat /tmp/browser-requests.log 2>/dev/null || echo "No browser logs found"
    echo
    echo "=== Active Sessions ==="
    cyc browser-session-manager list 2>/dev/null || echo "No active sessions"
    echo
    echo "=== Active Tunnels ==="
    cyc debug-tunnel-manager list 2>/dev/null || echo "No active tunnels"
}

# Alias for detailed logs
function cy-logs-detailed() {
    cy-logs
}

# Safe status overview
function cy-status-safe() {
    echo "=== DevContainer Safe Status ==="
    local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
    if [[ -n "$container_id" ]]; then
        echo "Container: $(docker ps --filter "id=$container_id" --format "{{.Names}}")"
        echo "Status: $(docker ps --filter "id=$container_id" --format "{{.Status}}")"
        echo "Image: $(docker inspect "$container_id" --format="{{.Config.Image}}")"
        echo "Resources: $(docker stats "$container_id" --no-stream --format "CPU: {{.CPUPerc}} Memory: {{.MemPerc}}")"
    else
        echo "No container running"
    fi
    echo
    echo "💡 For detailed status, use: cy-status-detailed (may affect running processes)"
}

# Detailed status (potentially invasive)
function cy-status() {
    echo "=== DevContainer Detailed Status ==="
    echo "⚠️  WARNING: This function executes commands in the container"
    echo "Container: $(docker ps --filter 'label=devcontainer.project=claude-code' --format '{{.Names}}' | head -1)"
    echo "Status: $(docker ps --filter 'label=devcontainer.project=claude-code' --format '{{.Status}}' | head -1)"
    echo
    cy-logs
}

# Alias for detailed status
function cy-status-detailed() {
    cy-status
}

function cy-help() {
    cat << 'EOF'
Claude DevContainer Aliases & Functions

CORE ALIASES:
  cyb, cy-build     - claude-yolo-build (rebuild container) [DESTRUCTIVE]
  cyu, cy-up        - claude-yolo-up (start container)
  cyc, cy-cmd       - claude-yolo-cmd (execute in container)
  cysh, cy-bash     - claude-yolo-bash (bash shell)
  cy                - claude-yolo (wrapper script)

BROWSER LAUNCHER (use within container):
  browser <url>              - Launch browser securely
  browser-debug <url>        - Launch with debugging
  browser-flutter <url>      - Launch with Flutter debugging
  browser-force <url>        - Launch browser bypassing validation [DANGEROUS]

DEBUG TUNNELS:
  tunnels                    - debug-tunnel-manager
  tunnel-list               - List active tunnels
  tunnel-create <port>      - Create tunnel on port
  tunnel-auto               - Auto-assign port
  tunnel-cleanup            - Clean up all tunnels [DESTRUCTIVE]

FLUTTER DEVELOPMENT:
  flutter-dev               - flutter-debug-helper
  flutter-run [dir] [port]  - Run Flutter app
  flutter-build [dir]       - Build Flutter app
  flutter-serve [dir] [port] - Serve Flutter build

SESSION MANAGEMENT:
  sessions                  - browser-session-manager
  session-list             - List active sessions
  session-stop <id>        - Stop specific session [DESTRUCTIVE]
  session-cleanup          - Clean expired sessions [DESTRUCTIVE]
  session-health           - Health check sessions

SAFE FUNCTIONS (won't affect running processes):
  cy-info                             - Safe environment info
  cy-health                           - Safe health check
  cy-status-safe                      - Safe status overview
  cy-logs-safe                        - Safe log overview
  cy-monitor                          - Safe performance monitor
  dev-server [port]                   - Quick dev server launch
  dev-debug [port] [debug_port]       - Quick debug server launch
  flutter-dev-start [dir] [port]      - Quick Flutter dev start

DETAILED FUNCTIONS (may affect running processes):
  cy-health-detailed                  - Full health check [INVASIVE]
  cy-status-detailed                  - Full status with logs [INVASIVE]
  cy-logs-detailed                    - All logs and sessions [INVASIVE]
  cy-monitor-detailed                 - Full performance monitor [INVASIVE]
  cy-cleanup-all                      - Clean all resources [DESTRUCTIVE]

EXAMPLES:
  cyb                                  # Rebuild container [DESTRUCTIVE]
  cy-info                             # Safe environment overview
  cy-health                           # Safe health check
  cyc browser http://localhost:3000    # Launch browser in container
  cyc browser-force file:///path.html  # Launch with force [DANGEROUS]
  dev-debug 8080 9223                 # Start debugging on custom ports
  flutter-dev-start ./my_app 3000     # Start Flutter app

NOTE: Functions marked [INVASIVE] execute commands in the container.
      Functions marked [DESTRUCTIVE] will stop/cleanup resources.
EOF
}

# Quick project setup functions
function cy-new-project() {
    local project_name=$1
    if [[ -z "$project_name" ]]; then
        echo "Usage: cy-new-project <project_name>"
        return 1
    fi
    
    echo "Setting up new project: $project_name"
    mkdir -p "$project_name"
    cd "$project_name"
    
    # Initialize basic project structure
    cyc "cd /workspace/$project_name && npm init -y"
    echo "Project $project_name created and initialized!"
}

function cy-flutter-new() {
    local app_name=$1
    if [[ -z "$app_name" ]]; then
        echo "Usage: cy-flutter-new <app_name>"
        return 1
    fi
    
    echo "Creating new Flutter app: $app_name"
    cyc "flutter create $app_name"
    echo "Flutter app $app_name created!"
    echo "Run: flutter-dev-start ./$app_name"
}

# Security testing functions
function cy-test-security() {
    echo "=== Testing Browser Launcher Security ==="
    echo
    echo "1. Testing dangerous URL schemes (should be blocked):"
    echo "   file:// scheme:"
    cyc sudo safe-browser-open file:///etc/passwd 2>/dev/null || echo "   ✅ Correctly blocked file:// scheme"
    
    echo "   javascript: scheme:"
    cyc sudo safe-browser-open "javascript:alert(1)" 2>/dev/null || echo "   ✅ Correctly blocked javascript: scheme"
    
    echo
    echo "2. Testing allowed schemes (will fail without host setup, but should pass validation):"
    echo "   HTTP localhost:"
    cyc sudo safe-browser-open http://localhost:3000 2>&1 | grep -q "Browser open request" && echo "   ✅ HTTP localhost validated" || echo "   ❌ HTTP localhost validation failed"
    
    echo
    echo "3. Testing rate limiting (run multiple times quickly):"
    for i in {1..3}; do
        cyc sudo safe-browser-open http://localhost:300$i 2>&1 | grep -q "Browser open request" && echo "   Request $i: ✅" || echo "   Request $i: ❌"
    done
    
    echo
    echo "Security testing complete!"
}

# Completion suggestions
function cy-complete() {
    echo "Available commands:"
    echo "  Core: cyb, cyu, cyc, cysh, cy"
    echo "  Browser: browser, browser-debug, browser-flutter"
    echo "  Tunnels: tunnels, tunnel-list, tunnel-create, tunnel-auto"
    echo "  Flutter: flutter-dev, flutter-run, flutter-build, flutter-serve"
    echo "  Sessions: sessions, session-list, session-stop, session-cleanup"
    echo "  Utils: dev-server, dev-debug, flutter-dev-start, cy-logs, cy-status"
    echo "  Setup: cy-new-project, cy-flutter-new"
    echo "  Test: cy-test-security"
}

# Auto-completion for common commands
function _cy_completion() {
    local commands=(
        "cyb:Rebuild devcontainer"
        "cyu:Start devcontainer" 
        "cyc:Execute command in devcontainer"
        "cysh:Start bash shell"
        "browser:Launch browser securely"
        "browser-debug:Launch browser with debugging"
        "tunnels:Manage debug tunnels"
        "flutter-dev:Flutter development helper"
        "sessions:Manage browser sessions"
        "dev-server:Quick development server"
        "cy-status:Show container status"
        "cy-help:Show help"
    )
    
    _describe 'claude-yolo commands' commands
}

# Register completions if compdef is available
if command -v compdef >/dev/null 2>&1; then
    compdef _cy_completion cyb cyu cyc cysh browser browser-debug tunnels flutter-dev sessions dev-server cy-status cy-help
fi

# Default aliases point to safe versions
alias cy-status='cy-status-safe'
alias cy-logs='cy-logs-safe'

# Claude DevContainer aliases loaded silently
# Type 'cy-help' for command reference
# Safe functions are used by default - use *-detailed versions if needed