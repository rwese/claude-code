# Docker Commands for DevContainer Management

This document provides Docker commands for managing devcontainers, utilizing the improved labels added to make containers easier to identify.

## Container Identification

### List all devcontainers
```bash
# List all devcontainers by project
docker ps -a --filter "label=devcontainer.project=claude-code"

# List all development containers
docker ps -a --filter "label=devcontainer.type=development"

# List running devcontainers
docker ps --filter "label=devcontainer.project=claude-code"
```

### Inspect devcontainer details
```bash
# Get detailed information about a devcontainer
docker inspect <container_id_or_name>

# Get specific label information
docker inspect <container_id> --format='{{.Config.Labels}}'

# Get container name and services
docker inspect <container_id> --format='{{.Name}} - {{index .Config.Labels "devcontainer.services"}}'
```

## Container Management

### Start/Stop containers
```bash
# Start a stopped devcontainer
docker start <container_id_or_name>

# Stop a running devcontainer
docker stop <container_id_or_name>

# Restart a devcontainer
docker restart <container_id_or_name>

# Start with interactive shell
docker start -i <container_id_or_name>
```

### Execute commands in running containers
```bash
# Open bash shell in running devcontainer
docker exec -it <container_id_or_name> bash

# Run specific command
docker exec -it <container_id_or_name> <command>

# Run as specific user (node)
docker exec -it --user node <container_id_or_name> bash
```

### Remove containers
```bash
# Remove stopped devcontainer
docker rm <container_id_or_name>

# Force remove running devcontainer
docker rm -f <container_id_or_name>

# Remove all stopped devcontainers for this project
docker container prune --filter "label=devcontainer.project=claude-code"
```

## Image Management

### List devcontainer images
```bash
# List all images with devcontainer labels
docker images --filter "label=devcontainer.project=claude-code"

# List images with detailed information
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
```

### Inspect image details
```bash
# Get image labels
docker inspect <image_id> --format='{{.Config.Labels}}'

# Get image metadata
docker inspect <image_id> --format='{{json .Config.Labels}}' | jq
```

### Remove images
```bash
# Remove specific image
docker rmi <image_id_or_name>

# Remove unused images
docker image prune --filter "label=devcontainer.project=claude-code"
```

## Volume Management

### List devcontainer volumes
```bash
# List all volumes (devcontainer volumes are prefixed with project name)
docker volume ls --filter "name=claude-code"

# List volumes with details
docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
```

### Inspect volume details
```bash
# Get volume information
docker volume inspect <volume_name>

# Get volume mount point
docker volume inspect <volume_name> --format='{{.Mountpoint}}'
```

### Remove volumes
```bash
# Remove specific volume
docker volume rm <volume_name>

# Remove unused volumes
docker volume prune
```

## Advanced Management

### Resource usage monitoring
```bash
# Monitor resource usage of devcontainers
docker stats --filter "label=devcontainer.project=claude-code"

# Get resource usage for specific container
docker stats <container_id_or_name> --no-stream
```

### Log management
```bash
# View container logs
docker logs <container_id_or_name>

# Follow logs in real-time
docker logs -f <container_id_or_name>

# View logs with timestamps
docker logs -t <container_id_or_name>

# Limit log output
docker logs --tail 100 <container_id_or_name>
```

### Network management
```bash
# List networks
docker network ls

# Inspect container network
docker inspect <container_id> --format='{{.NetworkSettings.Networks}}'

# Connect container to network
docker network connect <network_name> <container_id>
```

## Bulk Operations

### Clean up all devcontainer resources
```bash
# Remove all stopped containers for this project
docker container prune --filter "label=devcontainer.project=claude-code"

# Remove all unused images for this project
docker image prune --filter "label=devcontainer.project=claude-code"

# Remove all unused volumes
docker volume prune

# Complete cleanup (be careful!)
docker system prune --filter "label=devcontainer.project=claude-code"
```

### Backup and export
```bash
# Export container to tar file
docker export <container_id> > claude-code-devcontainer.tar

# Save image to tar file
docker save <image_id> > claude-code-image.tar

# Load image from tar file
docker load < claude-code-image.tar
```

## Useful One-liners

### Quick identification commands
```bash
# Get container ID by project
docker ps -q --filter "label=devcontainer.project=claude-code"

# Get container name and services
docker ps --filter "label=devcontainer.project=claude-code" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Count running devcontainers
docker ps --filter "label=devcontainer.project=claude-code" | wc -l
```

### Maintenance commands
```bash
# Remove all exited containers for this project
docker rm $(docker ps -a -q --filter "label=devcontainer.project=claude-code" --filter "status=exited")

# Stop all running containers for this project
docker stop $(docker ps -q --filter "label=devcontainer.project=claude-code")

# Get total disk usage by devcontainer images
docker images --filter "label=devcontainer.project=claude-code" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

## Environment Variables

The devcontainer supports these environment variables:
- `PERPLEXITY_API_KEY`: Enables Perplexity MCP service
- `GITHUB_TOKEN`: Enables GitHub integration
- `TZ`: Sets timezone (default: Europe/Berlin)

## Labels Reference

The following labels are available for filtering:

- `devcontainer.project=claude-code`: Project identifier
- `devcontainer.workspace=<workspace_name>`: Workspace name
- `devcontainer.type=development`: Container type
- `devcontainer.services=mcp-playwright,mcp-context7,firewall,proxy`: Available services
- `devcontainer.description=Claude Code development environment with MCP services`: Description
- `maintainer=claude-code-team`: Maintainer information

## DevContainer-specific Commands

### Using devcontainer CLI
```bash
# List devcontainers
devcontainer ls

# Build devcontainer
devcontainer build --workspace-folder .

# Start devcontainer
devcontainer up --workspace-folder .

# Execute command in devcontainer
devcontainer exec --workspace-folder . <command>
```

### Using project aliases
```bash
# Build and start (from project root)
claude-yolo-build

# Execute command
claude-yolo-cmd <command>

# Open bash shell
claude-yolo-bash
```

## Troubleshooting

### Common issues
1. **Container won't start**: Check logs with `docker logs <container_id>`
2. **Permission issues**: Ensure proper user mapping in devcontainer.json
3. **Network issues**: Verify firewall rules and proxy settings
4. **Volume issues**: Check volume mounts and permissions

### Debug commands
```bash
# Check container processes
docker top <container_id>

# Check resource limits
docker inspect <container_id> --format='{{.HostConfig.Memory}}'

# Check environment variables
docker inspect <container_id> --format='{{.Config.Env}}'
```