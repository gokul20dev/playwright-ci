#!/bin/bash
set -e

# Navigate to workspace
cd /workspace

# Run Playwright tests and generate HTML report
npx playwright test ./tests --reporter=html
STATUS=$?

# Report directory
REPORT_DIR="./playwright-report"
REPORT_FILE="$REPORT_DIR/index.html"

# Optional: zip report to attach
zip -r playwright-report.zip $REPORT_DIR

# Send email with report attached (requires mutt/mailx inside image)
echo -e "Hi,\n\nPlaywright tests completed.\nExit code: $STATUS\nPlease find the HTML report attached.\n\nRegards,\nCI/CD Pipeline" \
    | mutt -s "Playwright Test Result" -a playwright-report.zip -- gopalakrishnan93843@gmail.com

# Self-remove container
CONTAINER_ID=$(hostname)
docker rm -f $CONTAINER_ID || true
