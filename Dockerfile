# Use Playwright base image
FROM mcr.microsoft.com/playwright:v1.56.1

# Set working directory
WORKDIR /workspace

# Copy local repo into container
COPY . .

# Install Node dependencies quietly
RUN npm install --quiet

# Install Playwright browsers + required dependencies
RUN npx playwright install --with-deps

# Install zip and dos2unix for Linux compatibility
RUN apt-get update && \
    apt-get install -y zip dos2unix && \
    rm -rf /var/lib/apt/lists/*

# Convert all scripts to Unix line endings to avoid SyntaxError
RUN find . -type f -name "*.sh" -exec dos2unix {} \; && \
    find . -type f -name "*.js" -exec dos2unix {} \;

# Make test script executable
RUN chmod +x run_tests.sh

# Default command to run tests
CMD ["./run_tests.sh"]


