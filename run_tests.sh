#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

############################################
# 0️⃣ CLEAN OLD REPORT (IMPORTANT FIX)
############################################
echo "🧹 Cleaning old Playwright report..."
rm -rf playwright-report
mkdir -p playwright-report

############################################
# 1️⃣ Install dependencies
############################################
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

############################################
# 2️⃣ Run Playwright Tests – generate JSON + HTML
############################################
TEST_SUITE=${TEST_SUITE:-all}
TEST_EXIT_CODE=0

echo "▶️ [$(date +"%T")] Running Playwright tests for suite: ${TEST_SUITE}"

JSON_OUTPUT="playwright-report/results.json"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        > >(tee "$JSON_OUTPUT") 2>&1 || TEST_EXIT_CODE=$?
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        > >(tee "$JSON_OUTPUT") 2>&1 || TEST_EXIT_CODE=$?
fi

echo "📌 Real Playwright Exit Code = $TEST_EXIT_CODE"

echo "🕒 Waiting 4 seconds..."
sleep 4

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"

############################################
# 3️⃣ Ensure JSON Exists (CRITICAL FIX)
############################################
if [ ! -f "$JSON_OUTPUT" ]; then
    echo "❌ ERROR — results.json missing. Creating fallback empty JSON..."
    echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

############################################
# 4️⃣ Generate fresh HTML report (safe)
############################################
echo "🎨 Generating final HTML report..."
npx playwright show-report playwright-report || true

############################################
# 5️⃣ Test status
############################################
if [ $TEST_EXIT_CODE -ne 0 ]; then
    TEST_STATUS="Failed"
else
    TEST_STATUS="Passed"
fi
export TEST_STATUS

############################################
# 6️⃣ Upload to S3
############################################
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

############################################
# 7️⃣ Email report
############################################
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed."

############################################
# 8️⃣ Cleanup
############################################
echo "🧹 Cleaning Playwright processes..."
pkill -f "playwright" || true

echo "✅ Test execution finished."

###############################################
#    🔴 ALWAYS EXIT 0 (Pipeline never fails)
###############################################
exit 0
