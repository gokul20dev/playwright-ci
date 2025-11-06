#!/bin/bash
set -e

cd /workspace

# Install updates if needed
npm ci || npm install

# Run tests and generate HTML report
npx playwright test --reporter=html
STATUS=$?

# Report
zip -r playwright-report.zip ./playwright-report

# Send email report
echo -e "Playwright tests completed.\nExit code: $STATUS" \
 | mutt -s "Playwright Report" -a playwright-report.zip -- gopalakrishnan93843@gmail.com

exit $STATUS
