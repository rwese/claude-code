# Claude DevContainer ZSH Completions
# Source this file in your ~/.zshrc: source /path/to/.devcontainer/zsh/claude-yolo-completions.zsh

# Enable completion system
autoload -U compinit
compinit

# Core claude-yolo command completions
_claude_yolo_build_completion() {
    _describe 'claude-yolo-build options' \
        '(--no-cache:Disable build cache
          --config:Specify config file
          --workspace-folder:Set workspace folder)'
}

_claude_yolo_cmd_completion() {
    local -a commands
    commands=(
        'sudo safe-browser-open:Launch browser securely'
        'browser-session-manager:Manage browser sessions'
        'debug-tunnel-manager:Manage debug tunnels' 
        'flutter-debug-helper:Flutter development helper'
        'ls:List files'
        'cat:Display file content'
        'npm:Node package manager'
        'flutter:Flutter CLI'
        'git:Git version control'
    )
    _describe 'devcontainer commands' commands
}

_browser_url_completion() {
    local -a urls
    urls=(
        'http://localhost:3000:React dev server'
        'http://localhost:8080:Flutter web'
        'http://localhost:5173:Vite dev server'
        'http://localhost:4200:Angular dev server'
        'http://localhost:8000:Python dev server'
        'http://localhost:9000:PHP dev server'
        'https://github.com:GitHub'
        'https://docs.flutter.dev:Flutter docs'
        'https://developer.mozilla.org:MDN Web Docs'
    )
    _describe 'common URLs' urls
}

_debug_port_completion() {
    local -a ports
    ports=(
        '9222:Chrome DevTools default'
        '9223:Chrome DevTools alt'
        '9100:Flutter DevTools'
        '9229:Node.js debugger'
        '5005:Java debugger'
    )
    _describe 'debug ports' ports
}

_safe_browser_open_completion() {
    _arguments \
        '--debug[Enable remote debugging mode]' \
        '--debug-port=[Specify debug port]:port:_debug_port_completion' \
        '--flutter[Enable Flutter debugging mode]' \
        '--help[Show help message]' \
        '*:URL:_browser_url_completion'
}

_debug_tunnel_manager_completion() {
    local -a commands
    commands=(
        'create:Create new debug tunnel'
        'destroy:Destroy specific tunnel'
        'list:List active tunnels'
        'status:Get tunnel status'
        'cleanup:Clean up all tunnels'
        'health:Health check all tunnels'
        'auto:Auto-assign port and create tunnel'
    )
    
    case $words[2] in
        create|destroy|status)
            _describe 'ports' '(9222 9223 9100 9229 5005)'
            ;;
        *)
            _describe 'tunnel commands' commands
            ;;
    esac
}

_flutter_debug_helper_completion() {
    local -a commands
    commands=(
        'run:Launch Flutter web app with debugging'
        'build:Build Flutter web app'
        'serve:Serve static Flutter build'
        'doctor:Run Flutter doctor'
        'setup:Setup debugging environment'
        'cleanup:Clean up debugging resources'
    )
    
    case $words[2] in
        run|build|serve)
            _files -/
            ;;
        *)
            _describe 'flutter commands' commands
            ;;
    esac
}

_browser_session_manager_completion() {
    local -a commands
    commands=(
        'list:List active browser sessions'
        'stop:Stop specific session'
        'stop-all:Stop all sessions'
        'cleanup:Clean up expired sessions'
        'health:Check session health'
        'monitor:Monitor resource usage'
        'init:Initialize session manager'
    )
    
    case $words[2] in
        list)
            _describe 'list options' '(details:Show detailed information)'
            ;;
        stop)
            # Would need to dynamically get session IDs
            _message 'session ID'
            ;;
        *)
            _describe 'session commands' commands
            ;;
    esac
}

# Custom function completions
_cy_dev_completion() {
    _arguments \
        '1:port:(3000 8080 5173 4200 8000 9000)' \
        '2:debug mode:(true false)'
}

