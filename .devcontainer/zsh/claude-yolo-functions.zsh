# Claude DevContainer Advanced Functions
# Source this file in your ~/.zshrc: source /path/to/.devcontainer/zsh/claude-yolo-functions.zsh

# Advanced development workflow functions

# Smart project detection and browser launching
function cy-dev() {
    local port=${1:-3000}
    local debug=${2:-false}
    
    echo "🚀 Starting development workflow..."
    
    # Check if we're in a known project type
    if [[ -f "package.json" ]]; then
        echo "📦 Detected Node.js project"
        local start_script=$(jq -r '.scripts.start // .scripts.dev // "npm start"' package.json 2>/dev/null)
        echo "   Start script: $start_script"
        
        if [[ "$debug" == "true" ]]; then
            cyc "$start_script &" && dev-debug "$port"
        else
            cyc "$start_script &" && dev-server "$port"
        fi
        
    elif [[ -f "pubspec.yaml" ]]; then
        echo "📱 Detected Flutter project"
        flutter-dev-start . "$port"
        
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        echo "🐍 Detected Python project"
        if [[ "$debug" == "true" ]]; then
            dev-debug "$port"
        else
            dev-server "$port"
        fi
        
    elif [[ -f "Cargo.toml" ]]; then
        echo "🦀 Detected Rust project"
        if [[ "$debug" == "true" ]]; then
            dev-debug "$port"
        else
            dev-server "$port"
        fi
        
    else
        echo "❓ Unknown project type, starting generic dev server"
        if [[ "$debug" == "true" ]]; then
            dev-debug "$port"
        else
            dev-server "$port"
        fi
    fi
}

# Bulk session management
function cy-cleanup-all() {
    echo "🧹 Cleaning up all development resources..."
    
    echo "   Stopping all browser sessions..."
    cyc browser-session-manager stop-all 2>/dev/null || true
    
    echo "   Cleaning up debug tunnels..."
    cyc debug-tunnel-manager cleanup 2>/dev/null || true
    
    echo "   Cleaning up expired sessions..."
    cyc browser-session-manager cleanup 2>/dev/null || true
    
    echo "✅ Cleanup complete!"
}

# Development environment health check (safe, read-only)
function cy-health() {
    echo "🏥 DevContainer Health Check (Safe Mode)"
    echo "========================================"
    echo
    
    # Check container status (host-side only)
    local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
    if [[ -n "$container_id" ]]; then
        echo "✅ Container: Running ($container_id)"
        local container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        echo "   Name: $container_name"
        local uptime=$(docker ps --filter "id=$container_id" --format "{{.Status}}")
        echo "   Status: $uptime"
    else
        echo "❌ Container: Not running"
        return 1
    fi
    
    echo
    
    # Check if container is responsive (safe check)
    echo "🌐 Container Responsiveness:"
    if docker exec "$container_id" echo "ping" >/dev/null 2>&1; then
        echo "✅ Container is responsive"
    else
        echo "⚠️  Container may be busy or unresponsive"
    fi
    
    echo
    
    # Check container resources (host-side)
    echo "💾 Container Resources:"
    docker stats "$container_id" --no-stream --format "   CPU: {{.CPUPerc}}  Memory: {{.MemUsage}} ({{.MemPerc}})"
    
    echo
    
    # Basic file existence checks (non-invasive)
    echo "📁 Installation Status:"
    if docker exec "$container_id" test -f /usr/local/bin/safe-browser-open 2>/dev/null; then
        echo "✅ Browser launcher scripts installed"
    else
        echo "❌ Browser launcher scripts missing"
    fi
    
    echo
    echo "🎯 Safe health check complete!"
    echo "💡 For detailed checks, use: cy-health-detailed (may affect running processes)"
}

