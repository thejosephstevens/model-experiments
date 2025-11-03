#!/bin/bash
# =============================================================================
# Dataset Download Command Validation Script
# =============================================================================
# This script tests and validates the `dataset download` subcommand with
# various scenarios including:
# - Valid commands with all required parameters
# - Optional parameters
# - Error handling for missing/invalid parameters
# - Help text validation
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
TEST_OUTPUT_DIR="./test_downloads"
TEST_CACHE_DIR="./test_cache"

# Helper functions
print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_test() {
    echo -e "${YELLOW}Test $1:${NC} $2"
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_success() {
    echo -e "${GREEN}✓ PASSED${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo ""
}

print_failure() {
    echo -e "${RED}✗ FAILED${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Cleanup function
cleanup() {
    print_info "Cleaning up test directories..."
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_CACHE_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# =============================================================================
# Start Testing
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Dataset Download Command Validation Suite              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Help Text Validation
# =============================================================================
print_header "Test Suite 1: Help Text Validation"

print_test "1.1" "Check dataset download help displays correctly"
if uv run model-experiments dataset download --help > /dev/null 2>&1; then
    OUTPUT=$(uv run model-experiments dataset download --help 2>&1)
    if echo "$OUTPUT" | grep -qi "Download a dataset" && \
       echo "$OUTPUT" | grep -q "name" && \
       echo "$OUTPUT" | grep -q "output-dir" && \
       echo "$OUTPUT" | grep -q "max-samples" && \
       echo "$OUTPUT" | grep -q "cache-dir"; then
        print_success "Help text displays all required options"
    else
        print_failure "Help text missing expected content"
    fi
else
    print_failure "Help command failed to execute"
fi

# =============================================================================
# Test 2: Required Parameters Validation
# =============================================================================
print_header "Test Suite 2: Required Parameters Validation"

print_test "2.1" "Verify command fails without --name parameter"
if ! uv run model-experiments dataset download --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --name parameter"
else
    print_success "Command correctly requires --name parameter"
fi

print_test "2.2" "Verify command fails without --output-dir parameter"
if ! uv run model-experiments dataset download --name imdb 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --output-dir parameter"
else
    print_success "Command correctly requires --output-dir parameter"
fi

# =============================================================================
# Test 3: Valid Command Execution
# =============================================================================
print_header "Test Suite 3: Valid Command Execution"

print_test "3.1" "Execute with minimal required parameters"
mkdir -p "$TEST_OUTPUT_DIR"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR"; then
    print_success "Command executed successfully with required parameters"
else
    print_failure "Command failed with required parameters"
fi

print_test "3.2" "Execute with --max-samples option"
if uv run model-experiments dataset download \
    --name "ag_news" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 100; then
    print_success "Command executed successfully with --max-samples option"
else
    print_failure "Command failed with --max-samples option"
fi

print_test "3.3" "Execute with --cache-dir option"
mkdir -p "$TEST_CACHE_DIR"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --cache-dir "$TEST_CACHE_DIR"; then
    print_success "Command executed successfully with --cache-dir option"
else
    print_failure "Command failed with --cache-dir option"
fi

print_test "3.4" "Execute with all parameters"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 500 \
    --cache-dir "$TEST_CACHE_DIR"; then
    print_success "Command executed successfully with all parameters"
else
    print_failure "Command failed with all parameters"
fi

# =============================================================================
# Test 4: Output Validation
# =============================================================================
print_header "Test Suite 4: Output Validation"

print_test "4.1" "Verify output contains dataset name"
OUTPUT=$(uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "imdb"; then
    print_success "Output contains dataset name"
else
    print_failure "Output missing dataset name"
fi

print_test "4.2" "Verify output contains output directory"
OUTPUT=$(uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1)
# Extract basename to handle Path normalization (./test_downloads -> test_downloads)
DIR_BASENAME=$(basename "$TEST_OUTPUT_DIR")
if echo "$OUTPUT" | grep -qi "output.*directory" && echo "$OUTPUT" | grep -q "$DIR_BASENAME"; then
    print_success "Output contains output directory path"
else
    print_failure "Output missing output directory path"
fi

print_test "4.3" "Verify output shows max-samples when specified"
OUTPUT=$(uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 1000 2>&1)
if echo "$OUTPUT" | grep -q "1000"; then
    print_success "Output displays max-samples value"
else
    print_failure "Output missing max-samples value"
fi

print_test "4.4" "Verify successful download completion"
OUTPUT=$(uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 10 2>&1)
if echo "$OUTPUT" | grep -qi "downloaded successfully" && echo "$OUTPUT" | grep -qi "saved to"; then
    print_success "Download completed successfully"
else
    print_failure "Download did not complete successfully"
fi

# =============================================================================
# Test 5: Different Dataset Names
# =============================================================================
print_header "Test Suite 5: Different Dataset Names"

DATASETS=("imdb" "ag_news" "yelp_polarity" "squad" "rotten_tomatoes")

for dataset in "${DATASETS[@]}"; do
    print_test "5.x" "Test with dataset: $dataset"
    if uv run model-experiments dataset download \
        --name "$dataset" \
        --output-dir "$TEST_OUTPUT_DIR/$dataset"; then
        print_success "Command accepted dataset: $dataset"
    else
        print_failure "Command failed for dataset: $dataset"
    fi
done

# =============================================================================
# Test 6: Edge Cases and Special Values
# =============================================================================
print_header "Test Suite 6: Edge Cases and Special Values"

print_test "6.1" "Test with max-samples = 1"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 1; then
    print_success "Command accepts max-samples = 1"
else
    print_failure "Command failed with max-samples = 1"
fi

print_test "6.2" "Test with very large max-samples value"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR" \
    --max-samples 1000000; then
    print_success "Command accepts large max-samples value"
else
    print_failure "Command failed with large max-samples value"
fi

print_test "6.3" "Test with nested output directory path"
if uv run model-experiments dataset download \
    --name "imdb" \
    --output-dir "$TEST_OUTPUT_DIR/nested/path/to/data"; then
    print_success "Command accepts nested directory path"
else
    print_failure "Command failed with nested directory path"
fi

# =============================================================================
# Test Results Summary
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Test Results Summary                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests Run:    $TESTS_RUN"
echo -e "${GREEN}Tests Passed:       $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed:       $TESTS_FAILED${NC}"
echo ""

# Calculate pass rate
if [ $TESTS_RUN -gt 0 ]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED/$TESTS_RUN)*100}")
    echo "Pass Rate:          $PASS_RATE%"
fi

echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

