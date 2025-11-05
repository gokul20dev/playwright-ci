# Use official Playwright image
FROM mcr.microsoft.com/playwright:v1.44.0

WORKDIR /workspace

# Copy project dependencies and tests
COPY package*.json ./
COPY tests/ ./tests/
RUN npm ci
RUN npx playwright install --with-deps

# Install mail client for sending emails
RUN apt-get update && apt-get install -y mutt zip

# Copy the test runner script
COPY run_tests.sh /workspace/run_tests.sh
RUN chmod +x /workspace/run_tests.sh

# Default command: run the tests
CMD ["/workspace/run_tests.sh"]
