#!/bin/bash
set +e

cd /workspace

echo "▶️ Running Playwright tests..."

# Run tests & generate report
npx playwright test ./tests --reporter=html
TEST_STATUS=$?

# Zip HTML report
zip -r playwright-report.zip ./playwright-report

# Email subject & body
if [ $TEST_STATUS -eq 0 ]; then
    SUBJECT="✅ Playwright Test Passed"
    BODY="Hello,\n\n✅ All Playwright UI tests passed successfully.\n\nRegards,\nJenkins"
else
    SUBJECT="❌ Playwright Test Failed"
    BODY="Hello,\n\n❌ Some tests failed. Please check attached test report.\n\nRegards,\nJenkins"
fi

# Configure Gmail SMTP for mutt
echo "set from=\"$GMAIL_USER\"
set realname=\"Playwright Report\"
set smtp_url=\"smtp://smtp.gmail.com:587\"
set smtp_pass=\"$GMAIL_PASS\"
set smtp_auth=login
set ssl_starttls=yes
set ssl_force_tls=yes
" > ~/.muttrc

# Send email
echo -e "$BODY" | mutt -s "$SUBJECT" \
    -a playwright-report.zip -- "$GMAIL_USER"

echo "📨 Email triggered to $GMAIL_USER!"
exit 0
