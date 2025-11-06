#!/bin/bash
set +e  # Do NOT exit on failure

cd /workspace

echo "▶️ Running Playwright tests..."

# Run tests and generate HTML report
npx playwright test ./tests --reporter=html
TEST_STATUS=$?

# Zip test report
zip -r playwright-report.zip ./playwright-report

# Email message based on status
if [ $TEST_STATUS -eq 0 ]; then
    SUBJECT="✅ Playwright Test Passed"
    BODY="Hey team,\n\nAll UI tests passed successfully.\n\nRegards,\nJenkins"
else
    SUBJECT="❌ Playwright Test Failed"
    BODY="Hey team,\n\nSome UI tests failed.\nPlease check the attached report.\n\nRegards,\nJenkins"
fi

# Send mail to multiple recipients
echo -e "$BODY" | mutt -s "$SUBJECT" \
    -a playwright-report.zip -- \
    gokulgokul78752@gmail.com \
    gokullcoal78752@gmail.com

echo "📨 Email sent to recipients!"

exit 0  # ✅ Continue pipeline regardless of test results
