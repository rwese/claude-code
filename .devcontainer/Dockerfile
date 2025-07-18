FROM node:20

ARG TZ
ENV TZ="$TZ"

# Install basic development tools, iptables/ipset, and Puppeteer dependencies
RUN apt update && apt install -y less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  curl \
  fonts-liberation \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgbm1 \
  libgcc1 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  lsb-release \
  wget \
  xdg-utils \
  chromium \
  squid

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
  rm "git-delta_0.18.2_${ARCH}.deb"

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Default powerline10k theme
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install uv for Python package management (required for git MCP service)
ENV HOME="/home/node/"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && . $HOME/.local/bin/env
ENV PATH="/home/node/.cargo/bin:$PATH"
ENV PATH="$HOME/.local/bin:$PATH"

RUN PATH="/home/node/.local/bin:$PATH" uvx mcp-server-git --help 1>/dev/null

# Set Puppeteer to use system Chrome instead of downloading
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy and set up Squid proxy configuration
COPY squid.conf /etc/squid/squid.conf
USER root
RUN mkdir -p /var/log/squid /var/spool/squid /etc/squid/errors/custom && \
  chown -R proxy:proxy /var/log/squid /var/spool/squid && \
  chmod 755 /var/log/squid /var/spool/squid && \
  echo "denied" > /etc/squid/errors/custom/ERR_ACCESS_DENIED && \
  chown proxy:proxy /etc/squid/errors/custom/ERR_ACCESS_DENIED

# Copy and set up firewall scripts and MCP initialization
COPY init-firewall.sh /usr/local/bin/
COPY init-firewall-proxy.sh /usr/local/bin/
COPY setup-proxy-env.sh /usr/local/bin/
COPY init-mcp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/init-firewall-proxy.sh && \
  chmod +x /usr/local/bin/setup-proxy-env.sh && \
  chmod +x /usr/local/bin/init-mcp.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall-proxy.sh" >> /etc/sudoers.d/node-firewall && \
  echo "node ALL=(root) NOPASSWD: /usr/sbin/squid" > /etc/sudoers.d/node-squid && \
  echo "node ALL=(root) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/dpkg" > /etc/sudoers.d/node-packages && \
  chmod 0440 /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-squid && \
  chmod 0440 /etc/sudoers.d/node-packages

# Install Claude
RUN npm install -g @anthropic-ai/claude-code
RUN chown -R node /home/node

USER root

# Fix permissions for npm global directory
RUN chown -R node:node /usr/local/share/npm-global

USER node

# Install MCP server packages (without configuring them yet)
RUN npm install -g @playwright/mcp@latest @upstash/context7-mcp server-perplexity-ask 