# Project scaffolding functions
function cy-scaffold-react() {
    local app_name=${1:-my-react-app}
    echo "⚛️  Creating React application: $app_name"
    
    cyc "npx create-react-app $app_name"
    cd "$app_name" 2>/dev/null || return 1
    
    echo "✅ React app created!"
    echo "📝 To start development:"
    echo "   cd $app_name"
    echo "   cy-dev 3000"
}

function cy-scaffold-next() {
    local app_name=${1:-my-next-app}
    echo "▲ Creating Next.js application: $app_name"
    
    cyc "npx create-next-app@latest $app_name"
    cd "$app_name" 2>/dev/null || return 1
    
    echo "✅ Next.js app created!"
    echo "📝 To start development:"
    echo "   cd $app_name"
    echo "   cy-dev 3000"
}

function cy-scaffold-vue() {
    local app_name=${1:-my-vue-app}
    echo "💚 Creating Vue.js application: $app_name"
    
    cyc "npm init vue@latest $app_name"
    cd "$app_name" 2>/dev/null || return 1
    
    echo "✅ Vue.js app created!"
    echo "📝 To start development:"
    echo "   cd $app_name"
    echo "   cy-dev 5173"
}

# Debug session management
function cy-debug-session() {
    local url=${1:-http://localhost:3000}
    local debug_port=${2:-9222}
    
    echo "🐛 Starting debug session..."
    echo "   URL: $url"
    echo "   Debug port: $debug_port"
    
    # Create debug tunnel first
    cyc debug-tunnel-manager create "$debug_port"
    
    # Launch browser with debugging
    cyc sudo safe-browser-open --debug-port="$debug_port" "$url"
    
    echo "🔗 Debug URLs:"
    echo "   Application: $url"
    echo "   DevTools: http://localhost:$debug_port"
    echo
    echo "📝 To stop debug session:"
    echo "   cy-stop-debug $debug_port"
}

function cy-stop-debug() {
    local debug_port=${1:-9222}
    
    echo "🛑 Stopping debug session on port $debug_port..."
    
    # Stop debug tunnel
    cyc debug-tunnel-manager destroy "$debug_port"
    
    # Find and stop related browser sessions
    cyc browser-session-manager list | grep -q "Port $debug_port" && {
        local session_id=$(cyc browser-session-manager list details | grep -B5 "Port $debug_port" | grep "Session:" | cut -d: -f2 | tr -d ' ')
        if [[ -n "$session_id" ]]; then
            cyc browser-session-manager stop "$session_id"
            echo "✅ Stopped browser session: $session_id"
        fi
    }
    
    echo "✅ Debug session stopped"
}

# Performance monitoring (safe, host-side only)
function cy-monitor() {
    local interval=${1:-5}
    
    echo "📊 Starting DevContainer performance monitor - SAFE MODE (Ctrl+C to stop)"
    echo "Refresh interval: ${interval}s"
    echo "Note: Use 'cy-monitor-detailed' for full monitoring (may affect running processes)"
    echo
    
    while true; do
        clear
        echo "🐳 DevContainer Performance Monitor (Safe) - $(date)"
        echo "=============================================="
        echo
        
        # Container resources (host-side only)
        local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
        if [[ -n "$container_id" ]]; then
            echo "💾 Container Resources:"
            docker stats "$container_id" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
            echo
            
            echo "🔍 Container Status:"
            echo "   Uptime: $(docker ps --filter "id=$container_id" --format "{{.Status}}")"
            echo "   Image: $(docker inspect "$container_id" --format="{{.Config.Image}}")"
            echo
        else
            echo "❌ No container running"
        fi
        
        echo "💡 For detailed session monitoring, use: cy-monitor-detailed"
        
        sleep "$interval"
    done
}

# Quick test functions
function cy-test-browser() {
    echo "🧪 Testing browser launcher functionality..."
    
    echo "1. Testing help command:"
    cyc sudo safe-browser-open --help >/dev/null && echo "   ✅ Help command works" || echo "   ❌ Help command failed"
    
    echo "2. Testing security validation:"
    cyc sudo safe-browser-open file:///etc/passwd 2>&1 | grep -q "Dangerous URL scheme" && echo "   ✅ Security validation works" || echo "   ❌ Security validation failed"
    
    echo "3. Testing force flag (dangerous):"
    cyc sudo safe-browser-open --force file:///etc/passwd 2>&1 | grep -q "Force mode enabled" && echo "   ✅ Force flag works" || echo "   ❌ Force flag failed"
    
    echo "4. Testing valid URL (will fail without host setup):"
    cyc sudo safe-browser-open http://localhost:3000 2>&1 | grep -q "Browser open request" && echo "   ✅ URL validation works" || echo "   ❌ URL validation failed"
    
    echo "5. Testing session manager:"
    cyc browser-session-manager list >/dev/null && echo "   ✅ Session manager works" || echo "   ❌ Session manager failed"
    
    echo "6. Testing debug tunnel manager:"
    cyc debug-tunnel-manager list >/dev/null && echo "   ✅ Tunnel manager works" || echo "   ❌ Tunnel manager failed"
    
    echo
    echo "🎯 Browser launcher test complete!"
}

# Workspace management
function cy-workspace() {
    local action=${1:-status}
    
    case "$action" in
        "status")
            echo "📁 Workspace Status:"
            echo "   Current directory: $(pwd)"
            echo "   Files: $(ls -1 | wc -l)"
            echo "   Git status: $(git status --porcelain 2>/dev/null | wc -l) changes"
            ;;
        "clean")
            echo "🧹 Cleaning workspace..."
            cy-cleanup-all
            cyc "find /workspace -name 'node_modules' -type d -exec du -sh {} \; 2>/dev/null | head -5" || true
            ;;
        "backup")
            local backup_name="workspace-backup-$(date +%Y%m%d-%H%M%S)"
            echo "💾 Creating workspace backup: $backup_name"
            tar -czf "$backup_name.tar.gz" . --exclude=node_modules --exclude=.git
            echo "   Backup saved: $backup_name.tar.gz"
            ;;
        *)
            echo "Usage: cy-workspace [status|clean|backup]"
            ;;
    esac
}

