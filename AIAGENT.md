# AI Agent DevContainer Guide

## 🤖 Overview

This devcontainer provides a comprehensive environment for AI agents with advanced tooling for automation, testing, analysis, and system interaction. It's designed to give AI assistants like Claude, GPT-4, and other LLMs powerful capabilities while maintaining security and reliability.

## 🚀 Quick Start

```bash
# Initialize the AI agent environment
/init-agent-devcontainer

# Or if running the command directly
bash /workspace/.claude/commands/init-agent-devcontainer.md
```

## 🛠️ Core Capabilities

### 1. Browser Automation & Web Interaction

**Playwright Integration**
- Full browser automation with Chromium
- Screenshot capabilities
- Network request interception
- JavaScript execution in page context
- Multi-tab management

```bash
# Examples
sudo safe-browser-open http://localhost:3000
browser-debug http://localhost:8080
browser-session-manager list
```

**Web Scraping Tools**
- BeautifulSoup4 for HTML parsing
- Scrapy for complex crawling
- Selenium for dynamic content
- requests-html for JavaScript rendering

### 2. API Testing & Development

**HTTP Clients**
- `httpie`: Modern, user-friendly HTTP client
- `curl`: Classic tool with full protocol support
- `postman`/`insomnia`: GUI tools (via CLI)

**API Mocking**
- `json-server`: Quick REST API mocking
- `@stoplight/prism-cli`: OpenAPI-based mocking
- Custom mock endpoints

```bash
# Start mock API
json-server --watch api-mocks/db.json --port 3000

# Test endpoints
http GET localhost:3000/users
http POST localhost:3000/items name="test" value=42
```

### 3. Database Operations

**Supported Databases**
- SQLite (local file-based)
- PostgreSQL (client)
- MySQL/MariaDB (client)
- Redis (client + CLI)
- MongoDB (client)

```bash
# Quick database access
sqlite3 data/local.db
psql -h localhost -U postgres
mysql -h localhost -u root -p
redis-cli
mongosh
```

### 4. Code Analysis & Security

**Static Analysis**
- `semgrep`: Multi-language static analysis
- `eslint`: JavaScript/TypeScript linting
- `pylint`: Python code analysis
- `mypy`: Python type checking

**Security Scanning**
- `bandit`: Python security linter
- `safety`: Python dependency checker
- `trivy`: Container and filesystem scanner
- `snyk`: Vulnerability database (optional)

```bash
# Run comprehensive analysis
make analyze

# Security scan
trivy fs .
bandit -r .
safety check
```

### 5. Testing Frameworks

**Unit Testing**
- Python: `pytest` with plugins
- JavaScript: `jest`, `mocha`
- Coverage reporting included

**Performance Testing**
- `k6`: Modern load testing tool
- `ab` (Apache Bench): Simple benchmarking
- `wrk`: High-performance HTTP benchmarking

```bash
# Run tests
pytest -v --cov=.
npm test

# Performance test
k6 run scripts/k6-test.js
ab -n 1000 -c 10 http://localhost:3000/
```

### 6. Development Tools

**Version Control**
- Git with GitHub CLI (`gh`)
- Pre-commit hooks
- Automated workflows

**Documentation**
- `mkdocs`: Python documentation
- `sphinx`: Advanced documentation
- `jsdoc`/`typedoc`: JavaScript docs
- Markdown processors

**Task Automation**
- `make`: Classic build automation
- `just`: Modern command runner
- Shell scripts
- Python automation

### 7. Monitoring & Debugging

**System Monitoring**
- `htop`: Process monitoring
- `iotop`: I/O monitoring
- `nethogs`: Network monitoring
- `ncdu`: Disk usage analyzer

**Log Analysis**
- `lnav`: Advanced log file navigator
- `goaccess`: Real-time web log analyzer
- Structured logging support

**Debug Tools**
- Chrome DevTools integration
- SSH tunnel management
- Port forwarding utilities
- Session management

### 8. Data Processing

**Data Libraries**
- `pandas`: Data manipulation
- `numpy`: Numerical computing
- `matplotlib`/`seaborn`: Visualization
- `jupyter`: Interactive notebooks
- `csvkit`: CSV utilities

**File Processing**
- JSON/YAML/XML processors
- Text manipulation tools
- Binary file analysis

### 9. AI/ML Integration

**AI SDKs**
- OpenAI Python SDK
- Anthropic Python SDK
- Transformers library
- Datasets library

**Model Interaction**
```python
# Example AI integration
from openai import OpenAI
from anthropic import Anthropic

# Use for AI-powered analysis
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Analyze this code"}]
)
```

### 10. Security Features

