#!/bin/bash
# Claude DevContainer ZSH Configuration Demo
# Demonstrates the features and capabilities of the ZSH configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Demo functions
demo_header() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
 ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
██║     ██║     ███████║██║   ██║██║  ██║█████╗  
██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  
╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
                                                 
DevContainer ZSH Configuration Demo
EOF
    echo -e "${NC}"
    echo
}

demo_section() {
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
    echo
}

demo_command() {
    echo -e "${YELLOW}$ $1${NC}"
    sleep 1
}

demo_output() {
    echo -e "${GREEN}$1${NC}"
}

demo_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

wait_for_key() {
    echo
    echo -e "${BLUE}Press any key to continue...${NC}"
    read -n 1 -s
    echo
}

# Demo sections
demo_introduction() {
    demo_header
    demo_section "Welcome to Claude DevContainer ZSH Configuration"
    
    echo "This demo showcases the powerful ZSH configuration for Claude DevContainer."
    echo "Features include:"
    echo "  • Smart aliases for claude-yolo commands"
    echo "  • Advanced development workflow functions"
    echo "  • Intelligent tab completions"
    echo "  • Browser launcher integration"
    echo "  • Debug session management"
    echo "  • Project scaffolding tools"
    echo
    
    wait_for_key
}

demo_aliases() {
    demo_header
    demo_section "Core Aliases"
    
    echo "Short, memorable aliases for common commands:"
    echo
    
    demo_command "cyb"
    demo_output "→ claude-yolo-build (rebuild container)"
    echo
    
    demo_command "cyu"
    demo_output "→ claude-yolo-up (start container)"
    echo
    
    demo_command "cyc sudo safe-browser-open http://localhost:3000"
    demo_output "→ Launch browser securely in container"
    echo
    
    demo_command "tunnels list"
    demo_output "→ debug-tunnel-manager list (show active tunnels)"
    echo
    
    demo_command "flutter-run ./my_app 8080"
    demo_output "→ flutter-debug-helper run ./my_app 8080"
    echo
    
    demo_info "All aliases support tab completion with intelligent suggestions!"
    
    wait_for_key
}

demo_functions() {
    demo_header
    demo_section "Advanced Functions"
    
    echo "Powerful workflow automation functions:"
    echo
    
    demo_command "cy-dev"
    demo_output "Auto-detects project type and starts development server"
    demo_output "  • Detects package.json → Node.js workflow"
    demo_output "  • Detects pubspec.yaml → Flutter workflow"
    demo_output "  • Detects requirements.txt → Python workflow"
    echo
    
    demo_command "cy-debug-session http://localhost:3000 9222"
    demo_output "Starts comprehensive debug session:"
    demo_output "  • Creates SSH tunnel for port 9222"
    demo_output "  • Launches browser with debugging enabled"
    demo_output "  • Sets up Chrome DevTools access"
    echo
    
    demo_command "cy-scaffold-react my-awesome-app"
    demo_output "Creates new React application with full setup"
    echo
    
    demo_command "cy-health"
    demo_output "Comprehensive system health check:"
    demo_output "  • Container status and resources"
    demo_output "  • Browser launcher configuration"
    demo_output "  • SSH setup verification"
    demo_output "  • Active sessions and tunnels"
    echo
    
    wait_for_key
}

demo_completions() {
    demo_header
    demo_section "Intelligent Tab Completions"
    
    echo "Smart completions for enhanced productivity:"
    echo
    
    demo_command "cyc browser <TAB>"
    demo_output "Suggests common development URLs:"
    demo_output "  • http://localhost:3000 (React dev server)"
    demo_output "  • http://localhost:8080 (Flutter web)"
    demo_output "  • http://localhost:5173 (Vite dev server)"
    demo_output "  • https://github.com (GitHub)"
    echo
    
    demo_command "tunnels create <TAB>"
    demo_output "Suggests debug ports with descriptions:"
    demo_output "  • 9222 (Chrome DevTools default)"
    demo_output "  • 9100 (Flutter DevTools)"
    demo_output "  • 9229 (Node.js debugger)"
    echo
    
    demo_command "flutter-dev <TAB>"
    demo_output "Context-aware project completions:"
    demo_output "  • run, build, serve, doctor"
    demo_output "  • Directory suggestions for project paths"
    echo
    
    demo_info "Completions adapt to your current directory and project type!"
    
    wait_for_key
}

demo_browser_launcher() {
    demo_header
    demo_section "Browser Launcher Integration"
    
    echo "Secure browser launching with comprehensive features:"
    echo
    
    demo_command "browser http://localhost:3000"
    demo_output "Launches browser with security validation"
    echo
    
    demo_command "browser-debug http://localhost:8080"
    demo_output "Launches browser with Chrome DevTools enabled"
    echo
    
    demo_command "cy-test-security"
    demo_output "Tests security validation:"
    demo_output "  ✅ Blocks file:// schemes"
    demo_output "  ✅ Blocks javascript: schemes"
    demo_output "  ✅ Validates HTTP/HTTPS URLs"
    demo_output "  ✅ Rate limiting active"
    echo
    
    demo_command "sessions list"
    demo_output "Shows active browser sessions with details"
    echo
    
    demo_info "All browser launches are logged and monitored for security!"
    
    wait_for_key
}

