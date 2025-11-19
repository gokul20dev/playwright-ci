#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

echo ""
echo "============== STARTING DEBUG PIPELINE =============="
echo ""

cd /workspace || exit 1

START_TIME=$(date +%s)

echo "🧹 Cleaning old report..."
rm -rf playwright-report
mkdir -p playwright-report

echo "📦 Installing NPM deps..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || npm install --legacy-peer-deps --quiet
else
    npm install --quiet
fi

echo "========================================"
echo "▶️ RUNNING PLAYWRIGHT TESTS"
echo "========================================"

TEST_SUITE=${TEST_SUITE:-all}
JSON_OUTPUT="playwright-report/results.json"
TEST_EXIT_CODE=0

echo "Running suite = $TEST_SUITE"

if [ "$TEST_SUITE" = "all" ]; then
    echo "DEBUG: running ALL tests"
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report 2>&1 | tee "$JSON_OUTPUT" \
        || TEST_EXIT_CODE=$?
else
    if [ -d "tests/${TEST_SUITE}" ]; then
        echo "DEBUG: Running folder tests/${TEST_SUITE}"
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}" \
          --config=playwright.config.ts --reporter=json,html \
          --output=playwright-report 2>&1 | tee "$JSON_OUTPUT" \
          || TEST_EXIT_CODE=$?
    else
        echo "DEBUG: Running single test tests/${TEST_SUITE}.spec.js"
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
          --config=playwright.config.ts --reporter=json,html \
          --output=playwright-report 2>&1 | tee "$JSON_OUTPUT" \
          || TEST_EXIT_CODE=$?
    fi
fi

echo "Playwright exit code = $TEST_EXIT_CODE"
echo "========================================"

echo ""
echo "🔍 DEBUG: CHECKING WHAT FILES PLAYWRIGHT CREATED..."
ls -R playwright-report || true
echo ""

echo "========================================"
echo "🔍 FINDING HTML REPORT"
echo "========================================"

REAL_REPORT=""

echo "Checking root index.html..."
if [ -f "playwright-report/index.html" ]; then
    REAL_REPORT="playwright-report/index.html"
fi

echo "Checking nested playwright-report/playwright-report/index.html..."
if [ -z "$REAL_REPORT" ] && [ -f "playwright-report/playwright-report/index.html" ]; then
    REAL_REPORT="playwright-report/playwright-report/index.html"
fi

echo "Checking html/index.html (new version)..."
if [ -z "$REAL_REPORT" ] && [ -f "playwright-report/html/index.html" ]; then
    REAL_REPORT="playwright-report/html/index.html"
fi

echo "Searching ANY index.html..."
if [ -z "$REAL_REPORT" ]; then
    REAL_REPORT=$(find playwright-report -type f -name "index.html" | head -n 1 || true)
fi

echo "Searching ANY report.html..."
if [ -z "$REAL_REPORT" ]; then
    REAL_REPORT=$(find playwright-report -type f -name "report.html" | head -n 1 || true)
fi

if [ -z "$REAL_REPORT" ]; then
    echo "⚠️ NO REAL REPORT FOUND → creating fallback"
    REAL_REPORT="playwright-report/index.html"
    echo "<h2>No HTML report generated</h2>" > "$REAL_REPORT"
fi

echo "👉 FINAL REPORT FILE SELECTED = $REAL_REPORT"
cp "$REAL_REPORT" playwright-report/index.html

echo "========================================"
echo "☁️ DEBUG: STARTING S3 UPLOAD"
echo "========================================"

if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "Uploading to S3 → s3://${S3_BUCKET}/${S3_PATH}"

    echo "Uploading index.html..."
    aws s3 cp "playwright-report/index.html" \
      "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "$AWS_REGION" || true

    echo "Uploading full report folder..."
    aws s3 cp playwright-report \
      "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" \
      --recursive --region "$AWS_REGION" || true

    echo "Generating presigned URL..."
    REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" \
        --expires-in 86400 --region "$AWS_REGION" 2>/dev/null || true)

    export REPORT_URL
    echo "Presigned URL = $REPORT_URL"

else
    export REPORT_URL=""
    echo "⚠️ S3 NOT CONFIGURED"
fi

echo "========================================"
echo "📧 DEBUG: SENDING EMAIL..."
echo "========================================"

node send_report.js || echo "⚠️ EMAIL FAILED"

echo "========================================"
echo "🧹 CLEANUP"
echo "========================================"

pkill -f "playwright" || true
CID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
[ -n "$CID" ] && curl --unix-socket /var/run/docker.sock \
  -s -X POST "http:/v1.41/containers/$CID/stop" || true

echo ""
echo "=============== DONE ==============="
echo ""
