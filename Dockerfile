# ---------- COPY PACKAGE FILES (cache) ----------
COPY package*.json ./

# ---------- Install NPM dependencies ----------
RUN npm ci --quiet || npm install --legacy-peer-deps --quiet

# ---------- Copy rest of application ----------
COPY . .

# --- FIX: Make Playwright use TS config correctly ----
RUN echo "module.exports = require('./playwright.config.ts').default;" > playwright.config.js

# ---------- Install ALL system + Playwright deps correctly ----------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        xvfb \
        xauth \
        x11-apps \
        libxrandr2 \
        libasound2 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libnss3 \
        libxss1 \
        libxshmfence1 \
        libsmbclient \
        unzip \
        curl \
        jq \
        dos2unix \
    && apt-get clean

# ---------- Install Playwright browsers WITH system deps ----------
RUN npx playwright install --with-deps

# ---------- Install AWS CLI ----------
RUN curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/

# ---------- Convert CRLF to LF ----------
RUN find . -type f \( -name "*.sh" -o -name "*.js" -o -name "*.ts" \) -exec dos2unix {} + || true

# ---------- Ensure run_tests.sh is executable ----------
RUN chmod +x /workspace/run_tests.sh || true

# ---------- Keep container alive ----------
ENTRYPOINT ["tail", "-f", "/dev/null"]
