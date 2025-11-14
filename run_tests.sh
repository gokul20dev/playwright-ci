#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1' ERR

cd /workspace
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

# --- STEP 1: Install dependencies safely ---
echo "📦 [$(date +"%T")] Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || {
        echo "⚠️ npm ci failed — falling back to npm install";
        npm install --legacy-peer-deps --quiet;
    }
else
    npm install --quiet
fi
echo "✅ [$(date +"%T")] Dependencies installed."

# --- STEP 2: Run Playwright tests ---
TEST_SUITE=${TEST_SUITE:-all}
PLAYWRIGHT_LOG="playwright_error.log"
echo "▶️ [$(date +"%T")] Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test --config=playwright.config.js > >(tee $PLAYWRIGHT_LOG) 2>&1 || true
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" --config=playwright.config.js > >(tee $PLAYWRIGHT_LOG) 2>&1 || true
fi

echo "🕒 [$(date +"%T")] Waiting 4 seconds for report finalization..."
sleep 4

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"

# --- STEP 3: Detect ENVIRONMENT automatically ---
echo "🌍 Detecting Environment..."

if grep -qi "staging" "$PLAYWRIGHT_LOG"; then
    export ENVIRONMENT="Staging"
elif grep -qi "uat" "$PLAYWRIGHT_LOG"; then
    export ENVIRONMENT="UAT"
elif grep -qi "dev" "$PLAYWRIGHT_LOG"; then
    export ENVIRONMENT="Development"
elif grep -qi "qa" "$PLAYWRIGHT_LOG"; then
    export ENVIRONMENT="QA"
else
    export ENVIRONMENT="Production"
fi

echo "🌍 Environment detected: $ENVIRONMENT"

# --- STEP 4: Ensure HTML report exists ---
if [ -d "playwright-report" ] && [ -f "playwright-report/index.html" ]; then
    echo "✅ [$(date +"%T")] HTML report generated."
else
    echo "⚠️ [$(date +"%T")] HTML report missing. Creating fallback..."
    mkdir -p playwright-report
    {
        echo "<html><body style='font-family: monospace; background:#111; color:#f55;'>"
        echo "<h2>❌ Playwright Tests Failed: ${TEST_SUITE}</h2>"
        echo "<p><b>Timestamp:</b> $(date)</p>"
        echo "<h3>Error Log:</h3><pre>"
        cat "$PLAYWRIGHT_LOG" || echo "No logs found."
        echo "</pre></body></html>"
    } > playwright-report/index.html
fi

# --- STEP 5: Determine test status ---
if grep -qi "failed" "$PLAYWRIGHT_LOG"; then
    export TEST_STATUS="Failed"
    export TEST_SUBJECT="Playwright Tests Failed: ${TEST_SUITE}"
else
    export TEST_STATUS="Passed"
    export TEST_SUBJECT="Playwright Tests Passed: ${TEST_SUITE}"
fi

# --- STEP 6: Upload to AWS S3 ---
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ] && [ -f "playwright-report/index.html" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ [$(date +"%T")] Uploading report to S3: s3://${S3_BUCKET}/${S3_PATH}"

    if [ ! -s "playwright-report/index.html" ]; then
        echo "⚠️ Report seems empty — waiting 5 more seconds..."
        sleep 5
    fi

    if aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive; then
        echo "🌐 [$(date +"%T")] Report uploaded successfully!"

        if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
            export REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
            echo "🔗 Report URL (24h): ${REPORT_URL}"
        else
            echo "❌ index.html missing in S3."
            export REPORT_URL=""
        fi
    else
        echo "❌ [$(date +"%T")] Failed to upload report."
        export REPORT_URL=""
    fi
else
    echo "⚠️ [$(date +"%T")] Skipping S3 upload — missing values or report file."
    export REPORT_URL=""
fi

# --- STEP 7: Send Email Report ---
echo "📧 [$(date +"%T")] Sending report email..."
export GMAIL_USER=${GMAIL_USER}
export GMAIL_PASS=${GMAIL_PASS}

node send_report.js || echo "⚠️ Email sending failed. Continuing..."

# --- STEP 8: Cleanup ---
echo "🧹 [$(date +"%T")] Cleaning up Playwright processes..."
pkill -f "playwright" || true

echo "✅ [$(date +"%T")] Test execution finished."
echo "🧾 Container exiting gracefully..."
exit 0

