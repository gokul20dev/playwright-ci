#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1"' ERR

cd /workspace || exit 1
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
# 2️⃣ Run Playwright Tests (HTML + JSON)
############################################
TEST_SUITE=${TEST_SUITE:-all}
TEST_EXIT_CODE=0

echo "▶️ Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.ts \
        --reporter=json,html \
        --output=playwright-report \
        | tee playwright-output.log || TEST_EXIT_CODE=$?
else
    if [ -d "tests/${TEST_SUITE}" ]; then
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}" \
            --config=playwright.config.ts \
            --reporter=json,html \
            --output=playwright-report \
            | tee playwright-output.log || TEST_EXIT_CODE=$?
    else
        xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
            --config=playwright.config.ts \
            --reporter=json,html \
            --output=playwright-report \
            | tee playwright-output.log || TEST_EXIT_CODE=$?
    fi
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"

############################################
# 3️⃣ HTML REPORT FIXING (critical)
############################################

# 1) Suite-specific index.html
if [ -d "playwright-report/${TEST_SUITE}" ] && [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
    echo "📄 Using suite-specific HTML → playwright-report/${TEST_SUITE}/index.html"
    cp "playwright-report/${TEST_SUITE}/index.html" playwright-report/index.html || true
fi

# 2) Search for any index.html if missing
if [ ! -f "playwright-report/index.html" ]; then
    REAL_HTML=$(find playwright-report -type f -name "index.html" 2>/dev/null | head -n 1 || true)
    if [ -n "$REAL_HTML" ]; then
        echo "📄 Auto-detected HTML: $REAL_HTML"
        cp "$REAL_HTML" playwright-report/index.html || true
    fi
fi

# 3) Rename report.html if exists
if [ ! -f "playwright-report/index.html" ] && [ -f "playwright-report/report.html" ]; then
    echo "📄 Found report.html → renaming to index.html"
    mv playwright-report/report.html playwright-report/index.html || true
fi

# 4) Create placeholder if still missing
if [ ! -f "playwright-report/index.html" ]; then
    echo "⚠️ No HTML report found → creating placeholder"
    cat > playwright-report/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>No HTML report generated</title></head>
  <body><h2>No HTML report generated</h2><p>Playwright did not produce an HTML report for this run.</p></body>
</html>
HTML
fi

echo "🎨 HTML report generation complete."

############################################
# 4️⃣ Determine Test Status & Duration
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
# 5️⃣ Upload to S3
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading → s3://${S3_BUCKET}/${S3_PATH}"

    aws s3 cp "playwright-report/index.html" \
        "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "${AWS_REGION}" || true

    aws s3 cp playwright-report \
        "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" \
        --recursive --region "${AWS_REGION}" || true

    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null 2>&1; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
        export REPORT_URL
        echo "🔗 Report URL: $REPORT_URL"
    else
        export REPORT_URL=""
        echo "❌ Failed to generate report URL"
    fi
else
    export REPORT_URL=""
    echo "⚠️ S3 upload skipped."
fi

echo "⏳ Waiting 10 seconds to ensure S3 consistency..."
sleep 10

############################################
# 6️⃣ Send Email
############################################
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# 7️⃣ Stop Container
############################################
pkill -f "playwright" || true

if [ -f /proc/1/cpuset ]; then
    CID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
    if [ -n "$CID" ]; then
        echo "🛑 Stopping container ($CID)..."
        curl --unix-socket /var/run/docker.sock -s -X POST "http:/v1.41/containers/${CID}/stop" || true
    fi
fi

echo "✅ Finished. Suite=${TEST_SUITE} Status=${TEST_STATUS} Duration=${TEST_DURATION}"
exit 0
