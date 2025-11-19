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


############################################
# ⭐ FIX 1 — Ensure index.html always exists
############################################
# Playwright sometimes generates report.html
if [ -f "playwright-report/report.html" ]; then
    echo "🔧 Found report.html → renaming to index.html"
    mv playwright-report/report.html playwright-report/index.html
fi

# If nested folder exists, pick correct index.html
if [ ! -f "playwright-report/index.html" ]; then
    NESTED_INDEX=$(find playwright-report -name "index.html" | head -n 1 || true)
    if [ -n "$NESTED_INDEX" ]; then
        echo "🔧 Found nested HTML → copying to root"
        cp "$NESTED_INDEX" playwright-report/index.html
    fi
fi

############################################
# 3️⃣ Ensure JSON exists
############################################
if [ ! -s "$JSON_OUTPUT" ]; then
    echo "⚠️ JSON missing → creating fallback"
    echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

############################################
# 4️⃣ Safe report message
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
# 6️⃣ Upload to S3
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading report to S3 → s3://${S3_BUCKET}/${S3_PATH}"

    # Upload HTML
    if [ -f "playwright-report/index.html" ]; then
        aws s3 cp "playwright-report/index.html" \
           "s3://${S3_BUCKET}/${S3_PATH}index.html" || true
    fi

    # Upload full folder
    aws s3 cp playwright-report \
       "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive || true

    # Generate presigned URL
    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
        REPORT_URL=$(aws s3 presign \
          "s3://${S3_BUCKET}/${S3_PATH}index.html" \
          --expires-in 86400)
        export REPORT_URL
    else
        REPORT_URL=""
    fi
else
    export REPORT_URL=""
fi

############################################
# ⭐ FIX 2 — ADD DELAY BEFORE SENDING EMAIL
# Fixes missing report for ALL suite
############################################
echo "⏳ Waiting 15 seconds to ensure files are fully written..."
sleep 15

############################################
# 7️⃣ Email report
############################################
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# 8️⃣ Cleanup
############################################
pkill -f "playwright" || true

CONTAINER_ID=$(basename "$(cat /proc/1/cpuset)")
curl --unix-socket /var/run/docker.sock \
    -X POST "http:/v1.41/containers/${CONTAINER_ID}/stop" || true

echo "✅ Finished."
exit 0
