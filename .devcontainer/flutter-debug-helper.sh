#!/bin/bash
# Flutter Debug Helper for DevContainer
# Integrates Flutter development with secure browser launching and debugging

set -euo pipefail
IFS=$'\n\t'

# Configuration
FLUTTER_DEBUG_PORT="9100"
CHROME_DEBUG_PORT="9222"
FLUTTER_WEB_PORT="8080"
DEBUG_TUNNEL_MANAGER="/usr/local/bin/debug-tunnel-manager.sh"
BROWSER_LAUNCHER="/usr/local/bin/safe-browser-open"

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Check if Flutter is installed and configured
check_flutter_setup() {
    if ! command -v flutter >/dev/null 2>&1; then
        echo "Error: Flutter is not installed or not in PATH" >&2
        return 1
    fi
    
    # Check Flutter web support
    if ! flutter devices | grep -q "Chrome"; then
        log_action "WARNING" "Chrome device not available for Flutter"
    fi
    
    return 0
}

# Setup Flutter debugging environment
setup_flutter_debug() {
    log_action "INFO" "Setting up Flutter debugging environment"
    
    # Create debug tunnels for Flutter DevTools and Chrome
    if command -v "$DEBUG_TUNNEL_MANAGER" >/dev/null 2>&1; then
        "$DEBUG_TUNNEL_MANAGER" create "$FLUTTER_DEBUG_PORT" || true
        "$DEBUG_TUNNEL_MANAGER" create "$CHROME_DEBUG_PORT" || true
    else
        log_action "WARNING" "Debug tunnel manager not available"
    fi
    
    # Set Flutter environment variables for debugging
    export FLUTTER_WEB_AUTO_DETECT=false
    export FLUTTER_WEB_USE_SKIA=true
    
    log_action "INFO" "Flutter debugging environment configured"
}

# Launch Flutter web app with debugging
launch_flutter_web() {
    local project_dir="${1:-.}"
    local web_port="${2:-$FLUTTER_WEB_PORT}"
    local device="${3:-chrome}"
    
    log_action "INFO" "Launching Flutter web app from $project_dir"
    
    # Verify project directory
    if [[ ! -f "$project_dir/pubspec.yaml" ]]; then
        echo "Error: No pubspec.yaml found in $project_dir" >&2
        return 1
    fi
    
    # Setup debugging environment
    setup_flutter_debug
    
    # Configure Chrome flags for debugging
    local chrome_args="--remote-debugging-port=$CHROME_DEBUG_PORT"
    chrome_args="$chrome_args,--disable-web-security"
    chrome_args="$chrome_args,--disable-features=VizDisplayCompositor"
    chrome_args="$chrome_args,--disable-background-timer-throttling"
    
    export CHROME_EXECUTABLE="/usr/bin/chromium"
    
    log_action "INFO" "Starting Flutter web server on port $web_port"
    
    # Change to project directory
    cd "$project_dir"
    
    # Run Flutter in background with debugging enabled
    flutter run -d chrome \
        --web-port="$web_port" \
        --web-hostname="0.0.0.0" \
        --web-browser-flag="$chrome_args" \
        --debug \
        --enable-software-rendering \
        --devtools-server-address="0.0.0.0" \
        --devtools-server-port="$FLUTTER_DEBUG_PORT" &
    
    local flutter_pid=$!
    
    # Wait for Flutter to start
    log_action "INFO" "Waiting for Flutter web server to start..."
    sleep 5
    
    # Check if Flutter process is still running
    if ! kill -0 "$flutter_pid" 2>/dev/null; then
        log_action "ERROR" "Flutter process failed to start"
        return 1
    fi
    
    # Launch browser using secure launcher
    local app_url="http://localhost:$web_port"
    log_action "INFO" "Launching browser for Flutter app: $app_url"
    
    if command -v "$BROWSER_LAUNCHER" >/dev/null 2>&1; then
        sudo "$BROWSER_LAUNCHER" --flutter --debug-port="$CHROME_DEBUG_PORT" "$app_url"
    else
        log_action "ERROR" "Browser launcher not available"
        return 1
    fi
    
    # Display debugging information
    cat << EOF

=================================================================
FLUTTER DEBUG SESSION STARTED
=================================================================

Flutter App URL:     $app_url
DevTools URL:        http://localhost:$FLUTTER_DEBUG_PORT
Chrome DevTools:     http://localhost:$CHROME_DEBUG_PORT

Flutter PID:         $flutter_pid

To stop the Flutter app:
  kill $flutter_pid

To access DevTools from host:
  Open browser to: http://localhost:$FLUTTER_DEBUG_PORT

To debug in Chrome:
  1. Open: http://localhost:$CHROME_DEBUG_PORT
  2. Click on your Flutter app tab
  3. Use Chrome DevTools for debugging

=================================================================

EOF
    
    # Wait for Flutter process
    wait "$flutter_pid"
}

