#!/bin/bash
set +e

cd /workspace

echo "▶️ Install dependencies..."
npm ci --quiet

echo "▶️ Running Playwright tests..."
npx playwright test --reporter=html
TEST_STATUS=$?

echo "▶️ Zipping report..."
zip -r playwright-report.zip playwright-report

if [ $TEST_STATUS -eq 0 ]; then
    export TEST_SUBJECT="✅ Playwright Tests Passed"
else
    export TEST_SUBJECT="❌ Playwright Tests Failed"
fi

echo "▶️ Sending Email via Node.js..."
node send_report.js

echo "✅ Email send attempt complete!"
exit 0