# Environment information (safe, read-only)
function cy-info() {
    echo "ℹ️  Claude DevContainer Information (Safe Mode)"
    echo "==============================================="
    echo
    echo "📦 Container Info:"
    local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
    if [[ -n "$container_id" ]]; then
        docker inspect "$container_id" --format="   Image: {{.Config.Image}}"
        docker inspect "$container_id" --format="   Created: {{.Created}}"
        docker inspect "$container_id" --format="   Platform: {{.Platform}}"
        echo "   Status: $(docker ps --filter "id=$container_id" --format "{{.Status}}")"
    else
        echo "   No container running"
        return 1
    fi
    echo
    
    echo "💾 Resource Usage:"
    docker stats "$container_id" --no-stream --format "   CPU: {{.CPUPerc}}  Memory: {{.MemUsage}} ({{.MemPerc}})  Network: {{.NetIO}}"
    echo
    
    echo "🌐 Installation Status:"
    if docker exec "$container_id" test -f /usr/local/bin/safe-browser-open 2>/dev/null; then
        echo "   ✅ Browser launcher installed"
    else
        echo "   ❌ Browser launcher missing"
    fi
    
    if docker exec "$container_id" test -f /home/node/.ssh/devcontainer_host_key 2>/dev/null; then
        echo "   ✅ SSH key configured"
    else
        echo "   ⚠️  SSH key missing"
    fi
    echo
    
    echo "📚 Available Commands:"
    echo "   • cy-health-detailed - Full system check (may affect running processes)"
    echo "   • cy-status-safe - Safe status overview"
    echo "   • cy-logs-safe - Safe log viewing"
    echo "   • cy-help - Command reference"
}

