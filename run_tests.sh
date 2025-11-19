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
    # try to run suite by path under tests/ or by file tests/<suite>.spec.js
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
# ⭐ RELIABLE HTML DETECTION
# - Playwright sometimes places index.html nested under a suite folder
# - or emits report.html instead of index.html
# - We'll copy the real index.html into playwright-report/index.html
############################################

# 1) If suite-specific folder exists and contains index.html, prefer that
if [ -d "playwright-report/${TEST_SUITE}" ] && [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
    echo "📄 Using suite-specific HTML → playwright-report/${TEST_SUITE}/index.html"
    cp "playwright-report/${TEST_SUITE}/index.html" playwright-report/index.html || true
fi

# 2) If still missing, search for any index.html under playwright-report and copy the first one
if [ ! -f "playwright-report/index.html" ]; then
    REAL_HTML=$(find playwright-report -type f -name "index.html" 2>/dev/null | head -n 1 || true)
    if [ -n "$REAL_HTML" ]; then
        echo "📄 Auto-detected HTML report at: $REAL_HTML"
        cp "$REAL_HTML" playwright-report/index.html || true
    fi
fi

# 3) If Playwright created report.html, move/rename it
if [ ! -f "playwright-report/index.html" ] && [ -f "playwright-report/report.html" ]; then
    echo "📄 Found report.html → renaming to index.html"
    mv playwright-report/report.html playwright-report/index.html || true
fi

# 4) Last resort: create a small placeholder so email attachment / S3 always has something
if [ ! -f "playwright-report/index.html" ]; then
    echo "⚠️ No HTML report found → creating placeholder index.html"
    cat > playwright-report/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>No HTML report generated</title></head>
  <body><h2>No HTML report generated</h2><p>Playwright did not produce an HTML report for this run.</p></body>
</html>
HTML
fi

############################################
# 3️⃣ Ensure JSON exists
############################################
if [ ! -s "$JSON_OUTPUT" ]; then
    echo "⚠️ JSON missing → creating fallback"
    echo '{"suites":[]}' > "$JSON_OUTPUT"
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
# 5️⃣ Upload to S3 (if configured)
############################################
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    echo "☁️ Uploading report to S3 → s3://${S3_BUCKET}/${S3_PATH}"

    # upload the root index.html (guaranteed to exist now)
    aws s3 cp "playwright-report/index.html" "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "${AWS_REGION}" || true

    # upload the whole playwright-report folder so all assets are present
    aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive --region "${AWS_REGION}" || true

    # generate presigned URL if index was uploaded
    if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "${AWS_REGION}" >/dev/null 2>&1; then
        REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400 --region "${AWS_REGION}" 2>/dev/null || true)
        if [ -n "${REPORT_URL:-}" ]; then
            export REPORT_URL
            echo "🔗 Report URL: $REPORT_URL"
        else
            REPORT_URL=""
            export REPORT_URL
            echo "❌ Failed to generate presigned URL"
        fi
    else
        REPORT_URL=""
        export REPORT_URL
        echo "❌ index.html missing in S3 → presigned URL not created"
    fi
else
    export REPORT_URL=""
    echo "⚠️ S3 upload skipped (S3_BUCKET or AWS_REGION not set)"
fi

############################################
# ⭐ Pause a little to ensure files are flushed / visible
############################################
echo "⏳ Waiting 10 seconds to ensure files are flushed and S3 consistency..."
sleep 10

############################################
# 6️⃣ Send Email (send_report.js will use REPORT_URL and attachments)
############################################
echo "📧 Sending report email..."
node send_report.js || echo "⚠️ Email sending failed"

############################################
# 7️⃣ Cleanup & Stop Container
############################################
pkill -f "playwright" || true

# Figure out this container id and stop it via docker socket (works when container created with docker create)
if [ -f /proc/1/cpuset ]; then
    CONTAINER_ID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
    if [ -n "$CONTAINER_ID" ]; then
        echo "🛑 Auto-stopping this container (${CONTAINER_ID})..."
        curl --unix-socket /var/run/docker.sock -s -X POST "http:/v1.41/containers/${CONTAINER_ID}/stop" || true
    fi
fi

echo "✅ Finished. Suite=${TEST_SUITE} Status=${TEST_STATUS} Duration=${TEST_DURATION}"
exit 0
