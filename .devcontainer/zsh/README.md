# Claude DevContainer ZSH Configuration

This directory contains ZSH configuration files that provide aliases, functions, and completions for the Claude DevContainer and browser launcher system.

## ⚠️ Safety Note

**All functions are designed to be safe by default** - they won't interfere with running Claude instances unless explicitly intended. 

- **Safe functions** (default): Use host-side Docker commands and read-only operations
- **Detailed functions** (*-detailed): Execute commands inside the container and may affect running processes  
- **Destructive functions** ([DESTRUCTIVE]): Intentionally stop/cleanup resources

Use detailed functions only when you need the full functionality and understand they may affect running containers.

## 📁 Files

- **`claude-yolo-aliases.zsh`** - Core aliases and basic functions
- **`claude-yolo-functions.zsh`** - Advanced development workflow functions  
- **`claude-yolo-completions.zsh`** - Intelligent tab completions
- **`README.md`** - This documentation file

## 🚀 Installation

### Option 1: Source Individual Files

Add these lines to your `~/.zshrc`:

```bash
# Claude DevContainer configuration
source /path/to/.devcontainer/zsh/claude-yolo-aliases.zsh
source /path/to/.devcontainer/zsh/claude-yolo-functions.zsh
source /path/to/.devcontainer/zsh/claude-yolo-completions.zsh
```

### Option 2: Source All Files

```bash
# Claude DevContainer configuration
for file in /path/to/.devcontainer/zsh/*.zsh; do
    [[ -r "$file" ]] && source "$file"
done
```

### Option 3: Copy to ZSH Directory

```bash
# Copy to your ZSH configuration directory
mkdir -p ~/.config/zsh/claude-devcontainer
cp .devcontainer/zsh/*.zsh ~/.config/zsh/claude-devcontainer/

# Add to ~/.zshrc
for file in ~/.config/zsh/claude-devcontainer/*.zsh; do
    [[ -r "$file" ]] && source "$file"
done
```

## 🔧 Core Aliases

### DevContainer Management
- `cyb` / `cy-build` → `claude-yolo-build` (rebuild container)
- `cyu` / `cy-up` → `claude-yolo-up` (start container)
- `cyc` / `cy-cmd` → `claude-yolo-cmd` (execute in container)
- `cysh` / `cy-bash` → `claude-yolo-bash` (bash shell)
- `cy` → `claude-yolo` (wrapper script)

### Browser Launcher (for use within container)
- `browser <url>` → `sudo safe-browser-open <url>`
- `browser-debug <url>` → `sudo safe-browser-open --debug <url>`
- `browser-flutter <url>` → `sudo safe-browser-open --flutter <url>`

### Debug Tunnels
- `tunnels` → `debug-tunnel-manager`
- `tunnel-list` → `debug-tunnel-manager list`
- `tunnel-create <port>` → `debug-tunnel-manager create <port>`
- `tunnel-auto` → `debug-tunnel-manager auto`
- `tunnel-cleanup` → `debug-tunnel-manager cleanup`

### Flutter Development
- `flutter-dev` → `flutter-debug-helper`
- `flutter-run [dir] [port]` → `flutter-debug-helper run [dir] [port]`
- `flutter-build [dir]` → `flutter-debug-helper build [dir]`
- `flutter-serve [dir] [port]` → `flutter-debug-helper serve [dir] [port]`

### Session Management
- `sessions` → `browser-session-manager`
- `session-list` → `browser-session-manager list`
- `session-stop <id>` → `browser-session-manager stop <id>`
- `session-cleanup` → `browser-session-manager cleanup`

## 🎯 Advanced Functions

### Development Workflows
- `cy-dev [port] [debug]` - Smart project detection and development startup
- `dev-server [port]` - Quick development server launch
- `dev-debug [port] [debug_port]` - Quick debug server launch
- `flutter-dev-start [dir] [port]` - Quick Flutter development startup

### Project Scaffolding
- `cy-scaffold-react [name]` - Create React application
- `cy-scaffold-next [name]` - Create Next.js application
- `cy-scaffold-vue [name]` - Create Vue.js application
- `cy-flutter-new [name]` - Create Flutter application
- `cy-new-project [name]` - Create generic project

### Debug Sessions
- `cy-debug-session [url] [port]` - Start comprehensive debug session
- `cy-stop-debug [port]` - Stop debug session and cleanup
- `cy-test-security` - Run security validation tests
- `cy-test-browser` - Test browser launcher functionality

### System Management

