#!/bin/bash
set -e

cd /workspace

# Run Playwright tests with HTML report
npx playwright test tests --reporter=html
STATUS=$?

# Zip the report
zip -r playwright-report.zip playwright-report

# Send email
echo -e "Hi,\n\nPlaywright tests completed.\nExit code: $STATUS\nPlease find the HTML report attached.\n\nRegards,\nCI/CD Pipeline" \
    | mutt -s "Playwright Test Result" -a playwright-report.zip -- gopalakrishnan93843@gmail.com

# Exit with test status
exit $STATUS
