#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace || exit 1
echo "▶️ Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

############################################
# CLEAN OLD REPORT
############################################
rm -rf playwright-report
mkdir -p playwright-report

############################################
# INSTALL DEPENDENCIES
############################################
echo "📦 Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || npm install --legacy-peer-deps --quiet
else
    npm install --quiet
fi

############################################
# RUN PLAYWRIGHT TESTS
############################################
TEST_SUITE=${TEST_SUITE:-all}
TEST_EXIT_CODE=0
JSON_OUTPUT="playwright-report/results.json"

echo "▶️ Running suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?

else
    # detect folder or .spec file
    if [ -d "tests/${TEST_SUITE}" ]; then
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}" \
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
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

############################################
# ⭐ FIX BLOCK: RELIABLE HTML DETECTION
############################################

REPORT_ROOT="playwright-report/index.html"

# 1️⃣ Prefer suite folder: index.html → OR → report.html
if [ -d "playwright-report/${TEST_SUITE}" ]; then

    if [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
        echo "📄 Using suite index.html"
        cp "playwright-report/${TEST_SUITE}/index.html" "$REPORT_ROOT"
    fi

    if [ ! -f "$REPORT_ROOT" ] && [ -f "playwright-report/${TEST_SUITE}/report.html" ]; then
        echo "📄 Using suite report.html"
        cp "playwright-report/${TEST_SUITE}/report.html" "$REPORT_ROOT"
    fi
fi

# 2️⃣ Search ANY index.html in nested folders
if [ ! -f "$REPORT_ROOT" ]; then
    FOUND_INDEX=$(find playwright-report -type f -name "index.html" | head -n 1 || true)
    if [ -n "$FOUND_INDEX" ]; then
        echo "📄 Found nested index.html → $FOUND_INDEX"
        cp "$FOUND_INDEX" "$REPORT_ROOT"
    fi
fi

# 3️⃣ Search ANY report.html in nested folders
if [ ! -f "$REPORT_ROOT" ]; then
    FOUND_REPORT=$(find playwright-report -type f -name "report.html" | head -n 1 || true)
    if [ -n "$FOUND_REPORT" ]; then
        echo "📄 Found nested report.html → $FOUND_REPORT"
        cp "$FOUND_REPORT" "$REPORT_ROOT"
    fi
fi

# 4️⃣ Final fallback
if [ ! -f "$REPORT_ROOT" ]; then
    echo "⚠️ No HTML report → creating fallback"
    echo "<h2>No HTML report generated</h2>" > "$REPORT_ROOT"
fi

############################################
# ENSURE JSON EXISTS
############################################
if [ ! -s "$JSON_OUTPUT" ]; then
    echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

############################################
# TEST STATUS
############################################
TEST_STATUS="Passed"
[ $TEST_EXIT_CODE -ne 0 ] && TEST_STATUS="Failed"
export TEST_STATUS

END_TIME=$(date +%s)
export TEST_DURATION="$((END_TIME - START_TIME))s"

############################################
# UPLOAD TO S3
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading to s3://${S3_BUCKET}/${S3_PATH}"

    aws s3 cp "$REPORT_ROOT" "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "$AWS_REGION" || true
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive --region "$AWS_REGION" || true

    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null 2>&1; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400 --region "$AWS_REGION")
        export REPORT_URL
        echo "🔗 URL: $REPORT_URL"
    else
        export REPORT_URL=""
        echo "❌ Could not generate presigned URL"
    fi
else
    export REPORT_URL=""
    echo "⚠️ S3 Upload disabled"
fi

############################################
# EMAIL REPORT
############################################
echo "📧 Sending email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# CLEANUP
############################################
pkill -f "playwright" || true

CID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
[ -n "$CID" ] && curl --unix-socket /var/run/docker.sock -s -X POST "http:/v1.41/containers/$CID/stop" || true

echo "✅ Finished suite=$TEST_SUITE | status=$TEST_STATUS"
exit 0