demo_development_workflows() {
    demo_header
    demo_section "Development Workflows"
    
    echo "Streamlined workflows for common development tasks:"
    echo
    
    demo_command "cy-dev 3000 true"
    demo_output "Smart development startup:"
    demo_output "  • Detects project type automatically"
    demo_output "  • Starts dev server on port 3000"
    demo_output "  • Enables debugging mode"
    demo_output "  • Opens browser with DevTools"
    echo
    
    demo_command "flutter-dev-start ./my_flutter_app 8080"
    demo_output "Complete Flutter development setup:"
    demo_output "  • Configures Flutter debugging environment"
    demo_output "  • Starts Flutter web server"
    demo_output "  • Creates debug tunnels"
    demo_output "  • Launches browser with Flutter DevTools"
    echo
    
    demo_command "cy-monitor 5"
    demo_output "Real-time performance monitoring:"
    demo_output "  • Container resource usage"
    demo_output "  • Active browser sessions"
    demo_output "  • Debug tunnel status"
    demo_output "  • Recent activity logs"
    echo
    
    wait_for_key
}

demo_project_management() {
    demo_header
    demo_section "Project Management"
    
    echo "Project creation and management tools:"
    echo
    
    demo_command "cy-scaffold-react my-react-app"
    demo_output "Creates React app with create-react-app"
    echo
    
    demo_command "cy-scaffold-next my-next-app"
    demo_output "Creates Next.js app with latest template"
    echo
    
    demo_command "cy-flutter-new my-flutter-app"
    demo_output "Creates Flutter app with flutter create"
    echo
    
    demo_command "cy-workspace status"
    demo_output "Workspace information:"
    demo_output "  • Current directory and file count"
    demo_output "  • Git status and changes"
    demo_output "  • Active development resources"
    echo
    
    demo_command "cy-workspace backup"
    demo_output "Creates timestamped workspace backup"
    echo
    
    wait_for_key
}

demo_troubleshooting() {
    demo_header
    demo_section "Troubleshooting and Monitoring"
    
    echo "Built-in debugging and monitoring tools:"
    echo
    
    demo_command "cy-status"
    demo_output "Complete system status overview:"
    demo_output "  • Container health and uptime"
    demo_output "  • Browser sessions and tunnels"
    demo_output "  • Recent logs and activity"
    echo
    
    demo_command "cy-logs"
    demo_output "Consolidated logging view:"
    demo_output "  • Browser request logs"
    demo_output "  • Security events"
    demo_output "  • Session management events"
    echo
    
    demo_command "cy-cleanup-all"
    demo_output "Clean up all resources:"
    demo_output "  • Stop all browser sessions"
    demo_output "  • Clean up debug tunnels"
    demo_output "  • Remove expired sessions"
    echo
    
    demo_info "Comprehensive logging helps with debugging and security auditing!"
    
    wait_for_key
}

demo_installation() {
    demo_header
    demo_section "Installation"
    
    echo "Easy installation with automated installer:"
    echo
    
    demo_command "./install.sh"
    demo_output "Automated installation process:"
    demo_output "  • Checks prerequisites (ZSH availability)"
    demo_output "  • Backs up existing configuration"
    demo_output "  • Installs configuration files"
    demo_output "  • Updates ~/.zshrc automatically"
    demo_output "  • Verifies installation"
    demo_output "  • Tests configuration"
    echo
    
    demo_command "./install.sh test"
    demo_output "Tests existing configuration"
    echo
    
    demo_command "./install.sh uninstall"
    demo_output "Clean removal of configuration"
    echo
    
    demo_info "Installation is safe and reversible with automatic backups!"
    
    wait_for_key
}

demo_conclusion() {
    demo_header
    demo_section "Get Started"
    
    echo "Ready to enhance your Claude DevContainer experience?"
    echo
    echo "🚀 Installation:"
    echo "   cd .devcontainer/zsh"
    echo "   ./install.sh"
    echo
    echo "📚 Documentation:"
    echo "   • README.md - Complete feature overview"
    echo "   • claude-yolo-aliases.zsh - Core aliases and functions"
    echo "   • claude-yolo-functions.zsh - Advanced workflows"
    echo "   • claude-yolo-completions.zsh - Tab completions"
    echo
    echo "💡 Quick Start:"
    echo "   • Type 'cy-help' for command reference"
    echo "   • Use TAB completion everywhere"
    echo "   • Run 'cy-health' to check system status"
    echo "   • Try 'cy-dev' for smart development startup"
    echo
    echo "🔒 Security Features:"
    echo "   • URL validation and filtering"
    echo "   • Rate limiting and abuse prevention"
    echo "   • Comprehensive audit logging"
    echo "   • Isolated browser profiles"
    echo
    echo -e "${GREEN}Thank you for exploring Claude DevContainer ZSH Configuration!${NC}"
    echo -e "${BLUE}Happy coding! 🎉${NC}"
    echo
}

# Main demo flow
main() {
    local sections=(
        demo_introduction
        demo_aliases
        demo_functions
        demo_completions
        demo_browser_launcher
        demo_development_workflows
        demo_project_management
        demo_troubleshooting
        demo_installation
        demo_conclusion
    )
    
    if [[ $# -gt 0 && "$1" == "--quick" ]]; then
        # Quick demo - just show key features
        demo_introduction
        demo_aliases
        demo_functions
        demo_browser_launcher
        demo_conclusion
    else
        # Full demo
        for section in "${sections[@]}"; do
            $section
        done
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Claude DevContainer ZSH Configuration Demo"
        echo
        echo "Usage: $0 [--quick] [--help]"
        echo
        echo "Options:"
        echo "  --quick    Run abbreviated demo"
        echo "  --help     Show this help"
        echo
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac