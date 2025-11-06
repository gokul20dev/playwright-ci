#!/bin/bash
set +e

cd /workspace

echo "▶️ Configuring Gmail SMTP..."
cat <<EOF > /root/.muttrc
set from="$GMAIL_USER"
set realname="Jenkins Automation"
set smtp_url="smtp://smtp.gmail.com:587"
set smtp_pass="$GMAIL_PASS"
set ssl_starttls=yes
set ssl_force_tls=yes
EOF

echo "▶️ Install dependencies..."
npm ci --quiet

echo "▶️ Running Playwright tests..."
npx playwright test --reporter=html
TEST_STATUS=$?

echo "▶️ Zipping report..."
zip -r playwright-report.zip playwright-report

if [ $TEST_STATUS -eq 0 ]; then
    SUBJECT="✅ Playwright Tests Passed"
    BODY="All UI tests passed ✅\nHTML report attached."
else
    SUBJECT="❌ Playwright Tests Failed"
    BODY="Some UI tests failed ❌\nHTML report attached."
fi

echo "▶️ Sending Email..."
echo -e "$BODY" | mutt -s "$SUBJECT" -a playwright-report.zip -- "$GMAIL_USER"

echo "✅ Email send attempt complete!"
exit 0