# Detailed versions (potentially invasive - use with caution)
function cy-health-detailed() {
    echo "🏥 DevContainer Detailed Health Check"
    echo "===================================="
    echo "⚠️  WARNING: This function executes commands in the container and may affect running processes"
    echo
    
    # Check container status
    local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
    if [[ -n "$container_id" ]]; then
        echo "✅ Container: Running ($container_id)"
        local container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        echo "   Name: $container_name"
        local uptime=$(docker ps --filter "id=$container_id" --format "{{.Status}}")
        echo "   Status: $uptime"
    else
        echo "❌ Container: Not running"
        return 1
    fi
    
    echo
    
    # Check browser launcher (invasive)
    echo "🌐 Browser Launcher:"
    if cyc sudo -l | grep -q "safe-browser-open" 2>/dev/null; then
        echo "✅ Sudo permissions configured"
    else
        echo "❌ Sudo permissions missing"
    fi
    
    if cyc test -f /usr/local/bin/safe-browser-open 2>/dev/null; then
        echo "✅ Browser launcher installed"
    else
        echo "❌ Browser launcher missing"
    fi
    
    echo
    
    # Check SSH setup (invasive)
    echo "🔐 SSH Configuration:"
    if cyc test -f /home/node/.ssh/devcontainer_host_key 2>/dev/null; then
        echo "✅ SSH key generated"
    else
        echo "⚠️  SSH key not found"
    fi
    
    if cyc test -f /home/node/.ssh/config 2>/dev/null; then
        echo "✅ SSH config created"
    else
        echo "⚠️  SSH config missing"
    fi
    
    echo
    
    # Check active sessions and tunnels (invasive)
    echo "📊 Active Resources:"
    local sessions=$(cyc browser-session-manager list 2>/dev/null | grep -c "Session:" || echo "0")
    echo "   Browser sessions: $sessions"
    
    local tunnels=$(cyc debug-tunnel-manager list 2>/dev/null | grep -c "Port" || echo "0")
    echo "   Debug tunnels: $tunnels"
    
    echo
    
    # Check logs (invasive)
    echo "📝 Recent Activity:"
    if cyc test -f /tmp/browser-requests.log 2>/dev/null; then
        local recent_requests=$(cyc tail -5 /tmp/browser-requests.log 2>/dev/null | wc -l)
        echo "   Recent browser requests: $recent_requests"
    else
        echo "   No browser request logs found"
    fi
    
    echo
    echo "🎯 Detailed health check complete!"
}

# Detailed monitoring (potentially invasive)
function cy-monitor-detailed() {
    local interval=${1:-5}
    
    echo "📊 Starting DevContainer detailed performance monitor (Ctrl+C to stop)"
    echo "⚠️  WARNING: This function executes commands in the container and may affect running processes"
    echo "Refresh interval: ${interval}s"
    echo
    
    while true; do
        clear
        echo "🐳 DevContainer Performance Monitor (Detailed) - $(date)"
        echo "================================================="
        echo
        
        # Container resources
        local container_id=$(docker ps -q --filter "label=devcontainer.project=claude-code" | head -1)
        if [[ -n "$container_id" ]]; then
            echo "💾 Container Resources:"
            docker stats "$container_id" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
            echo
        fi
        
        # Browser sessions (invasive)
        echo "🌐 Browser Sessions:"
        cyc browser-session-manager monitor 2>/dev/null || echo "No active sessions"
        echo
        
        # Debug tunnels (invasive)
        echo "🔗 Debug Tunnels:"
        cyc debug-tunnel-manager list 2>/dev/null || echo "No active tunnels"
        echo
        
        # Recent activity (invasive)
        echo "📝 Recent Browser Requests:"
        cyc tail -3 /tmp/browser-requests.log 2>/dev/null || echo "No recent requests"
        
        sleep "$interval"
    done
}

# Claude DevContainer advanced functions loaded silently
# Safe functions: cy-dev, cy-health, cy-cleanup-all, cy-monitor, cy-info
# Detailed functions: cy-health-detailed, cy-monitor-detailed, cy-test-browser