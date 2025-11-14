# ✅ Base image with Node.js + Playwright dependencies
FROM mcr.microsoft.com/playwright:v1.56.1-jammy

# Set working directory inside the container
WORKDIR /workspace

# Copy package files first (for layer caching)
COPY package*.json ./

# ✅ Install dependencies (cached layer)
RUN npm ci --quiet || npm install --legacy-peer-deps --quiet

# Copy the remaining project files
COPY . .

# ✅ Install Playwright browsers + dependencies
# --with-deps installs Chromium/Firefox/WebKit + OS deps
RUN npx playwright install --with-deps

# ✅ Install essential system utilities only (fast!)
# Replaces slow pip AWS CLI with official AWS CLI v2 binary
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends unzip curl xvfb dos2unix && \
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws/ /var/lib/apt/lists/*

# ✅ Convert Windows line endings to Unix (fast batch)
RUN find . -type f \( -name "*.sh" -o -name "*.js" \) -exec dos2unix {} +

# ✅ Make main script executable
RUN chmod +x run_tests.sh

# ✅ Set default environment variables (can be overridden by Jenkins)
ENV TEST_SUITE=all \
    AWS_REGION=ap-south-1 \
    S3_BUCKET=playwright-test-reports-gokul \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# ✅ Run the test runner and stream logs to stdout (for Jenkins)
CMD ["bash", "-c", "./run_tests.sh | tee /proc/1/fd/1"]

