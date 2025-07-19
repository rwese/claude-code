# DevContainer Browser Launcher with Debug Support

This solution provides secure browser launching capabilities from within the devcontainer, with full support for Chrome DevTools debugging and Flutter development workflows.

## 🔧 Features

- **Secure Browser Launching**: Open browsers on the host system from within the container
- **Debug Support**: Full Chrome DevTools integration with port forwarding
- **Flutter Integration**: Specialized Flutter development and debugging support
- **Rate Limiting**: Protection against abuse with configurable limits
- **URL Validation**: Strict allowlist-based URL validation for security
- **Session Management**: Track and manage multiple browser sessions
- **SSH Tunneling**: Secure port forwarding for debugging protocols
- **Comprehensive Logging**: Security audit trails and monitoring

## 🚀 Quick Start

### Basic Browser Launch
```bash
sudo safe-browser-open "http://localhost:3000"
```

### Debug Mode
```bash
sudo safe-browser-open --debug "http://localhost:8080"
```

### Flutter Development
```bash
flutter-debug-helper run ./my_flutter_app
```

## 📋 Components

### Core Scripts

1. **`safe-browser-open`** - Main browser launcher command (sudo-enabled)
2. **`host-browser-launcher.sh`** - Host-side browser launcher (to be installed on host)
3. **`debug-tunnel-manager`** - SSH tunnel management for debugging
4. **`flutter-debug-helper`** - Flutter-specific development workflows
5. **`browser-session-manager`** - Session tracking and cleanup
6. **`security-validation.sh`** - Security functions and logging

### Setup Scripts

- **`setup-ssh-host-access.sh`** - Configure SSH for container-to-host communication

## 🛠 Installation

### Automatic Setup (Recommended)

The devcontainer will automatically set up most components during container creation. After the container starts:

1. **Install Host Script**: Copy the host browser launcher to your host system:
   ```bash
   sudo cp .devcontainer/host-browser-launcher.sh /usr/local/bin/devcontainer-browser-launcher.sh
   sudo chmod +x /usr/local/bin/devcontainer-browser-launcher.sh
   sudo chown root:root /usr/local/bin/devcontainer-browser-launcher.sh
   ```

2. **Configure SSH Access** (Optional - for debug tunnels):
   ```bash
   # Get the container's public key
   cat /tmp/devcontainer_public_key.pub
   
   # Add to your host's ~/.ssh/authorized_keys
   echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
   ```

### Manual Setup

If you need to set up manually:

```bash
# Initialize SSH setup
/usr/local/bin/setup-ssh-host-access.sh

# Initialize session manager
browser-session-manager init

# Test the setup
sudo safe-browser-open "http://localhost:3000"
```

## 🔒 Security Features

