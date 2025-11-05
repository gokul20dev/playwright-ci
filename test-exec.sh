#!/bin/bash
set -e

# Start postfix service
service postfix start

# Run Playwright tests
if npx playwright test; then
    echo "✅ Playwright Tests Passed" | mail -s "✅ UI Tests Passed" "$RECEIVER_EMAIL"
else
    echo "❌ Playwright Tests Failed" | mail -s "❌ UI Tests Failed" "$RECEIVER_EMAIL"
fi

# Stop postfix service
service postfix stop
