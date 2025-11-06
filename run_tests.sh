#!/bin/bash
set +e

cd /workspace

echo "▶️ Install dependencies..."
npm ci --quiet

echo "▶️ Running Playwright tests..."
npx playwright test --reporter=html
TEST_STATUS=$?

echo "▶️ Sending email via Node.js..."
if [ $TEST_STATUS -eq 0 ]; then
    export TEST_SUBJECT="✅ Playwright Tests Passed"
else
    export TEST_SUBJECT="❌ Playwright Tests Failed"
fi

node send_report.js

echo "✅ Email send attempt complete!"
exit 0
