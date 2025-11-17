# --- STEP 2: Run Playwright tests + JSON result ---
TEST_SUITE=${TEST_SUITE:-all}
PLAYWRIGHT_LOG="playwright_error.log"
JSON_REPORT="playwright-report/results.json"

echo "▶️ [$(date +"%T")] Running Playwright tests for suite: ${TEST_SUITE}"

# Ensure report folder exists
mkdir -p playwright-report

TEST_EXIT_CODE=0

if [ "$TEST_SUITE" = "all" ]; then
    xvfb-run -a timeout 180s npx playwright test \
        --config=playwright.config.js \
        --reporter=json \
        --output=playwright-report \
        > >(tee $PLAYWRIGHT_LOG) 2>&1 || TEST_EXIT_CODE=$?
else
    xvfb-run -a timeout 180s npx playwright test "tests/${TEST_SUITE}.spec.js" \
        --config=playwright.config.js \
        --reporter=json \
        --output=playwright-report \
        > >(tee $PLAYWRIGHT_LOG) 2>&1 || TEST_EXIT_CODE=$?
fi

echo "📌 Playwright Exit Code = $TEST_EXIT_CODE"
sleep 2

# --- Extract JSON result ---
if [ -f "$JSON_REPORT" ]; then
    export PASSED_COUNT=$(jq '.stats.expected' "$JSON_REPORT")
    export FAILED_COUNT=$(jq '.stats.unexpected' "$JSON_REPORT")
    export SKIPPED_COUNT=$(jq '.stats.skipped' "$JSON_REPORT")
    export TOTAL_COUNT=$(jq '.stats.total' "$JSON_REPORT")
else
    echo "⚠️ JSON report missing. Setting default values."
    export PASSED_COUNT=0
    export FAILED_COUNT=0
    export SKIPPED_COUNT=0
    export TOTAL_COUNT=0
fi

# Determine status
if [ "$FAILED_COUNT" -gt 0 ] || [ $TEST_EXIT_CODE -ne 0 ]; then
    export TEST_STATUS="Failed"
else
    export TEST_STATUS="Passed"
fi

echo "📊 Test Summary:"
echo "  ✔ Passed:  $PASSED_COUNT"
echo "  ❌ Failed:  $FAILED_COUNT"
echo "  ➖ Skipped: $SKIPPED_COUNT"
echo "  📦 Total:   $TOTAL_COUNT"
