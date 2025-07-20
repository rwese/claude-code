#!/bin/bash
# Test script for AI agent devcontainer setup

set -euo pipefail

echo "🧪 Testing AI Agent DevContainer Setup..."
echo "========================================"

# Test 1: Check command file exists
echo "✓ Checking command file..."
if [[ -f ".claude/commands/init-agent-devcontainer.md" ]]; then
    echo "  Command file exists"
else
    echo "  ❌ Command file not found"
    exit 1
fi

# Test 2: Check documentation exists
echo "✓ Checking documentation..."
if [[ -f "AIAGENT.md" ]]; then
    echo "  Documentation exists"
else
    echo "  ❌ Documentation not found"
    exit 1
fi

# Test 3: Validate command syntax
echo "✓ Validating command syntax..."
if grep -q "#!/bin/bash" .claude/commands/init-agent-devcontainer.md; then
    echo "  Command has valid shebang"
else
    echo "  ❌ Invalid command format"
    exit 1
fi

# Test 4: Check for required tools in command
echo "✓ Checking for required tools..."
required_tools=("httpie" "jq" "pytest" "semgrep" "k6" "mkdocs")
for tool in "${required_tools[@]}"; do
    if grep -q "$tool" .claude/commands/init-agent-devcontainer.md; then
        echo "  ✓ $tool installation found"
    else
        echo "  ⚠️  $tool not found in setup"
    fi
done

# Test 5: Validate documentation structure
echo "✓ Validating documentation structure..."
required_sections=("Overview" "Quick Start" "Core Capabilities" "Common AI Agent Tasks" "Best Practices")
for section in "${required_sections[@]}"; do
    if grep -q "$section" AIAGENT.md; then
        echo "  ✓ Section '$section' found"
    else
        echo "  ⚠️  Section '$section' missing"
    fi
done

# Test 6: Check devcontainer integration
echo "✓ Checking devcontainer integration..."
if [[ -f ".devcontainer/devcontainer-manager.sh" ]]; then
    echo "  DevContainer manager available"
fi

echo ""
echo "✅ AI Agent setup validation complete!"
echo ""
echo "To initialize the AI agent environment in a devcontainer, run:"
echo "  /init-agent-devcontainer"
echo ""
echo "For more information, see AIAGENT.md"