# Build Flutter web app
build_flutter_web() {
    local project_dir="${1:-.}"
    local output_dir="${2:-build/web}"
    
    log_action "INFO" "Building Flutter web app"
    
    cd "$project_dir"
    
    # Clean previous build
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Build for web
    flutter build web --debug --web-renderer html
    
    log_action "INFO" "Flutter web build completed in $output_dir"
}

# Serve static Flutter build
serve_flutter_build() {
    local project_dir="${1:-.}"
    local port="${2:-8080}"
    local build_dir="$project_dir/build/web"
    
    if [[ ! -d "$build_dir" ]]; then
        echo "Error: Build directory not found. Run build first." >&2
        return 1
    fi
    
    log_action "INFO" "Serving Flutter build from $build_dir on port $port"
    
    # Use Python's built-in server
    if command -v python3 >/dev/null 2>&1; then
        cd "$build_dir"
        python3 -m http.server "$port" &
        local server_pid=$!
        
        sleep 2
        
        # Launch browser
        local app_url="http://localhost:$port"
        if command -v "$BROWSER_LAUNCHER" >/dev/null 2>&1; then
            sudo "$BROWSER_LAUNCHER" "$app_url"
        fi
        
        echo "Static server PID: $server_pid"
        echo "App URL: $app_url"
        echo "To stop server: kill $server_pid"
        
        wait "$server_pid"
    else
        echo "Error: Python3 not available for static server" >&2
        return 1
    fi
}

# Flutter doctor check
flutter_doctor() {
    log_action "INFO" "Running Flutter doctor"
    flutter doctor -v
}

# Clean up Flutter debugging resources
cleanup_flutter_debug() {
    log_action "INFO" "Cleaning up Flutter debugging resources"
    
    # Stop debug tunnels
    if command -v "$DEBUG_TUNNEL_MANAGER" >/dev/null 2>&1; then
        "$DEBUG_TUNNEL_MANAGER" destroy "$FLUTTER_DEBUG_PORT" 2>/dev/null || true
        "$DEBUG_TUNNEL_MANAGER" destroy "$CHROME_DEBUG_PORT" 2>/dev/null || true
    fi
    
    # Kill any running Flutter processes
    pkill -f "flutter run" 2>/dev/null || true
    pkill -f "dart.*flutter" 2>/dev/null || true
    
    log_action "INFO" "Flutter debugging cleanup completed"
}

# Usage information
usage() {
    cat << 'EOF'
Usage: flutter-debug-helper.sh <command> [options]

COMMANDS:
  run [project_dir] [port]           Launch Flutter web app with debugging
  build [project_dir] [output_dir]   Build Flutter web app
  serve [project_dir] [port]         Serve static Flutter build  
  doctor                             Run Flutter doctor
  setup                              Setup debugging environment
  cleanup                            Clean up debugging resources

OPTIONS:
  -h, --help                         Show this help message

EXAMPLES:
  flutter-debug-helper.sh run                    # Run current project
  flutter-debug-helper.sh run ./my_app 3000      # Run specific project on port 3000
  flutter-debug-helper.sh build ./my_app         # Build specific project
  flutter-debug-helper.sh serve ./my_app 8080    # Serve built app on port 8080
  flutter-debug-helper.sh doctor                 # Check Flutter setup
  flutter-debug-helper.sh cleanup                # Clean up debug resources

DEBUGGING:
  - Flutter DevTools available at: http://localhost:9100
  - Chrome DevTools available at: http://localhost:9222
  - Web app typically runs on: http://localhost:8080

REQUIREMENTS:
  - Flutter SDK installed and configured
  - Chrome/Chromium browser available
  - Debug tunnel manager and browser launcher configured
EOF
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        run)
            check_flutter_setup || exit 1
            launch_flutter_web "${2:-.}" "${3:-$FLUTTER_WEB_PORT}"
            ;;
        
        build)
            check_flutter_setup || exit 1
            build_flutter_web "${2:-.}" "${3:-build/web}"
            ;;
        
        serve)
            serve_flutter_build "${2:-.}" "${3:-8080}"
            ;;
        
        doctor)
            check_flutter_setup || exit 1
            flutter_doctor
            ;;
        
        setup)
            check_flutter_setup || exit 1
            setup_flutter_debug
            ;;
        
        cleanup)
            cleanup_flutter_debug
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
    # Clean up any background processes if script is interrupted
    pkill -P $$ 2>/dev/null || true
}

trap cleanup_on_exit EXIT INT TERM

# Execute main function
main "$@"