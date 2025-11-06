#!/bin/bash
set -e

cd /workspace

echo "▶️ Running Playwright tests..."

# Run Playwright tests and generate HTML report
npx playwright test ./tests --reporter=html
STATUS=$?

# Create zipped report
zip -r playwright-report.zip ./playwright-report

# Send result via email
echo -e "Playwright Tests Completed. Status: $STATUS" \
  | mutt -s "Playwright Test Result" -a playwright-report.zip -- gopalakrishnan93843@gmail.com

exit $STATUS
