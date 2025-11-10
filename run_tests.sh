#!/bin/bash
set +e

cd /workspace

echo "▶️ Install dependencies..."
npm ci --quiet

# Get test suite name from environment
TEST_SUITE=${TEST_SUITE:-all}

echo "▶️ Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    npx playwright test --reporter=html
else
    npx playwright test "tests/${TEST_SUITE}.spec.js" --reporter=html
fi

TEST_STATUS=$?

echo "▶️ Zipping report..."
zip -r playwright-report.zip playwright-report

if [ $TEST_STATUS -eq 0 ]; then
    export TEST_SUBJECT="✅ Playwright Tests Passed: ${TEST_SUITE}"
else
    export TEST_SUBJECT="❌ Playwright Tests Failed: ${TEST_SUITE}"
fi

echo "▶️ Sending email via Node.js..."
node send_report.js

echo "✅ Email send attempt complete!"
exit 0
