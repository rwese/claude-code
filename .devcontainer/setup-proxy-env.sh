#!/bin/bash
# Setup proxy environment variables for the container

cat >> /home/node/.bashrc << 'EOF'

# Proxy configuration
export HTTP_PROXY=http://localhost:3128
export HTTPS_PROXY=http://localhost:3128
export http_proxy=http://localhost:3128
export https_proxy=http://localhost:3128
export no_proxy=localhost,127.0.0.1,::1

# Configure Puppeteer with proxy
export PUPPETEER_LAUNCH_OPTIONS='{"headless":true,"args":["--disable-dev-shm-usage","--disable-gpu","--proxy-server=http://localhost:3128"]}'

# Configure git to use proxy
git config --global http.proxy http://localhost:3128
git config --global https.proxy http://localhost:3128

EOF

cat >> /home/node/.zshrc << 'EOF'

# Proxy configuration
export HTTP_PROXY=http://localhost:3128
export HTTPS_PROXY=http://localhost:3128
export http_proxy=http://localhost:3128
export https_proxy=http://localhost:3128
export no_proxy=localhost,127.0.0.1,::1

# Configure Puppeteer with proxy
export PUPPETEER_LAUNCH_OPTIONS='{"headless":true,"args":["--disable-dev-shm-usage","--disable-gpu","--proxy-server=http://localhost:3128"]}'

# Configure git to use proxy
git config --global http.proxy http://localhost:3128
git config --global https.proxy http://localhost:3128

EOF

# Configure npm to use proxy
npm config set proxy http://localhost:3128
npm config set https-proxy http://localhost:3128

echo "Proxy environment configured"