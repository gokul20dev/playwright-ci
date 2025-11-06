#!/bin/bash
set +e  # Continue even if tests fail

cd /workspace

echo "▶️ Running Playwright tests..."

# Run tests and generate HTML report
npx playwright test ./tests --reporter=html
TEST_STATUS=$?

# Zip test report
zip -r playwright-report.zip ./playwright-report

# Email subject & message based on results
if [ $TEST_STATUS -eq 0 ]; then
    SUBJECT="✅ Playwright Test Passed"
    BODY="Hello,\n\nAll Playwright UI tests passed successfully.\n\nRegards,\nJenkins"
else
    SUBJECT="❌ Playwright Test Failed"
    BODY="Hello,\n\nSome Playwright tests failed.\nPlease check the attached report.\n\nRegards,\nJenkins"
fi

# Send mail to your Gmail
echo -e "$BODY" | mutt -s "$SUBJECT" \
    -a playwright-report.zip -- \
    gopalakrishnan93843@gmail.com

echo "📨 Email triggered!"
exit 0