### URL Validation
- Only HTTP/HTTPS schemes allowed
- Domain allowlist validation with wildcard support
- Path validation to prevent directory traversal
- Automatic blocking of dangerous schemes (file://, javascript:, etc.)

### Rate Limiting
- Maximum 10 browser launches per minute per user
- Configurable limits and time windows
- Automatic cleanup of rate limit data

### Allowed Domains
By default, these domains are allowed:
- `localhost`, `127.0.0.1`, `::1`
- `*.localhost`, `*.local`
- `github.com`, `*.github.com`
- `stackoverflow.com`, `*.stackoverflow.com`
- `developer.mozilla.org`
- `docs.flutter.dev`, `pub.dev`

### Audit Logging
All browser launches and security events are logged to:
- `/var/log/devcontainer-security.log`
- `/var/log/devcontainer-browser.log`

## 🐛 Debug Features

### Chrome DevTools
```bash
# Launch with debugging enabled
sudo safe-browser-open --debug "http://localhost:3000"

# Manual tunnel management
debug-tunnel-manager create 9222
debug-tunnel-manager list
debug-tunnel-manager destroy 9222
```

### Flutter Development
```bash
# Run Flutter app with debugging
flutter-debug-helper run

# Build Flutter web app
flutter-debug-helper build

# Serve static build
flutter-debug-helper serve
```

### Debug URLs
When debugging is enabled:
- **Chrome DevTools**: `http://localhost:9222`
- **Flutter DevTools**: `http://localhost:9100`
- **Custom Debug Port**: `http://localhost:<port>`

## 📊 Session Management

### List Active Sessions
```bash
browser-session-manager list
browser-session-manager list details
```

### Stop Sessions
```bash
# Stop specific session
browser-session-manager stop session-123

# Stop all sessions
browser-session-manager stop-all
```

### Monitor Resources
```bash
# Health check
browser-session-manager health

# Resource monitoring
browser-session-manager monitor
```

## 🔧 Configuration

### Environment Variables
- `DEVCONTAINER_HOST_USER` - Host username for SSH (default: current user)
- `CHROME_EXECUTABLE` - Path to Chrome binary
- `FLUTTER_WEB_AUTO_DETECT` - Flutter web detection (default: false)

### Limits and Timeouts
- **Max Sessions**: 5 concurrent browser sessions
- **Session Timeout**: 1 hour
- **Rate Limit**: 10 requests per minute
- **Debug Port Range**: 9200-9299

### Log Configuration
- **Max Log Size**: 50MB (auto-rotated)
- **Log Retention**: 30 days
- **Security Log Location**: `/var/log/devcontainer-security.log`

## 🚨 Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   ```bash
   # Check sudo configuration
   sudo -l | grep safe-browser-open
   ```

2. **SSH connection failures**
   ```bash
   # Test SSH connectivity
   ssh devcontainer-host "echo 'Connection successful'"
   
   # Regenerate SSH keys
   /usr/local/bin/setup-ssh-host-access.sh
   ```

3. **Debug tunnels not working**
   ```bash
   # Check tunnel status
   debug-tunnel-manager list
   debug-tunnel-manager health
   
   # Restart tunnels
   debug-tunnel-manager cleanup
   debug-tunnel-manager create 9222
   ```

4. **Browser not launching**
   ```bash
   # Check host script installation
   ls -la /usr/local/bin/devcontainer-browser-launcher.sh
   
   # Test host script directly
   ssh devcontainer-host "/usr/local/bin/devcontainer-browser-launcher.sh 'http://localhost:3000'"
   ```

### Log Analysis

```bash
# View security logs
tail -f /var/log/devcontainer-security.log

# Check rate limiting
grep "RATE_LIMITED" /var/log/devcontainer-security.log

# Monitor browser requests
grep "BROWSER_REQUEST" /var/log/devcontainer-security.log
```

## 🧪 Examples

### React Development
```bash
# Start React dev server
npm start

# Launch with debugging
sudo safe-browser-open --debug "http://localhost:3000"
```

### Flutter Web Development
```bash
# Complete Flutter workflow
flutter-debug-helper run ./my_app 8080

# Access URLs:
# App: http://localhost:8080
# DevTools: http://localhost:9100
# Chrome DevTools: http://localhost:9222
```

### Custom Debug Setup
```bash
# Create custom debug session
debug-tunnel-manager auto  # Gets available port
sudo safe-browser-open --debug-port=9223 "http://localhost:4000"
```

## 🔐 Security Considerations

### For Examining Potentially Malicious Code

This solution is designed with security in mind for examining potentially nefarious code:

1. **Isolated Browser Execution**: Browsers run in isolated profiles
2. **Network Restrictions**: Firewall rules limit outbound connections
3. **URL Validation**: Strict allowlist prevents access to unauthorized sites
4. **Rate Limiting**: Prevents abuse and resource exhaustion
5. **Comprehensive Logging**: Full audit trail of all activities
6. **Session Limits**: Prevents resource exhaustion
7. **Automatic Cleanup**: Expired sessions are automatically terminated

### Host Protection

The host system is protected through:
- SSH key-based authentication
- Sudo restrictions to specific commands
- Process isolation
- Resource monitoring and limits

## 📝 Development Notes

### Adding New Allowed Domains

Edit `host-browser-launcher.sh` and add to the `ALLOWED_DOMAINS` array:
```bash
ALLOWED_DOMAINS=(
    # ... existing domains ...
    "newdomain.com"
    "*.newdomain.com"
)
```

### Customizing Debug Ports

Modify the port ranges in:
- `debug-tunnel-manager.sh`: `DEBUG_PORT_RANGE_START/END`
- `security-validation.sh`: `validate_port_number` calls

### Adding Security Rules

Add new validation functions to `security-validation.sh` and integrate them into `validate_browser_request()`.

## 📚 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DevContainer  │    │   SSH Tunnel    │    │   Host System   │
│                 │    │                 │    │                 │
│ safe-browser-   │───▶│ Port Forwarding │───▶│ Browser Launch  │
│ open            │    │ (Debug Ports)   │    │ (Chrome/Firefox)│
│                 │    │                 │    │                 │
│ Flutter Debug   │    │ Secure Channel  │    │ DevTools Access │
│ Helper          │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Session Manager │    │ Security Logger │    │ Rate Limiter    │
│ (Cleanup)       │    │ (Audit Trail)   │    │ (Abuse Prevent) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

This comprehensive solution provides secure, feature-rich browser launching capabilities while maintaining security for examining potentially malicious code in the devcontainer environment.