**Access Control**
- Sandboxed browser execution
- Rate limiting on operations
- Secure credential management
- Audit logging

**Network Security**
- Firewall rules via iptables
- Proxy configuration support
- HTTPS certificate validation
- Domain allowlisting

## 📁 Directory Structure

```
/workspace/
├── .ai-agent/
│   ├── config.json      # Agent configuration
│   ├── helpers.sh       # Helper functions
│   ├── cache/           # Operation cache
│   ├── sessions/        # Active sessions
│   └── templates/       # Code templates
├── .devcontainer/
│   ├── browser-*.sh     # Browser automation
│   ├── security-*.sh    # Security tools
│   └── devcontainer.json
├── api-mocks/           # Mock API data
├── data/                # Databases & datasets
├── docs/                # Generated docs
├── logs/                # Application logs
├── scripts/             # Automation scripts
└── tests/               # Test suites
```

## 🔧 Common AI Agent Tasks

### 1. Web Application Testing
```bash
# Start local server
python -m http.server 8000

# Open in browser
sudo safe-browser-open http://localhost:8000

# Take screenshot
browser-session-manager screenshot

# Run automated tests
python scripts/browser-test.py http://localhost:8000
```

### 2. API Development & Testing
```bash
# Create mock API
echo '{"users": [], "posts": []}' > api-mocks/db.json
json-server --watch api-mocks/db.json

# Test CRUD operations
./scripts/test-api.sh http://localhost:3000

# Performance test
k6 run --vus 50 --duration 30s scripts/k6-test.js
```

### 3. Code Analysis Pipeline
```bash
# Full code analysis
make analyze

# Security audit
just security-scan

# Generate report
semgrep --config=auto --json -o reports/semgrep.json .
```

### 4. Data Processing
```python
# Load and analyze data
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('data/metrics.csv')
df.describe()
df.plot(kind='line', x='date', y='value')
plt.savefig('docs/metrics-plot.png')
```

### 5. Automated Documentation
```bash
# Generate API docs
mkdocs build

# Create code documentation
jsdoc -c jsdoc.json -d docs/api

# Convert to PDF
markdown-pdf README.md -o docs/readme.pdf
```

## 🎯 Best Practices for AI Agents

### 1. Error Handling
Always implement robust error handling:
```python
try:
    result = perform_operation()
except Exception as e:
    log_error(f"Operation failed: {e}")
    return fallback_result()
```

### 2. Resource Management
Monitor and limit resource usage:
```bash
# Check resource usage
htop
df -h
free -m

# Limit process resources
ulimit -m 1000000  # 1GB memory limit
```

### 3. Logging & Debugging
Use structured logging:
```python
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('logs/agent.log'),
        logging.StreamHandler()
    ]
)
```

### 4. Security Considerations
- Always validate URLs before browsing
- Use secure credential storage
- Implement rate limiting
- Audit all operations

### 5. Testing Strategy
- Write unit tests for all functions
- Implement integration tests
- Use property-based testing
- Performance benchmarking

## 🚨 Limitations & Warnings

1. **Browser Automation**: Requires proper permissions and may be blocked by some sites
2. **Network Access**: Subject to firewall rules and rate limits
3. **Resource Limits**: Container has memory and CPU constraints
4. **Security**: Some operations require elevated privileges
5. **Persistence**: Container state may be reset

## 🆘 Troubleshooting

### Common Issues

**Browser won't open**
```bash
# Check permissions
ls -la /usr/local/bin/safe-browser-open

# Test security validation
bash /usr/local/bin/security-validation.sh "http://localhost:3000"
```

**Database connection failed**
```bash
# Check if service is running
docker ps | grep postgres

# Test connection
pg_isready -h localhost -p 5432
```

**Permission denied errors**
```bash
# Check file ownership
ls -la /tmp/

# Fix permissions
sudo chown -R node:node /workspace
```

### Debug Commands
```bash
# Check system status
cy-status

# View logs
cy-logs

# Clean up resources
cy-cleanup-all

# Restart services
cy restart
```

## 📚 Additional Resources

- [Playwright Documentation](https://playwright.dev/)
- [HTTPie Documentation](https://httpie.io/docs)
- [K6 Performance Testing](https://k6.io/docs/)
- [Semgrep Rules](https://semgrep.dev/r)
- [Docker DevContainer Spec](https://containers.dev/)

## 🤝 Contributing

To enhance the AI agent environment:

1. Add new tools to the Dockerfile
2. Update init-agent-devcontainer.md
3. Document in this guide
4. Add examples and test cases
5. Submit PR with clear description

---

**Note**: This environment is designed for development and testing. Production deployments require additional security hardening and resource optimization.