# Install Node dependencies quietly
RUN npm install --quiet

# Install Playwright browsers + required dependencies
RUN npx playwright install --with-deps

# Install zip and dos2unix for Linux compatibility
RUN apt-get update && \
    apt-get install -y zip dos2unix && \
    rm -rf /var/lib/apt/lists/*

# Convert all scripts to Unix line endings
RUN find . -type f -name "*.sh" -exec dos2unix {} \; && \
    find . -type f -name "*.js" -exec dos2unix {} \;

# Make test script executable
RUN chmod +x run_tests.sh

# Environment variable for Jenkins parameter
ENV TEST_SUITE=all

# Default command to run tests
CMD ["./run_tests.sh"]
