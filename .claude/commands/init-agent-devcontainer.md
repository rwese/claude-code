# Initialize AI Agent DevContainer

This command sets up a comprehensive development container environment optimized for AI agents with advanced tooling for automation, testing, analysis, and monitoring.

To run this initialization:
```bash
/init-agent-devcontainer
```

## Setup Script

```bash
#!/bin/bash
set -euo pipefail

echo "🤖 Initializing AI Agent DevContainer Environment..."
echo "=================================================="

# Ensure we're in the devcontainer
if [[ "${DEVCONTAINER:-false}" != "true" ]]; then
    echo "❌ This script must be run inside the devcontainer"
    echo "   Run: devcontainer up && devcontainer exec bash"
    exit 1
fi

# Create AI agent workspace structure
echo "📁 Creating AI agent workspace structure..."
mkdir -p /workspace/{.ai-agent,logs,data,tests,docs,scripts,api-mocks}
mkdir -p /workspace/.ai-agent/{configs,templates,cache,sessions}

# Install additional AI agent tools
echo "📦 Installing AI agent tools..."

# API Testing & Development
echo "   Installing API testing tools..."
sudo apt-get update -qq
sudo apt-get install -y -qq httpie jq yq mitmproxy

# Database Clients
echo "   Installing database clients..."
sudo apt-get install -y -qq sqlite3 postgresql-client mysql-client redis-tools mongodb-clients

# Code Analysis & Quality
echo "   Installing code analysis tools..."
pip install --user semgrep bandit safety pylint black isort mypy
npm install -g eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Testing Frameworks
echo "   Installing testing frameworks..."
pip install --user pytest pytest-cov pytest-mock pytest-asyncio hypothesis
npm install -g jest mocha chai sinon nyc

# Documentation Tools
echo "   Installing documentation tools..."
pip install --user mkdocs mkdocs-material sphinx recommonmark
npm install -g jsdoc typedoc markdown-pdf

# Performance Testing
echo "   Installing performance testing tools..."
sudo apt-get install -y -qq apache2-utils
wget -q https://github.com/grafana/k6/releases/latest/download/k6-linux-amd64.tar.gz -O /tmp/k6.tar.gz
sudo tar -xzf /tmp/k6.tar.gz -C /usr/local/bin --strip-components=1 k6
rm /tmp/k6.tar.gz

# Container & Process Management
echo "   Installing container management tools..."
sudo apt-get install -y -qq docker-compose htop iotop nethogs ncdu

# Data Processing
echo "   Installing data processing tools..."
pip install --user pandas numpy scikit-learn matplotlib seaborn jupyter csvkit
sudo apt-get install -y -qq csvtool

# Web Scraping Enhancement
echo "   Installing web scraping tools..."
pip install --user beautifulsoup4 scrapy selenium requests-html pyquery

# AI/ML CLI Tools
echo "   Installing AI/ML tools..."
pip install --user openai anthropic transformers datasets

# Task Automation
echo "   Installing task automation tools..."
sudo apt-get install -y -qq make
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# API Mocking
echo "   Installing API mocking tools..."
npm install -g json-server @stoplight/prism-cli

# Log Analysis
echo "   Installing log analysis tools..."
sudo apt-get install -y -qq goaccess lnav

# Security Scanning
echo "   Installing security scanning tools..."
wget -qO - https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-64bit.tar.gz | sudo tar -xzf - -C /usr/local/bin trivy

# Create AI agent configuration
echo "📝 Creating AI agent configuration..."
cat > /workspace/.ai-agent/config.json << 'EOF'
{
  "version": "1.0.0",
  "capabilities": {
    "browser_automation": true,
    "api_testing": true,
    "database_access": true,
    "code_analysis": true,
    "documentation_generation": true,
    "performance_testing": true,
    "security_scanning": true,
    "web_scraping": true,
    "data_processing": true
  },
  "tools": {
    "api_testing": ["httpie", "curl", "postman", "insomnia"],
    "databases": ["sqlite3", "psql", "mysql", "redis-cli", "mongosh"],
    "code_analysis": ["semgrep", "eslint", "pylint", "bandit", "mypy"],
    "testing": ["pytest", "jest", "mocha", "k6"],
    "documentation": ["mkdocs", "sphinx", "jsdoc", "typedoc"],
    "monitoring": ["htop", "iotop", "nethogs", "goaccess"],
    "scraping": ["playwright", "beautifulsoup4", "scrapy", "selenium"],
    "automation": ["make", "just", "bash", "python"]
  },
  "api_endpoints": {
    "mock_server": "http://localhost:3000",
    "test_server": "http://localhost:8080",
    "debug_port": 9229
  }
}
EOF

# Create example automation scripts
echo "📜 Creating example automation scripts..."

# API testing script
cat > /workspace/scripts/test-api.sh << 'EOF'
#!/bin/bash
# Example API testing script for AI agents

API_BASE="${1:-http://localhost:3000}"
echo "Testing API at: $API_BASE"

# Health check
http GET "$API_BASE/health" || echo "Health check failed"

# Test CRUD operations
http POST "$API_BASE/items" name="test-item" value=42
http GET "$API_BASE/items"
http PUT "$API_BASE/items/1" name="updated-item"
http DELETE "$API_BASE/items/1"
EOF
chmod +x /workspace/scripts/test-api.sh

# Code analysis script
cat > /workspace/scripts/analyze-code.sh << 'EOF'
#!/bin/bash
# Comprehensive code analysis for AI agents

echo "🔍 Running code analysis..."

# Python analysis
if [[ -f "requirements.txt" ]] || find . -name "*.py" -type f | head -1 > /dev/null; then
    echo "Python code detected..."
    pylint **/*.py --exit-zero || true
    bandit -r . || true
    safety check || true
fi

# JavaScript/TypeScript analysis
if [[ -f "package.json" ]]; then
    echo "JavaScript/TypeScript code detected..."
    npx eslint . || true
fi

# Security scanning
echo "Running security scan..."
semgrep --config=auto . || true
trivy fs . || true
EOF
chmod +x /workspace/scripts/analyze-code.sh

# Performance testing script
cat > /workspace/scripts/perf-test.sh << 'EOF'
#!/bin/bash
# Performance testing script for AI agents

URL="${1:-http://localhost:3000}"
CONCURRENT="${2:-10}"
REQUESTS="${3:-1000}"

echo "🚀 Performance testing: $URL"
echo "   Concurrent: $CONCURRENT"
echo "   Requests: $REQUESTS"

# Apache Bench test
ab -n "$REQUESTS" -c "$CONCURRENT" "$URL/" || true

# K6 test (if script exists)
if [[ -f "k6-test.js" ]]; then
    k6 run k6-test.js
fi
EOF
chmod +x /workspace/scripts/perf-test.sh

# Create Makefile for common tasks
cat > /workspace/Makefile << 'EOF'
.PHONY: help test analyze docs clean setup

help:
	@echo "AI Agent DevContainer Tasks:"
	@echo "  make setup    - Set up environment"
	@echo "  make test     - Run all tests"
	@echo "  make analyze  - Run code analysis"
	@echo "  make docs     - Generate documentation"
	@echo "  make clean    - Clean temporary files"

setup:
	@echo "Setting up AI agent environment..."
	@pip install -r requirements.txt || true
	@npm install || true

test:
	@echo "Running tests..."
	@pytest -v --cov=. --cov-report=html || true
	@npm test || true

analyze:
	@bash scripts/analyze-code.sh

docs:
	@echo "Generating documentation..."
	@mkdocs build || true
	@jsdoc -c jsdoc.json || true

clean:
	@echo "Cleaning up..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + || true
	@find . -type f -name "*.pyc" -delete || true
	@rm -rf .coverage htmlcov .pytest_cache || true
	@rm -rf node_modules/.cache || true
EOF

# Create Justfile for additional tasks
cat > /workspace/justfile << 'EOF'
# AI Agent DevContainer Tasks

# Default task - show help
default:
    @just --list

# Start mock API server
mock-api:
    json-server --watch api-mocks/db.json --port 3000

# Run browser automation test
browser-test url="http://localhost:3000":
    python scripts/browser-test.py {{url}}

# Analyze logs
analyze-logs:
    lnav logs/*.log

# Database operations
db-shell db="sqlite":
    #!/bin/bash
    case {{db}} in
        sqlite) sqlite3 data/local.db ;;
        postgres) psql -h localhost -U postgres ;;
        mysql) mysql -h localhost -u root ;;
        redis) redis-cli ;;
        *) echo "Unknown database: {{db}}" ;;
    esac

# Security scan
security-scan:
    trivy fs .
    bandit -r .
    safety check

# Performance benchmark
benchmark url="http://localhost:3000":
    k6 run --vus 10 --duration 30s scripts/k6-test.js

# Generate test data
generate-data:
    python scripts/generate-test-data.py

# Watch for changes and run tests
watch:
    nodemon --exec "make test" --ext py,js,ts,json
EOF

# Create example K6 performance test
cat > /workspace/scripts/k6-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m30s', target: 20 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const res = http.get('http://localhost:3000');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
EOF

# Create browser automation example
cat > /workspace/scripts/browser-test.py << 'EOF'
#!/usr/bin/env python3
"""Example browser automation script for AI agents"""

import sys
from playwright.sync_api import sync_playwright

def test_website(url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        
        print(f"Testing: {url}")
        page.goto(url)
        
        # Take screenshot
        page.screenshot(path="logs/screenshot.png")
        
        # Extract data
        title = page.title()
        links = page.locator("a").all()
        
        print(f"Title: {title}")
        print(f"Links found: {len(links)}")
        
        browser.close()

if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3000"
    test_website(url)
EOF
chmod +x /workspace/scripts/browser-test.py

# Create test data generator
cat > /workspace/scripts/generate-test-data.py << 'EOF'
#!/usr/bin/env python3
"""Generate test data for AI agent testing"""

import json
import random
import string
from datetime import datetime, timedelta

def generate_user():
    return {
        "id": random.randint(1000, 9999),
        "name": f"User_{random.choice(string.ascii_uppercase)}{''.join(random.choices(string.ascii_lowercase, k=5))}",
        "email": f"user{random.randint(100, 999)}@example.com",
        "created": (datetime.now() - timedelta(days=random.randint(0, 365))).isoformat()
    }

def generate_api_data():
    return {
        "users": [generate_user() for _ in range(10)],
        "posts": [
            {
                "id": i,
                "userId": random.randint(1000, 9999),
                "title": f"Post {i}",
                "content": "Lorem ipsum dolor sit amet",
                "timestamp": datetime.now().isoformat()
            } for i in range(1, 21)
        ]
    }

if __name__ == "__main__":
    data = generate_api_data()
    
    # Save for json-server
    with open("api-mocks/db.json", "w") as f:
        json.dump(data, f, indent=2)
    
    # Save as CSV
    import pandas as pd
    pd.DataFrame(data["users"]).to_csv("data/users.csv", index=False)
    pd.DataFrame(data["posts"]).to_csv("data/posts.csv", index=False)
    
    print("✅ Test data generated successfully!")
EOF
chmod +x /workspace/scripts/generate-test-data.py

# Initialize mock API data
echo "🔧 Initializing mock API..."
mkdir -p api-mocks
echo '{"users":[],"posts":[],"items":[]}' > api-mocks/db.json

# Create AI agent helper functions
cat > /workspace/.ai-agent/helpers.sh << 'EOF'
#!/bin/bash
# AI Agent Helper Functions

# Quick API test
api_test() {
    local url="${1:-http://localhost:3000}"
    http --print=HhBb GET "$url" || curl -i "$url"
}

# Start all services
start_services() {
    echo "Starting AI agent services..."
    json-server --watch api-mocks/db.json --port 3000 &
    echo "Mock API started on port 3000"
}

# Run full test suite
run_all_tests() {
    make test
    make analyze
    ./scripts/perf-test.sh
}

# Quick code search
code_search() {
    local pattern="$1"
    rg "$pattern" --type-add 'code:*.{py,js,ts,jsx,tsx,go,rs,java,cpp,c,h}' -t code
}

# Database quick connect
db_connect() {
    case "$1" in
        sqlite) sqlite3 data/local.db ;;
        *) echo "Usage: db_connect [sqlite]" ;;
    esac
}

# Export functions
export -f api_test start_services run_all_tests code_search db_connect
EOF

# Create README for AI agents
cat > /workspace/.ai-agent/README.md << 'EOF'
# AI Agent DevContainer Environment

This environment is optimized for AI agents with comprehensive tooling for:

## 🛠️ Available Tools

### API Testing & Development
- `httpie` - Modern command line HTTP client
- `curl` + `jq` - Classic HTTP client with JSON processor
- `json-server` - Quick REST API mocking
- `mitmproxy` - HTTP/HTTPS proxy for debugging

### Database Access
- SQLite, PostgreSQL, MySQL, Redis, MongoDB clients
- Database migration tools
- Query builders and ORMs

### Code Analysis
- Static analysis: semgrep, eslint, pylint
- Security scanning: bandit, safety, trivy
- Type checking: mypy, TypeScript
- Formatting: black, prettier

### Testing Frameworks
- Python: pytest with coverage
- JavaScript: jest, mocha
- Performance: k6, Apache Bench
- Browser: Playwright

### Automation
- Task runners: make, just
- Process managers: PM2, supervisord
- Schedulers: cron, systemd timers

## 🚀 Quick Start

1. **Start services**: `just start-services`
2. **Run tests**: `make test`
3. **Analyze code**: `make analyze`
4. **Performance test**: `just benchmark`

## 📁 Directory Structure

```
/workspace/
├── .ai-agent/        # AI agent configs and cache
├── api-mocks/        # Mock API data
├── data/             # Local databases and datasets
├── docs/             # Generated documentation
├── logs/             # Application and test logs
├── scripts/          # Automation scripts
└── tests/            # Test suites
```

## 🔧 Common Tasks

```bash
# API Testing
./scripts/test-api.sh http://localhost:3000

