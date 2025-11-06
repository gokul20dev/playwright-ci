#!/bin/bash
set -e

cd /workspace

# Run Playwright tests and generate HTML report
npx playwright test ./tests --reporter=html
STATUS=$?

# Prepare report
REPORT_DIR="./playwright-report"
REPORT_FILE="$REPORT_DIR/index.html"
zip -r playwright-report.zip $REPORT_DIR

# Send email with report attached
echo -e "Hi,\n\nPlaywright tests completed.\nExit code: $STATUS\nPlease find the HTML report attached.\n\nRegards,\nCI/CD Pipeline" \
    | mutt -s "Playwright Test Result" -a playwright-report.zip -- gopalakrishnan93843@gmail.com

# Exit with test status
exit $STATUS
 
