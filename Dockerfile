# Use prebuilt Playwright image with browsers
FROM mcr.microsoft.com/playwright:v1.56.1

# Set working directory
WORKDIR /workspace

# Copy package.json and install Node dependencies
COPY package*.json ./
RUN npm install --quiet

# Copy project files
COPY . .

# Make test script executable
RUN chmod +x run_tests.sh

# Default command
CMD ["./run_tests.sh"]


