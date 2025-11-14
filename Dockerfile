# Base image with Playwright + Node
FROM mcr.microsoft.com/playwright:v1.56.1-jammy

# ---------- WORKDIR ----------
WORKDIR /workspace

# ---------- COPY PACKAGE FILES (cache) ----------
COPY package*.json ./

# ---------- Install dependencies ----------
RUN npm ci --quiet || npm install --legacy-peer-deps --quiet

# ---------- Copy everything (initial version) ----------
COPY . .

# --- FIX: Wrapper so Playwright loads TS config correctly ----
RUN echo "module.exports = require('./playwright.config.ts').default;" > playwright.config.js

# ---------- Install Playwright browsers + OS deps ----------
RUN npx playwright install --with-deps

# ---------- Install additional system deps ----------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends unzip curl xvfb dos2unix jq && \
    curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/ /var/lib/apt/lists/*

# ---------- Fix CRLF from Windows ----------
RUN find . -type f \( -name "*.sh" -o -name "*.js" -o -name "*.ts" \) -exec dos2unix {} + || true

# ---------- Make script executable (safe default) ----------
RUN chmod +x /workspace/run_tests.sh || true

# ------------------------------------------------------------
# IMPORTANT CHANGE FOR OPTION B:
# Container MUST NOT auto-run tests.
# It must stay alive so Jenkins can:
# 1) docker create
# 2) docker cp workspace/
# 3) docker exec chmod
# 4) docker exec /workspace/run_tests.sh
#
# So we DISABLE tests in CMD.
# ------------------------------------------------------------

# Keep container alive until Jenkins starts tests
ENTRYPOINT ["tail", "-f", "/dev/null"]

