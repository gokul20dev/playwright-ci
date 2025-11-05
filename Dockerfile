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
