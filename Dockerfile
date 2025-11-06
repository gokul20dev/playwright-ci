FROM mcr.microsoft.com/playwright:v1.56.1

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y zip

# Copy package.json and install Node dependencies
COPY package*.json ./
RUN npm install --quiet
RUN npx playwright install --with-deps

# Copy project files
COPY . .

# Make test script executable
RUN chmod +x run_tests.sh

# Default command
CMD ["./run_tests.sh"]

