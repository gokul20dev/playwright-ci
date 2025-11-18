#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

############################################
# 0️⃣ CLEAN OLD REPORT
############################################
echo "🧹 Cleaning old Playwright report..."
rm -rf playwright-report
mkdir -p playwright-report

############################################
# 1️⃣ Install dependencies
############################################
echo "📦 Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || npm install --legacy-peer-deps --quiet
else
    npm install --quiet
fi
echo "✅ Dependencies installed."

############################################
# 2️⃣ Run Playwright Tests (JSON + HTML)
############################################

TEST_SUITE=${TEST_SUITE:-all}
TEST_EXIT_CODE=0

JSON_OUTPUT="playwright-report/results.json"

echo "▶️ Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

echo "📁 DEBUG: Listing playwright-report folder"
find playwright-report -maxdepth 5 -type f -print

############################################
# 3️⃣ Ensure JSON exists
############################################
if [ ! -s "$JSON_OUTPUT" ]; then
    echo "⚠️ JSON missing → creating fallback"
    echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

############################################
# 4️⃣ DO NOT RUN show-report (hangs CI)
############################################
echo "🎨 HTML report generated safely."

############################################
# 5️⃣ Test Status
############################################
if [ $TEST_EXIT_CODE -ne 0 ]; then
    TEST_STATUS="Failed"
else
    TEST_STATUS="Passed"
fi
export TEST_STATUS

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"

############################################
# 6️⃣ Upload to S3 (FIXED LOGIC)
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading report to S3 → s3://${S3_BUCKET}/${S3_PATH}"

    ############################################
    # 🔍 AUTO-DETECT CORRECT HTML REPORT PATH
    ############################################
    HTML_FILE=""

    # Case 1: Root index.html (Exammaker)
    if [ -f "playwright-report/index.html" ]; then
        HTML_FILE="playwright-report/index.html"

    # Case 2: Suite folder index.html (Examtaker/reports/all)
    elif [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
        HTML_FILE="playwright-report/${TEST_SUITE}/index.html"

    # Case 3: Playwright may generate under /all/ even when TEST_SUITE != all
    elif [ -f "playwright-report/all/index.html" ]; then
        HTML_FILE="playwright-report/all/index.html"
    fi

    ############################################
    # 📤 Upload correct index.html into root of S3 suite folder
    ############################################
    if [ -n "$HTML_FILE" ]; then
        echo "📤 Uploading HTML report: $HTML_FILE"
        aws s3 cp "$HTML_FILE" "s3://${S3_BUCKET}/${S3_PATH}index.html" || true
    else
        echo "❌ No HTML report found for suite ${TEST_SUITE}"
    fi

    ############################################
    # 📤 Upload full report folder
    ############################################
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive || true

    ############################################
    # 🔗 Generate Presigned URL
    ############################################
    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
        export REPORT_URL
        echo "🔗 Report URL: $REPORT_URL"
    else
        REPORT_URL=""
        echo "❌ index.html missing in S3 → Button will not appear"
    fi

else
    export REPORT_URL=""
    echo "⚠️ S3 upload skipped"
fi


############################################
# 7️⃣ Email report
############################################
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# 8️⃣ Cleanup
############################################
echo "🧹 Killing Playwright background processes..."
pkill -f "playwright" || true

echo "🛑 Auto-stopping this container..."
CONTAINER_ID=$(basename "$(cat /proc/1/cpuset)")

curl --unix-socket /var/run/docker.sock -X POST "http:/v1.41/containers/${CONTAINER_ID}/stop" || true

echo "✅ Test execution finished."
exit 0
