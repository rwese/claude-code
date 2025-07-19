#!/bin/bash
# MCP Service Configuration Script
# This script configures MCP services based on available environment variables

set -e

echo "🔧 Configuring MCP services..."

# Ensure .claude directory permissions are correct for bind mount
echo "📁 Ensuring .claude directory permissions..."
if [ -d "/home/node/.claude" ]; then
    # Fix permissions for bind-mounted .claude directory
    if [ -w "/home/node/.claude" ] || sudo chown -R node:node "/home/node/.claude" 2>/dev/null; then
        echo "✅ .claude directory permissions verified"
    else
        echo "⚠️  Warning: Could not fix .claude directory permissions"
    fi
    
    # Ensure .claude.json exists with proper permissions
    if [ ! -f "/home/node/.claude/.claude.json" ]; then
        echo "📄 Creating .claude.json with default settings..."
        echo '{"bypassPermissionsModeAccepted": true}' > "/home/node/.claude/.claude.json"
    fi
else
    echo "❌ .claude directory not found at /home/node/.claude"
fi

# Always configure these core services
echo "📦 Adding core MCP services..."
claude mcp add -s local playwright -- npx -y @playwright/mcp@latest 2>/dev/null || echo "⚠️  Playwright MCP already configured"
claude mcp add -s local context7 -- npx -y @upstash/context7-mcp 2>/dev/null || echo "⚠️  Context7 MCP already configured"

# Configure Perplexity MCP if API key is available
if [ -n "$PERPLEXITY_API_KEY" ]; then
    echo "🔍 Configuring Perplexity MCP service..."
    claude mcp add -s local perplexity -- npx -y server-perplexity-ask 2>/dev/null || echo "⚠️  Perplexity MCP already configured"
else
    echo "⏭️  Skipping Perplexity MCP (no API key found)"
fi

# Configure GitHub MCP if token is available
if [ -n "$GITHUB_TOKEN" ]; then
    echo "🐙 Configuring GitHub MCP service..."
    # Note: GitHub MCP server is now distributed as Docker image ghcr.io/github/github-mcp-server
    # For now, skip GitHub MCP configuration - will be added in future update
    echo "⏭️  GitHub MCP not yet configured (Docker-based installation required)"
else
    echo "⏭️  Skipping GitHub MCP (no token found)"
fi

# Configure Flutter MCP if Flutter is available
if command -v flutter &> /dev/null; then
    echo "📱 Configuring Flutter MCP service..."
    # Note: Flutter MCP server package name needs verification
    echo "⏭️  Flutter MCP not yet configured (needs package verification)"
else
    echo "⏭️  Skipping Flutter MCP (Flutter not installed)"
fi

echo "✅ MCP service configuration complete!"
echo "📋 Configured services:"
claude mcp list 2>/dev/null || echo "   (Unable to list services)"