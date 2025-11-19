#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"; exit 1' ERR

cd /workspace || { echo "Workspace not found"; exit 1; }
echo "▶️ [$(date +"%T")] Starting Playwright CI Test Runner..."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

# -------------------------------------------
# clean old report
# -------------------------------------------
echo "🧹 Cleaning old Playwright report..."
rm -rf playwright-report
mkdir -p playwright-report

# -------------------------------------------
# install dependencies
# -------------------------------------------
echo "📦 Installing dependencies..."
if [ -f "package-lock.json" ]; then
  npm ci --quiet || npm install --legacy-peer-deps --quiet
else
  npm install --quiet
fi
echo "✅ Dependencies installed."

# -------------------------------------------
# run playwright tests (capture logs + exit code)
# -------------------------------------------
TEST_SUITE=${TEST_SUITE:-all}
JSON_OUTPUT="playwright-report/results.json"
PLAY_LOG="playwright.log"
TEST_EXIT_CODE=0

echo "▶️ Running Playwright tests for suite: ${TEST_SUITE}"
# Allow Playwright command to fail without exiting script; we'll capture exit code.
set +e

if [ "$TEST_SUITE" = "all" ]; then
  # timeout must wrap xvfb-run so it actually kills the test after timeout
  timeout 180s xvfb-run -a npx playwright test \
    --config=playwright.config.ts \
    --reporter=json,html \
    --output=playwright-report \
    2>&1 | tee "$PLAY_LOG"
  TEST_EXIT_CODE=${PIPESTATUS[0]:-0}
else
  # run either tests/<suite> folder or tests/<suite>.spec.js file
  if [ -d "tests/${TEST_SUITE}" ]; then
    timeout 180s xvfb-run -a npx playwright test "tests/${TEST_SUITE}" \
      --config=playwright.config.ts \
      --reporter=json,html \
      --output=playwright-report \
      2>&1 | tee "$PLAY_LOG"
    TEST_EXIT_CODE=${PIPESTATUS[0]:-0}
  else
    timeout 180s xvfb-run -a npx playwright test "tests/${TEST_SUITE}.spec.js" \
      --config=playwright.config.ts \
      --reporter=json,html \
      --output=playwright-report \
      2>&1 | tee "$PLAY_LOG"
    TEST_EXIT_CODE=${PIPESTATUS[0]:-0}
  fi
fi

set -e
echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"
echo "📄 Last 40 lines of Playwright log:"
tail -n 40 "$PLAY_LOG" || true

# -------------------------------------------
# Reliable HTML detection & place root index.html
# -------------------------------------------
echo "🔍 Scanning for real Playwright HTML report..."
REPORT_ROOT="playwright-report/index.html"
REAL_REPORT=""

# prefer suite-specific index/report paths
if [ -d "playwright-report/${TEST_SUITE}" ]; then
  if [ -f "playwright-report/${TEST_SUITE}/index.html" ]; then
    REAL_REPORT=$(readlink -f "playwright-report/${TEST_SUITE}/index.html")
  elif [ -f "playwright-report/${TEST_SUITE}/report.html" ]; then
    REAL_REPORT=$(readlink -f "playwright-report/${TEST_SUITE}/report.html")
  fi
fi

# common places
if [ -z "$REAL_REPORT" ] && [ -f "playwright-report/index.html" ]; then
  REAL_REPORT=$(readlink -f "playwright-report/index.html")
fi

if [ -z "$REAL_REPORT" ] && [ -f "playwright-report/html/index.html" ]; then
  REAL_REPORT=$(readlink -f "playwright-report/html/index.html")
fi

if [ -z "$REAL_REPORT" ]; then
  REAL_REPORT=$(find playwright-report -type f -name "index.html" | head -n 1 || true)
fi

if [ -z "$REAL_REPORT" ]; then
  REAL_REPORT=$(find playwright-report -type f -name "report.html" | head -n 1 || true)
fi

# fallback placeholder if still nothing
if [ -z "$REAL_REPORT" ]; then
  echo "⚠️ No actual HTML report found → creating fallback placeholder"
  cat > "$REPORT_ROOT" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>No HTML report generated</title></head>
<body><h2>No HTML report generated</h2><pre>Playwright did not produce an HTML report for this run. See playwright.log for details.</pre></body></html>
HTML
else
  echo "📄 Using real report: $REAL_REPORT"
  # copy the real report to root index.html so email + S3 always use a root index.html
  cp "$REAL_REPORT" "$REPORT_ROOT"
fi

# -------------------------------------------
# Ensure JSON exists
# -------------------------------------------
if [ ! -s "$JSON_OUTPUT" ]; then
  echo "⚠️ JSON missing → creating fallback JSON"
  echo '{"suites":[]}' > "$JSON_OUTPUT"
fi

# -------------------------------------------
# Determine test status and duration
# -------------------------------------------
if [ "$TEST_EXIT_CODE" -ne 0 ]; then
  TEST_STATUS="Failed"
else
  TEST_STATUS="Passed"
fi
export TEST_STATUS

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
export TEST_DURATION="${DURATION}s"
echo "⏱ Duration: $TEST_DURATION  Status: $TEST_STATUS"

# -------------------------------------------
# Upload to S3 (if configured)
# -------------------------------------------
export REPORT_URL=""
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"
  echo "☁️ Uploading report to S3 → s3://${S3_BUCKET}/${S3_PATH}"

  # upload index.html root first so presign exists
  aws s3 cp "$REPORT_ROOT" "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "${AWS_REGION}" || true
  # upload full folder so assets (css/js) remain (if any)
  aws s3 cp playwright-report "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" --recursive --region "${AWS_REGION}" || true

  if aws s3 ls "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "${AWS_REGION}" >/dev/null 2>&1; then
    REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" --expires-in 86400 --region "${AWS_REGION}" 2>/dev/null || true)
    export REPORT_URL
    echo "🔗 Report URL: $REPORT_URL"
  else
    echo "❌ index.html not found in S3 after upload"
  fi
else
  echo "⚠️ S3 upload skipped (S3_BUCKET or AWS_REGION not set)"
fi

# small wait so S3 is consistent + files flushed
echo "⏳ Waiting 5 seconds for flush/consistency..."
sleep 5

# -------------------------------------------
# Send Email (calls your send_report.js)
# -------------------------------------------
echo "📧 Sending report email (send_report.js uses REPORT_URL, TEST_STATUS, TEST_DURATION)..."
# Node file should use process.env.* to pick up REPORT_URL etc.
node send_report.js || echo "⚠️ send_report.js failed (email not sent)"

# -------------------------------------------
# Cleanup: kill playwright processes then stop container (best-effort)
# -------------------------------------------
pkill -f "playwright" || true

if [ -f /proc/1/cpuset ]; then
  CID=$(basename "$(cat /proc/1/cpuset)" 2>/dev/null || true)
  if [ -n "$CID" ]; then
    echo "🛑 Stopping container ${CID} via docker socket (best-effort)"
    curl --unix-socket /var/run/docker.sock -s -X POST "http:/v1.41/containers/${CID}/stop" || true
  fi
fi

echo "✅ Finished. Suite=${TEST_SUITE} Status=${TEST_STATUS} Duration=${TEST_DURATION}"
exit "$TEST_EXIT_CODE"
