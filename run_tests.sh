#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1' ERR

cd /workspace
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

# --- STEP 1: Install dependencies safely ---
echo "📦 [$(date +"%T")] Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --quiet || { echo "⚠️ npm ci failed — falling back to npm install"; npm install --legacy-peer-deps --quiet; }
else
    npm install --legacy-peer-deps --quiet
fi
echo "✅ [$(date +"%T")] Dependencies installed."

# --- STEP 2: Run Playwright tests ---
TEST_SUITE=${TEST_SUITE:-all}
PLAYWRIGHT_LOG="playwright_error.log"
echo "▶️ [$(date +"%T")] Running Playwright tests for suite: ${TEST_SUITE}"

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test --reporter=html > >(tee $PLAYWRIGHT_LOG) 2>&1 || true
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" --reporter=html > >(tee $PLAYWRIGHT_LOG) 2>&1 || true
fi

echo "🕒 [$(date +"%T")] Waiting 5 seconds for report finalization..."
sleep 5

# --- STEP 3: Ensure report exists ---
if [ -d "playwright-report" ]; then
    echo "✅ [$(date +"%T")] Playwright HTML report generated successfully."
else
    echo "⚠️ [$(date +"%T")] No Playwright report found. Creating fallback HTML..."
    mkdir -p playwright-report
    {
        echo "<html><body style='font-family: monospace; background-color:#111; color:#f55;'>"
        echo "<h2>❌ Playwright Tests Failed: ${TEST_SUITE}</h2>"
        echo "<p><b>Timestamp:</b> $(date)</p>"
        echo "<h3>Captured Error Log:</h3><pre>"
        cat "$PLAYWRIGHT_LOG" || echo "No log captured."
        echo "</pre></body></html>"
    } > playwright-report/index.html
fi

# --- STEP 4: Determine test status ---
if grep -qi "failed" "$PLAYWRIGHT_LOG"; then
    export TEST_STATUS="Failed"
    export TEST_SUBJECT="❌ Playwright Tests Failed: ${TEST_SUITE}"
else
    export TEST_STATUS="Passed"
    export TEST_SUBJECT="✅ Playwright Tests Passed: ${TEST_SUITE}"
fi

# --- STEP 5: Upload to AWS S3 (before email) ---
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ] && [ -f "playwright-report/index.html" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"
    echo "☁️ [$(date +"%T")] Uploading report to S3: s3://${S3_BUCKET}/${S3_PATH}"

    # Wait if the report is still being finalized
    if [ ! -s "playwright-report/index.html" ]; then
        echo "⚠️ Report file appears empty. Waiting additional 5 seconds..."
        sleep 5
    fi

    # Upload and verify
    if aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}" --recursive; then
        echo "🌐 [$(date +"%T")] Report uploaded successfully!"

        # Verify that index.html exists
        if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" >/dev/null; then
            export REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400)
            echo "🔗 Pre-signed Report URL (valid 24h): ${REPORT_URL}"
        else
            echo "❌ index.html not found in S3 after upload."
            export REPORT_URL=""
        fi

        # Log number of files uploaded for debugging
        echo "📄 Files uploaded to S3 path:"
        aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}" || echo "⚠️ Could not list uploaded files."

    else
        echo "❌ [$(date +"%T")] Failed to upload to S3."
        export REPORT_URL=""
    fi
else
    echo "⚠️ [$(date +"%T")] Skipping S3 upload — missing credentials or report file."
    export REPORT_URL=""
fi

# --- STEP 6: Send Email Report ---
echo "📧 [$(date +"%T")] Sending report email via Node.js..."
export GMAIL_USER=${GMAIL_USER}
export GMAIL_PASS=${GMAIL_PASS}
node send_report.js || echo "⚠️ Email sending failed, continuing."

# --- STEP 7: Cleanup & Exit ---
echo "🧹 [$(date +"%T")] Cleaning up old Playwright processes..."
pkill -f "playwright" || true

echo "✅ [$(date +"%T")] Test execution completed successfully."
echo "🧾 Container exiting gracefully..."
exit 0

