#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

# STEP 1 — Install dependencies
echo "📦 [$(date +"%T")] Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || {
        echo "⚠️ npm ci failed — falling back to npm install"
        npm install --legacy-peer-deps --quiet
    }
else
    npm install --quiet
fi
echo "✅ [$(date +"%T")] Dependencies installed."

# STEP 2 — Run Playwright tests (with real exit code)

TEST_SUITE=${TEST_SUITE:-all}
PLAYWRIGHT_LOG="playwright_error.log"
TEST_EXIT_CODE=0

echo "▶️ [$(date +"%T")] Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json \
        > >(tee playwright-report/results.json) 2>&1 || TEST_EXIT_CODE=$?
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
        --config=playwright.config.ts \
        --reporter=json \
        > >(tee playwright-report/results.json) 2>&1 || TEST_EXIT_CODE=$?
fi

echo "📌 Real Playwright Exit Code = $TEST_EXIT_CODE"

echo "🕒 [$(date +"%T")] Waiting 4 seconds for report finalization..."
sleep 4

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"

# STEP 3 — Detect environment
echo "🌍 Detecting Environment..."
if grep -qi "staging" "$PLAYWRIGHT_LOG"; then
    ENVIRONMENT="Staging"
elif grep -qi "uat" "$PLAYWRIGHT_LOG"; then
    ENVIRONMENT="UAT"
elif grep -qi "dev" "$PLAYWRIGHT_LOG"; then
    ENVIRONMENT="Development"
elif grep -qi "qa" "$PLAYWRIGHT_LOG"; then
    ENVIRONMENT="QA"
else
    ENVIRONMENT="Production"
fi
export ENVIRONMENT
echo "🌍 Environment detected: $ENVIRONMENT"

# STEP 4 — Ensure HTML exists
if [ -d "playwright-report" ] && [ -f "playwright-report/index.html" ]; then
    echo "✅ [$(date +"%T")] HTML report generated."
else
    echo "⚠️ HTML report missing, creating fallback..."
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

# STEP 5 — Set final status
if [ $TEST_EXIT_CODE -ne 0 ]; then
    TEST_STATUS="Failed"
else
    TEST_STATUS="Passed"
fi
export TEST_STATUS
echo "📌 Final Test Status = $TEST_STATUS"

# STEP 6 — Upload to S3
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading report to S3: s3://${S3_BUCKET}/${S3_PATH}"

    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive || true

    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
        export REPORT_URL
        echo "🔗 Report URL: $REPORT_URL"
    else
        export REPORT_URL=""
        echo "❌ index.html missing in S3."
    fi
else
    echo "⚠️ Skipping S3 upload — missing AWS vars."
    export REPORT_URL=""
fi

# STEP 7 — Send email
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed."

# STEP 8 — Cleanup
echo "🧹 Cleaning Playwright processes..."
pkill -f "playwright" || true

echo "✅ Test execution finished."
exit $TEST_EXIT_CODE