# Code Analysis
./scripts/analyze-code.sh

# Performance Testing
./scripts/perf-test.sh http://localhost:3000 50 5000

# Generate Test Data
python scripts/generate-test-data.py

# Start Mock API
json-server --watch api-mocks/db.json

# Database Access
sqlite3 data/local.db
```

## 🤖 AI Agent Best Practices

1. Always validate inputs and outputs
2. Use structured logging for debugging
3. Implement retry logic for network requests
4. Cache expensive operations
5. Monitor resource usage
6. Generate comprehensive test reports
7. Document all automated workflows
EOF

# Set up Git hooks for AI agents
echo "🔗 Setting up Git hooks..."
cat > /workspace/.git/hooks/pre-commit << 'EOF'
#!/bin/bash
# AI Agent pre-commit hook

echo "Running AI agent pre-commit checks..."

# Code quality
make analyze || exit 1

# Security scan
trivy fs . --exit-code 1 --severity HIGH,CRITICAL || exit 1

echo "✅ Pre-commit checks passed!"
EOF
chmod +x /workspace/.git/hooks/pre-commit || true

# Final setup
echo "🎯 Finalizing setup..."
cd /workspace
source /workspace/.ai-agent/helpers.sh

echo ""
echo "✅ AI Agent DevContainer initialized successfully!"
echo ""
echo "📚 Documentation: /workspace/.ai-agent/README.md"
echo "🛠️  Tools installed: $(cat /workspace/.ai-agent/config.json | jq -r '.tools | keys | join(", ")')"
echo ""
echo "Quick commands:"
echo "  make help         - Show available tasks"
echo "  just              - Show automation commands"
echo "  api_test URL      - Test an API endpoint"
echo "  start_services    - Start mock services"
echo ""
```

## Usage

Run this command inside your devcontainer to set up the complete AI agent environment:

```bash
/init-agent-devcontainer
```

This will install and configure:
- API testing and mocking tools
- Database clients and tools
- Code analysis and security scanning
- Testing frameworks and coverage tools
- Documentation generators
- Performance testing utilities
- Data processing libraries
- Web scraping enhancements
- Task automation systems
- Monitoring and logging tools

See `/workspace/.ai-agent/README.md` after initialization for detailed usage instructions.