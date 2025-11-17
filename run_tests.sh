#!/bin/bash
# SAFE MODE: Do NOT stop script when errors happen
set +e

cd /workspace
echo "▶️ Starting Playwright CI Runner"

START_TIME=$(date +%s)

# --- Install dependencies ---
echo "📦 Installing dependencies..."
npm ci --quiet || npm install --legacy-peer-deps --quiet

# --- Prepare logs & folders ---
TEST_SUITE=${TEST_SUITE:-all}
PLAYWRIGHT_LOG="playwright_error.log"
JSON_REPORT="playwright-report/results.json"

mkdir -p playwright-report

echo "▶️ Running Playwright suite: ${TEST_SUITE}"

# --- Run Playwright tests and capture JSON output to file and log ---
# Use reporter=json (prints JSON to stdout) and capture that stdout to results.json + log
if [ "$TEST_SUITE" = "all" ]; then
    # run tests; capture stdout (JSON) to both results.json and the normal log
    xvfb-run -a npx playwright test --reporter=json --output=playwright-report 2>&1 \
      | tee "$PLAYWRIGHT_LOG" | tee "$JSON_REPORT" >/dev/null
else
    xvfb-run -a npx playwright test "tests/${TEST_SUITE}.spec.js" --reporter=json --output=playwright-report 2>&1 \
      | tee "$PLAYWRIGHT_LOG" | tee "$JSON_REPORT" >/dev/null
fi

TEST_EXIT_CODE=$?
echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

# --- Determine TEST_STATUS ---
if [ $TEST_EXIT_CODE -eq 0 ]; then
    export TEST_STATUS="Passed"
else
    export TEST_STATUS="Failed"
fi

# --- Compute Duration ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"

# --- Upload to S3 if report exists ---
if [ -f "playwright-report/index.html" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading report to S3..."
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive || true

    # only presign if upload succeeded (we attempt anyway)
    REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400 2>/dev/null || echo "")
    export REPORT_URL
    echo "🔗 Report URL: ${REPORT_URL}"
fi

# --- Debug: show the JSON file size (optional) ---
if [ -f "$JSON_REPORT" ]; then
    echo "🔍 JSON report size:"
    ls -lh "$JSON_REPORT" || true
else
    echo "⚠️ JSON report not created."
fi

# --- Send Email (ALWAYS RUNS) ---
echo "📧 Sending email report..."
node /workspace/send_report.js || echo "⚠️ Email sending failed but continuing..."

echo "🎉 Run completed. Exiting container."
exit 0
