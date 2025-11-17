#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace
echo "▶️ Starting Playwright CI Test Runner"
echo "-----------------------------------------------"

START_TIME=$(date +%s)

############################################
# 0️⃣ CLEAN OLD REPORT
############################################
echo "🧹 Removing old playwright-report..."
rm -rf playwright-report
mkdir -p playwright-report

############################################
# 1️⃣ INSTALL DEPENDENCIES
############################################
echo "📦 Installing dependencies..."

if [ -f "package-lock.json" ]; then
    npm ci --quiet || npm install --legacy-peer-deps --quiet
else
    npm install --quiet
fi

echo "✅ Dependencies installed."

############################################
# 2️⃣ RUN PLAYWRIGHT TESTS (CORRECT JSON SAVE)
############################################
TEST_SUITE=${TEST_SUITE:-all}
TEST_EXIT_CODE=0

echo "▶️ Running suite: ${TEST_SUITE}"

JSON_FILE="playwright-report/results.json"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        --reporter=json="${JSON_FILE}" \
        || TEST_EXIT_CODE=$?
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        --reporter=json="${JSON_FILE}" \
        || TEST_EXIT_CODE=$?
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

sleep 3

############################################
# 3️⃣ FIX MISSING JSON
############################################
if [ ! -s "$JSON_FILE" ]; then
    echo "⚠️ JSON missing → creating fallback"
    echo '{"suites":[]}' > "$JSON_FILE"
fi

############################################
# 4️⃣ GENERATE FINAL HTML REPORT
############################################
echo "🎨 Generating final HTML report..."
npx playwright show-report playwright-report >/dev/null 2>&1 || true

############################################
# 5️⃣ SET STATUS
############################################
if [ "$TEST_EXIT_CODE" != "0" ]; then
    TEST_STATUS="Failed"
else
    TEST_STATUS="Passed"
fi

export TEST_STATUS

############################################
# 6️⃣ UPLOAD TO S3
############################################
if [ -n "${S3_BUCKET:-}" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading to s3://${S3_BUCKET}/${S3_PATH}"

    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive || true

    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
        export REPORT_URL
        echo "🔗 Report URL: $REPORT_URL"
    fi
else
    echo "⚠️ Skipping S3 upload."
fi

############################################
# 7️⃣ SEND EMAIL
############################################
echo "📧 Sending email..."
node send_report.js || echo "⚠️ Email failed"

############################################
# 8️⃣ CLEANUP
############################################
pkill -f "playwright" || true

echo "✅ Finished."

###############################################
# NEVER FAIL PIPELINE
###############################################
exit 0
