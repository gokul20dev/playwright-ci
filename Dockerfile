<<<<<<< HEAD
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

=======
# Base image with Playwright pre-installed
FROM mcr.microsoft.com/playwright:v1.44.0-jammy

# Set working directory
WORKDIR /workspace

# Copy all files from your project into the container
COPY . .

# Install dependencies and mail utilities
RUN apt-get update && \
    apt-get install -y mailutils postfix && \
    npm install && \
    npx playwright install --with-deps

# Copy the test script that sends email
COPY test-exec.sh /usr/local/bin/test-exec.sh
RUN chmod +x /usr/local/bin/test-exec.sh

# Run the script when container starts
CMD ["test-exec.sh"]
>>>>>>> 4aec46e885b61bcaaeca79ed0a121b4f77a196d4
