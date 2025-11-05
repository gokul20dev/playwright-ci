FROM mcr.microsoft.com/playwright:v1.44.0

WORKDIR /workspace

# Copy project files
COPY package*.json ./
RUN npm ci
RUN npx playwright install --with-deps

# Install mail client for sending emails
RUN apt-get update && apt-get install -y mutt zip

# Copy run_tests.sh
COPY run_tests.sh /workspace/run_tests.sh
RUN chmod +x /workspace/run_tests.sh

# Default command (can be overridden in docker run)
CMD ["/workspace/run_tests.sh"]
