#!/bin/bash
set +e

cd /workspace

echo "▶️ Configuring Gmail SMTP..."
cat <<EOF > /etc/Muttrc
set from="$GMAIL_USER"
set realname="$GMAIL_USER"
set smtp_url="smtp://smtp.gmail.com:587"
set smtp_pass="$GMAIL_PASS"
set ssl_starttls=yes
set ssl_force_tls=yes
EOF

echo "▶️ Running Playwright tests..."
npx playwright test ./tests --reporter=html
TEST_STATUS=$?

# Zip test report folder
zip -r playwright-report.zip ./playwright-report

# Email subject & body based on result
if [ $TEST_STATUS -eq 0 ]; then
    SUBJECT="✅ Playwright Tests Passed"
    BODY="Hey,\n\nAll UI tests passed ✅\nCheck report.\n\nRegards,\nJenkins"
else
    SUBJECT="❌ Playwright Tests Failed"
    BODY="Hey,\n\nSome UI tests failed! ❌\nCheck report.\n\nRegards,\nJenkins"
fi

echo "▶️ Sending Email..."
echo -e "$BODY" | mutt -s "$SUBJECT" \
    -a playwright-report.zip -- "$GMAIL_USER"

echo "📨 Email send attempt finished!"

exit 0
