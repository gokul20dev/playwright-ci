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

# --- Run Playwright tests with JSON output to file ---
if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a npx playwright test \
      --reporter=json=playwright-report/results.json \
      --output=playwright-report \
      > >(tee $PLAYWRIGHT_LOG) 2>&1
else
    xvfb-run -a npx playwright test "tests/${TEST_SUITE}.spec.js" \
      --reporter=json=playwright-report/results.json \
      --output=playwright-report \
      > >(tee $PLAYWRIGHT_LOG) 2>&1
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
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive

    export REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
    echo "🔗 Report URL: ${REPORT_URL}"
fi

# --- Send Email (ALWAYS RUNS) ---
echo "📧 Sending email report..."
node /workspace/send_report.js || echo "⚠️ Email sending failed but continuing..."

echo "🎉 Run completed. Exiting container."
exit 0
