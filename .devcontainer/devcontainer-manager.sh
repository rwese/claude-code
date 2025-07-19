#!/bin/bash
# DevContainer Management Script
# Provides commands to manage devcontainer lifecycles

set -euo pipefail

show_help() {
    cat << 'EOF'
DevContainer Manager - Manage devcontainer lifecycles

USAGE:
    devcontainer-manager <command> [options]

COMMANDS:
    cleanup [--stop-all]    Clean up development resources
                           --stop-all: Also stop all devcontainers after cleanup
    
    stop-all               Stop all running devcontainers
    
    list                   List all running devcontainers
    
    status                 Show status of current workspace devcontainer

EXAMPLES:
    devcontainer-manager cleanup
    devcontainer-manager cleanup --stop-all
    devcontainer-manager stop-all
    devcontainer-manager list

EOF
}

list_devcontainers() {
    echo "📋 DevContainers currently running:"
    docker ps --filter "name=devcontainer" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | head -20
}

stop_all_devcontainers() {
    echo "🛑 Stopping all devcontainers..."
    
    local containers
    containers=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | head -20)
    
    if [[ -z "$containers" ]]; then
        echo "   No devcontainers running"
        return 0
    fi
    
    local count=0
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            echo "   Stopping: $container"
            docker stop "$container" >/dev/null 2>&1 || true
            count=$((count + 1))
        fi
    done <<< "$containers"
    
    echo "✅ Stopped $count devcontainer(s)"
}

cleanup_resources() {
    local stop_all="${1:-false}"
    
    echo "🧹 Cleaning up development resources..."
    echo "   Stopping all browser sessions..."
    devcontainer up --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . && \
    devcontainer exec --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . browser-session-manager stop-all 2>/dev/null || true
    
    echo "   Cleaning up debug tunnels..."
    devcontainer up --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . && \
    devcontainer exec --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . debug-tunnel-manager cleanup 2>/dev/null || true
    
    echo "   Cleaning up expired sessions..."
    devcontainer up --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . && \
    devcontainer exec --config="${PWD}/.devcontainer/devcontainer.json" --workspace-folder . browser-session-manager cleanup 2>/dev/null || true
    
    if [[ "$stop_all" == "true" ]]; then
        echo ""
        stop_all_devcontainers
    fi
    
    echo "✅ Cleanup complete!"
}

show_status() {
    echo "📊 DevContainer Status:"
    
    # Check if we're in a workspace with devcontainer config
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        echo "   Workspace: $(basename "$PWD")"
        echo "   Config: .devcontainer/devcontainer.json found"
        
        # Try to find the running container for this workspace
        local workspace_hash
        workspace_hash=$(echo "$PWD" | shasum -a 256 | cut -d' ' -f1 | head -c 8)
        local running_container
        running_container=$(docker ps --filter "name=devcontainer" --format "{{.Names}}" | grep "$workspace_hash" | head -1 || true)
        
        if [[ -n "$running_container" ]]; then
            echo "   Status: Running ($running_container)"
        else
            echo "   Status: Not running"
        fi
    else
        echo "   No devcontainer configuration found in current directory"
    fi
    
    echo ""
    list_devcontainers
}

main() {
    case "${1:-help}" in
        "cleanup")
            local stop_all="false"
            if [[ "${2:-}" == "--stop-all" ]]; then
                stop_all="true"
            fi
            cleanup_resources "$stop_all"
            ;;
        
        "stop-all")
            stop_all_devcontainers
            ;;
        
        "list")
            list_devcontainers
            ;;
        
        "status")
            show_status
            ;;
        
        "help"|"--help"|"-h")
            show_help
            ;;
        
        *)
            echo "❌ Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"