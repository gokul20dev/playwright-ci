#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1' ERR

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
PLAYWRIGHT_LOG="playwright-error.log"

echo "▶️ Running suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        2>&1 | tee "$PLAYWRIGHT_LOG" | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
else
    # detect folder or .spec file
    if [ -d "tests/${TEST_SUITE}" ]; then
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}" \
            --config=playwright.config.ts \
            --reporter=json,html \
            --output=playwright-report \
            2>&1 | tee "$PLAYWRIGHT_LOG" | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
    else
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
            --config=playwright.config.ts \
            --reporter=json,html \
            --output=playwright-report \
            2>&1 | tee "$PLAYWRIGHT_LOG" | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
    fi
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

############################################
# RELIABLE HTML DETECTION
############################################
REPORT_ROOT="playwright-report/index.html"

# 1) Prefer suite folder: index.html or report.html
if [ -d "playwright-report/${TEST_SUITE}" ]; then
    if [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
        echo "📄 Using suite index.html"
        cp "playwright-report/${TEST_SUITE}/index.html" "$REPORT_ROOT" || true
    fi
    if [ ! -f "$REPORT_ROOT" ] && [ -f "playwright-report/${TEST_SUITE}/report.html" ]; then
        echo "📄 Using suite report.html"
        cp "playwright-report/${TEST_SUITE}/report.html" "$REPORT_ROOT" || true
    fi
fi

# 2) Search ANY index.html
if [ ! -f "$REPORT_ROOT" ]; then
    FOUND_INDEX=$(find playwright-report -type f -name "index.html" 2>/dev/null | head -n 1 || true)
    if [ -n "$FOUND_INDEX" ]; then
        echo "📄 Found nested index.html → $FOUND_INDEX"
        cp "$FOUND_INDEX" "$REPORT_ROOT" || true
    fi
fi

# 3) Search ANY report.html
if [ ! -f "$REPORT_ROOT" ]; then
    FOUND_REPORT=$(find playwright-report -type f -name "report.html" 2>/dev/null | head -n 1 || true)
    if [ -n "$FOUND_REPORT" ]; then
        echo "📄 Found nested report.html → $FOUND_REPORT"
        cp "$FOUND_REPORT" "$REPORT_ROOT" || true
    fi
fi

# 4) Final fallback: create a helpful fallback containing last lines of Playwright log
if [ ! -f "$REPORT_ROOT" ]; then
    echo "⚠️ No HTML report → creating fallback (includes error log tail)"
    {
      echo "<!doctype html><html><head><meta charset='utf-8'><title>No HTML report generated</title></head><body>"
      echo "<h2>No HTML report generated</h2>"
      echo "<p>Playwright did not produce an HTML report for this run. Last log lines:</p><pre>"
      tail -n 200 "$PLAYWRIGHT_LOG" 2>/dev/null || echo "No playwright log available."
      echo "</pre></body></html>"
    } > "$REPORT_ROOT"
fi

############################################
# ENSURE JSON EXISTS
############################################
if [ ! -s "$JSON_OUTPUT" ]; then
    echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

############################################
# TEST STATUS & DURATION
############################################
TEST_STATUS="Passed"
[ $TEST_EXIT_CODE -ne 0 ] && TEST_STATUS="Failed"
export TEST_STATUS

END_TIME=$(date +%s)
export TEST_DURATION="$((END_TIME - START_TIME))s"
export TEST_SUITE

############################################
# UPLOAD TO S3 (if configured)
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading to s3://${S3_BUCKET}/${S3_PATH}"

    # upload root index.html (guaranteed to exist)
    aws s3 cp "$REPORT_ROOT" "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "$AWS_REGION" || true

    # upload the entire report folder (so assets like css/js/screenshots exist)
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive --region "$AWS_REGION" || true

    # verify and presign
    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "$AWS_REGION" >/dev/null 2>&1; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400 --region "$AWS_REGION" 2>/dev/null || true)
        if [ -n "${REPORT_URL:-}" ]; then
            export REPORT_URL
            echo "🔗 Report URL: $REPORT_URL"
        else
            export REPORT_URL=""
            echo "❌ Failed to generate presigned URL"
        fi
    else
        export REPORT_URL=""
        echo "❌ index.html missing in S3 → presigned URL not created"
    fi
else
    export REPORT_URL=""
    echo "⚠️ S3 Upload disabled (S3_BUCKET or AWS_REGION not set)"
fi

############################################
# PAUSE to ensure eventual consistency
############################################
echo "⏳ Waiting 6 seconds for file flush / S3 consistency..."
sleep 6

############################################
# SEND EMAIL
############################################
echo "📧 Sending email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# CLEANUP
############################################
pkill -f "playwright" || true

CID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
[ -n "$CID" ] && curl --unix-socket /var/run/docker.sock -s -X POST "http:/v1.41/containers/$CID/stop" || true

echo "✅ Finished suite=$TEST_SUITE | status=$TEST_STATUS | duration=$TEST_DURATION"
exit 0
