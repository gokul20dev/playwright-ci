FROM mcr.microsoft.com/playwright:v1.44.0

WORKDIR /workspace

# Install system deps + mail client
RUN apt-get update && apt-get install -y mutt zip

# Install Playwright dependencies
RUN npm init -y && npm install @playwright/test && npx playwright install --with-deps

CMD ["/workspace/run_tests.sh"]
