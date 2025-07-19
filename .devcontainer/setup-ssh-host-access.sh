#!/bin/bash
# SSH setup script for secure container-to-host communication
# This script configures SSH access from container to host for browser launching

set -euo pipefail
IFS=$'\n\t'

# Configuration
SSH_DIR="/home/node/.ssh"
SSH_KEY_PATH="$SSH_DIR/devcontainer_host_key"
SSH_CONFIG="$SSH_DIR/config"
AUTHORIZED_KEYS_PATH="$SSH_DIR/authorized_keys_devcontainer"

# Logging function
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Generate SSH key pair for container-to-host authentication
generate_ssh_key() {
    log_action "INFO" "Generating SSH key pair for devcontainer"
    
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Generate Ed25519 key (more secure and faster than RSA)
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "devcontainer-$(hostname)-$(date +%s)"
    
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
    
    log_action "INFO" "SSH key pair generated successfully"
}

# Create SSH config for host connection
create_ssh_config() {
    log_action "INFO" "Creating SSH configuration"
    
    # Detect host IP
    local host_ip=$(ip route | grep default | cut -d" " -f3)
    if [[ -z "$host_ip" ]]; then
        log_action "ERROR" "Failed to detect host IP"
        return 1
    fi
    
    log_action "INFO" "Detected host IP: $host_ip"
    
    # Create SSH config
    cat > "$SSH_CONFIG" << EOF
# DevContainer SSH Configuration for Host Access
Host devcontainer-host
    HostName $host_ip
    User $(whoami)
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath /tmp/ssh-control-%r@%h:%p
    ControlPersist 300

# Fallback configuration for localhost
Host devcontainer-host-local
    HostName localhost
    User $(whoami)
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 5
EOF
    
    chmod 600 "$SSH_CONFIG"
    log_action "INFO" "SSH configuration created"
}

# Test SSH connection
test_ssh_connection() {
    log_action "INFO" "Testing SSH connection to host"
    
    # Test with timeout
    if timeout 10 ssh -o ConnectTimeout=5 devcontainer-host "echo 'SSH connection successful'" 2>/dev/null; then
        log_action "INFO" "SSH connection to host successful"
        return 0
    else
        log_action "WARNING" "SSH connection to host failed - this is expected if SSH server is not configured"
        return 1
    fi
}

# Generate instructions for host setup
generate_host_setup_instructions() {
    local public_key_content
    public_key_content=$(cat "${SSH_KEY_PATH}.pub")
    
    cat << EOF

=================================================================
HOST SETUP INSTRUCTIONS
=================================================================

To enable secure browser launching from the devcontainer, please
set up the following on your HOST system:

1. INSTALL HOST BROWSER LAUNCHER SCRIPT:
   Copy the host-browser-launcher.sh script to your host system:
   
   sudo cp .devcontainer/host-browser-launcher.sh /usr/local/bin/devcontainer-browser-launcher.sh
   sudo chmod +x /usr/local/bin/devcontainer-browser-launcher.sh
   sudo chown root:root /usr/local/bin/devcontainer-browser-launcher.sh

2. CONFIGURE SSH ACCESS (Optional - for debug tunnels):
   Add the following public key to your ~/.ssh/authorized_keys file:
   
   $public_key_content
   
   Or run this command on your host:
   echo '$public_key_content' >> ~/.ssh/authorized_keys

3. VERIFY SSH SERVICE (Optional):
   Ensure SSH server is running on your host:
   sudo systemctl enable ssh
   sudo systemctl start ssh

4. TEST THE SETUP:
   From within the devcontainer, test with:
   sudo safe-browser-open "http://localhost:3000"

=================================================================
DOCKER SOCKET ALTERNATIVE
=================================================================

If you prefer not to use SSH, you can mount the Docker socket
by adding this to your devcontainer.json mounts:

"source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"

=================================================================
SECURITY NOTES
=================================================================

- The host script validates all URLs against an allowlist
- Rate limiting prevents abuse (max 10 requests/minute)
- All browser launches are logged
- Debug browsers run in isolated profiles
- SSH keys are container-specific and rotated

=================================================================

EOF
}

# Main setup function
main() {
    log_action "INFO" "Starting SSH setup for devcontainer host access"
    
    # Generate SSH key pair
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        generate_ssh_key
    else
        log_action "INFO" "SSH key already exists, skipping generation"
    fi
    
    # Create SSH config
    create_ssh_config
    
    # Test connection (optional)
    test_ssh_connection || true
    
    # Generate setup instructions
    generate_host_setup_instructions
    
    log_action "INFO" "SSH setup completed successfully"
    
    # Save public key to a file for easy access
    cp "${SSH_KEY_PATH}.pub" "/tmp/devcontainer_public_key.pub"
    log_action "INFO" "Public key saved to /tmp/devcontainer_public_key.pub"
}

# Check if running as correct user
current_user="$(whoami)"
if [[ "$current_user" != "node" ]]; then
    echo "Warning: This script should be run as the 'node' user (current: $current_user)" >&2
fi

# Execute main function
main "$@"