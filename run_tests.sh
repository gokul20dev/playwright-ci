#!/bin/bash
set -e

# Navigate to workspace
cd /workspace

# Run Playwright tests and generate HTML report
npx playwright test ./tests --reporter=html
STATUS=$?


