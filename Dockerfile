# Base image with Playwright + Node
FROM mcr.microsoft.com/playwright:v1.56.1-jammy

WORKDIR /workspace

# Only copy package files (optional)
COPY package*.json ./

# Install dependencies (cached layer)
RUN npm ci --quiet || npm install --legacy-peer-deps --quiet

# Install Playwright browsers + OS deps
RUN npx playwright install --with-deps

# Install system deps (jq added)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends unzip curl xvfb dos2unix jq && \
    curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/ /var/lib/apt/lists/*

# Ensure workspace exists
RUN mkdir -p /workspace

# Default ENV
ENV TEST_SUITE=all \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# ❗ REMOVE CMD COMPLETELY
# Container should not auto-run anything