_cy_debug_session_completion() {
    _arguments \
        '1:URL:_browser_url_completion' \
        '2:debug port:_debug_port_completion'
}

_cy_scaffold_completion() {
    _arguments '1:app name:'
}

_cy_workspace_completion() {
    local -a actions
    actions=(
        'status:Show workspace status'
        'clean:Clean workspace'
        'backup:Create workspace backup'
    )
    _describe 'workspace actions' actions
}

# Project type completions
_project_completion() {
    local -a projects
    projects=(
        'react:React application'
        'next:Next.js application'
        'vue:Vue.js application'
        'flutter:Flutter application'
        'node:Node.js application'
        'python:Python application'
    )
    _describe 'project types' projects
}

# Register all completions
compdef _claude_yolo_build_completion claude-yolo-build cyb
compdef _claude_yolo_cmd_completion claude-yolo-cmd cyc
compdef _safe_browser_open_completion browser browser-debug browser-flutter
compdef _debug_tunnel_manager_completion tunnels tunnel-list tunnel-create tunnel-auto tunnel-cleanup
compdef _flutter_debug_helper_completion flutter-dev flutter-run flutter-build flutter-serve
compdef _browser_session_manager_completion sessions session-list session-stop session-cleanup
compdef _cy_dev_completion cy-dev
compdef _cy_debug_session_completion cy-debug-session cy-stop-debug
compdef _cy_scaffold_completion cy-scaffold-react cy-scaffold-next cy-scaffold-vue cy-flutter-new
compdef _cy_workspace_completion cy-workspace
compdef _project_completion cy-new-project

# Advanced completions for common development scenarios
_common_ports_completion() {
    local -a ports
    ports=(
        '3000:React/Express default'
        '3001:React alternative'
        '8080:Flutter web/Tomcat'
        '8000:Python/Django'
        '5173:Vite'
        '4200:Angular'
        '5000:Flask'
        '8888:Jupyter'
        '9000:PHP/Gatsby'
        '1313:Hugo'
        '4000:Jekyll'
        '8888:Lab environments'
    )
    _describe 'common development ports' ports
}

# Context-aware completions based on current directory
_smart_project_completion() {
    if [[ -f "package.json" ]]; then
        # Node.js project - suggest npm scripts
        local scripts=($(jq -r '.scripts | keys[]' package.json 2>/dev/null))
        if [[ ${#scripts[@]} -gt 0 ]]; then
            _describe 'npm scripts' scripts
        fi
    elif [[ -f "pubspec.yaml" ]]; then
        # Flutter project
        _describe 'flutter commands' '(run build test clean)'
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        # Python project
        _describe 'python commands' '(runserver manage.py app.py)'
    fi
}

# Dynamic URL completion based on running processes
_dynamic_url_completion() {
    local -a running_urls
    
    # Check for common development servers (this would need to be run in container context)
    running_urls=(
        'http://localhost:3000:Detected React server'
        'http://localhost:8080:Detected Flutter web'
        'http://localhost:5173:Detected Vite server'
    )
    
    _describe 'detected running servers' running_urls
}

# Git-aware completions
_git_branch_urls() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ -n "$current_branch" ]]; then
            _describe 'branch-based URLs' "http://localhost:3000/$current_branch:Branch preview"
        fi
    fi
}

# Context menu style help
_cy_help_menu() {
    local -a help_topics
    help_topics=(
        'commands:List all available commands'
        'browser:Browser launcher help'
        'tunnels:Debug tunnel help'
        'flutter:Flutter development help'
        'sessions:Session management help'
        'security:Security features help'
        'troubleshooting:Common issues and solutions'
    )
    _describe 'help topics' help_topics
}

compdef _cy_help_menu cy-help

echo "Claude DevContainer ZSH completions loaded! 🎯"
echo "Press TAB for intelligent completions on all cy-* commands"