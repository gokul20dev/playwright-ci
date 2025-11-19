#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error occurred on line $LINENO"' ERR

echo ""
echo "============== STARTING DEBUG PIPELINE =============="
echo ""

cd /workspace || exit 1

# >>> added - start time
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

run_pw() {
    echo "Running suite: $1"
    xvfb-run -a timeout 600s npx playwright test "$1" \
        --reporter=json,html \
        --config=playwright.config.ts \
        --output=playwright-report \
        | tee "$JSON_OUTPUT" || TEST_EXIT_CODE=$?
}

if [ "$TEST_SUITE" = "all" ]; then
    run_pw "tests"
elif [ -d "tests/${TEST_SUITE}" ]; then
    run_pw "tests/${TEST_SUITE}"
else
    run_pw "tests/${TEST_SUITE}.spec.js"
fi

echo "Playwright exit code = $TEST_EXIT_CODE"
echo "========================================"

echo ""
echo "🔧 FORCE-GENERATING HTML REPORT..."
echo "========================================"

npx playwright show-report --output=playwright-report || true

echo ""
echo "🔍 DEBUG: CHECKING WHAT FILES PLAYWRIGHT CREATED..."
ls -R playwright-report || true
echo ""

echo "========================================"
echo "🔍 FINDING HTML REPORT"
echo "========================================"

REAL_REPORT=""

if [ -f "playwright-report/index.html" ]; then
    REAL_REPORT="playwright-report/index.html"
fi

if [ -z "$REAL_REPORT" ]; then
    REAL_REPORT=$(find playwright-report -type f -name "index.html" | head -n 1 || true)
fi

if [ -z "$REAL_REPORT" ]; then
    echo "⚠️ No HTML report found even after forcing → creating fallback"
    REAL_REPORT="playwright-report/index.html"
    echo "<h2>No HTML report generated</h2>" > "$REAL_REPORT"
fi

echo "👉 FINAL REPORT = $REAL_REPORT"
cp "$REAL_REPORT" playwright-report/index.html || true

echo "========================================"
echo "☁️ DEBUG: STARTING S3 UPLOAD"
echo "========================================"

if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_REGION:-}" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    S3_PATH="${TEST_SUITE}/${TIMESTAMP}/"

    aws s3 cp "playwright-report/index.html" \
        "s3://${S3_BUCKET}/${S3_PATH}index.html" --region "$AWS_REGION" || true

    aws s3 cp playwright-report \
        "s3://${S3_BUCKET}/${S3_PATH}playwright-report/" \
        --recursive --region "$AWS_REGION" || true

    REPORT_URL=$(aws s3 presign "s3://${S3_BUCKET}/${S3_PATH}index.html" \
        --expires-in 86400 --region "$AWS_REGION" 2>/dev/null || true)

    export REPORT_URL
else
    export REPORT_URL=""
fi

# >>> added - end time + duration calculation
END_TIME=$(date +%s)
TEST_DURATION=$(( END_TIME - START_TIME ))
export TEST_DURATION

echo "========================================"
echo "📧 DEBUG: SENDING EMAIL..."
echo "========================================"

node send_report.js || echo "⚠️ EMAIL FAILED"

echo "========================================"
echo "🧹 CLEANUP"
echo "========================================"

pkill -f "playwright" || true

CID=$(basename "$(cat /proc/1/cpuset 2>/dev/null)" 2>/dev/null || true)
if [ -n "$CID" ]; then
    curl --unix-socket /var/run/docker.sock -s -X POST \
        "http:/v1.41/containers/$CID/stop" || true
fi

echo ""
echo "=============== DONE ==============="
echo ""