**Safe Functions (won't affect running containers):**
- `cy-health` - Safe health check (host-side only)
- `cy-status` / `cy-status-safe` - Safe status overview
- `cy-logs` / `cy-logs-safe` - Safe log overview  
- `cy-monitor` - Safe performance monitoring (host-side only)
- `cy-info` - Safe environment information
- `cy-workspace [action]` - Workspace management

**Detailed Functions (may affect running containers):**
- `cy-health-detailed` - Full health check with container commands
- `cy-status-detailed` - Full status with active sessions/tunnels
- `cy-logs-detailed` - Full logs including container operations
- `cy-monitor-detailed` - Full monitoring with container operations
- `cy-cleanup-all` - Clean up all resources **[DESTRUCTIVE]**

## 🎯 Tab Completions

The completion system provides intelligent suggestions for:

### URL Completions
- Common development URLs (`http://localhost:3000`, etc.)
- Framework-specific URLs (React, Flutter, Angular, etc.)
- Documentation sites (MDN, Flutter docs, etc.)

### Port Completions
- Common development ports (3000, 8080, 5173, etc.)
- Debug ports (9222, 9223, 9100, etc.)
- Framework defaults with descriptions

### Command Completions
- All browser launcher options (`--debug`, `--flutter`, etc.)
- Debug tunnel commands (`create`, `destroy`, `list`, etc.)
- Flutter commands (`run`, `build`, `serve`, etc.)
- Session management commands

### Smart Context Completions
- Detects project type (package.json, pubspec.yaml, etc.)
- Suggests relevant commands based on current directory
- Provides npm script completions for Node.js projects

## 💡 Usage Examples

### Quick Development Startup
```bash
# Auto-detect project and start development
cy-dev

# Start with specific port and debugging
cy-dev 8080 true

# Flutter development
flutter-dev-start ./my_app 3000
```

### Browser Launcher
```bash
# Launch browser securely (in container)
cyc browser http://localhost:3000

# Launch with debugging
cyc browser-debug http://localhost:8080

# Quick development server launch
dev-server 4200
```

### Debug Sessions
```bash
# Start comprehensive debug session
cy-debug-session http://localhost:3000 9222

# Stop debug session
cy-stop-debug 9222

# Test security features
cy-test-security
```

### System Monitoring
```bash
# Safe health check (won't affect running containers)
cy-health

# Safe real-time monitoring (host-side only)
cy-monitor 3

# Safe status overview
cy-status

# Safe log overview  
cy-logs

# Detailed functions (may affect running containers)
cy-health-detailed       # Full health check with container commands
cy-monitor-detailed 3    # Full monitoring with container operations
cy-status-detailed       # Full status with sessions/tunnels
cy-logs-detailed         # Full logs with container operations
```

### Project Creation
```bash
# Create React app
cy-scaffold-react my-react-app

# Create Flutter app  
cy-flutter-new my-flutter-app

# Create generic project
cy-new-project my-project
```

## 🔧 Customization

### Adding Custom Aliases
Add your own aliases to any of the `.zsh` files or create a new file:

```bash
# Custom aliases
alias my-dev='cy-dev 3000 true'
alias my-flutter='flutter-dev-start . 8080'
```

### Custom Functions
```bash
function my-workflow() {
    cy-health
    cy-dev 3000
    cy-debug-session http://localhost:3000 9222
}
```

### Custom Completions
```bash
_my_command_completion() {
    _describe 'my options' '(option1:Description option2:Description)'
}
compdef _my_command_completion my-command
```

## 🐛 Troubleshooting

### Completions Not Working
```bash
# Reload completions
autoload -U compinit && compinit

# Check if functions are loaded
which cy-dev
```

### Functions Not Available
```bash
# Check if files are sourced
echo $fpath | grep claude

# Manually source files
source ~/.config/zsh/claude-devcontainer/claude-yolo-aliases.zsh
```

### Performance Issues
The configuration is optimized for performance, but if you experience slowdowns:

```bash
# Disable real-time monitoring
unset -f cy-monitor

# Use lazy loading for heavy functions
autoload -U cy-health cy-info
```

## 📚 Related Documentation

- **Main Documentation**: `.devcontainer/BROWSER_LAUNCHER_README.md`
- **Global Configuration**: `~/.claude/CLAUDE.md`
- **Container Scripts**: `/usr/local/bin/safe-browser-open` and related tools

The ZSH configuration provides a powerful, user-friendly interface to the Claude DevContainer browser launcher system with intelligent completions and workflow automation! 🚀