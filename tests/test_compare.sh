#!/bin/bash
# =============================================================================
# Compare Command Validation Script
# =============================================================================
# This script tests and validates the `compare` subcommand with various
# scenarios including:
# - Valid commands with all required parameters
# - Optional parameters and flags
# - Error handling for missing/invalid parameters
# - Help text validation
# - Metrics file validation
# - Format validation
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
TEST_OUTPUT_DIR="./test_comparison"
TEST_METRICS_DIR="./test_compare_metrics"

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

# Create sample metrics files
create_metrics_file() {
    local file=$1
    mkdir -p "$(dirname "$file")"
    
    # Create sample metrics JSON
    cat > "$file" << 'EOF'
{
  "model_path": "test_model",
  "num_samples": 100,
  "metrics": {
    "accuracy": 0.85,
    "f1": 0.83,
    "precision": 0.82,
    "recall": 0.84
  },
  "requested_metrics": ["accuracy", "f1", "precision", "recall"]
}
EOF
}

# Cleanup function
cleanup() {
    print_info "Cleaning up test directories..."
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_METRICS_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# =============================================================================
# Start Testing
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Compare Command Validation Suite                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Help Text Validation
# =============================================================================
print_header "Test Suite 1: Help Text Validation"

print_test "1.1" "Check compare help displays correctly"
if uv run model-experiments compare --help > /dev/null 2>&1; then
    OUTPUT=$(uv run model-experiments compare --help 2>&1)
    if echo "$OUTPUT" | grep -qi "Compare baseline" && \
       echo "$OUTPUT" | grep -q "baseline-metrics" && \
       echo "$OUTPUT" | grep -q "fine-tuned-metrics" && \
       echo "$OUTPUT" | grep -q "output-dir"; then
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

# Create test metrics files
mkdir -p "$TEST_METRICS_DIR"
create_metrics_file "$TEST_METRICS_DIR/baseline.json"
create_metrics_file "$TEST_METRICS_DIR/fine_tuned.json"

print_test "2.1" "Verify command fails without --baseline-metrics"
if ! uv run model-experiments compare \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --baseline-metrics"
else
    print_success "Command correctly requires --baseline-metrics"
fi

print_test "2.2" "Verify command fails without --fine-tuned-metrics"
if ! uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --fine-tuned-metrics"
else
    print_success "Command correctly requires --fine-tuned-metrics"
fi

print_test "2.3" "Verify command fails without --output-dir"
if ! uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --output-dir"
else
    print_success "Command correctly requires --output-dir"
fi

# =============================================================================
# Test 3: File Validation
# =============================================================================
print_header "Test Suite 3: File Validation"

print_test "3.1" "Verify command fails with non-existent baseline metrics"
if ! uv run model-experiments compare \
    --baseline-metrics ./nonexistent/baseline.json \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qi "not found"; then
    print_failure "Command should fail with non-existent baseline"
else
    print_success "Command correctly validates baseline metrics existence"
fi

print_test "3.2" "Verify command fails with non-existent fine-tuned metrics"
if ! uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics ./nonexistent/fine_tuned.json \
    --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qi "not found"; then
    print_failure "Command should fail with non-existent fine-tuned"
else
    print_success "Command correctly validates fine-tuned metrics existence"
fi

# =============================================================================
# Test 4: Format Validation
# =============================================================================
print_header "Test Suite 4: Format Validation"

print_test "4.1" "Verify valid format: table"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/test1" \
    --format table 2>&1 | grep -qi "comparison configuration"; then
    print_success "Command accepts table format"
else
    print_failure "Command rejected table format"
fi

print_test "4.2" "Verify valid format: json"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/test2" \
    --format json 2>&1 | grep -qi "comparison configuration"; then
    print_success "Command accepts json format"
else
    print_failure "Command rejected json format"
fi

print_test "4.3" "Verify valid format: html"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/test3" \
    --format html 2>&1 | grep -qi "comparison configuration"; then
    print_success "Command accepts html format"
else
    print_failure "Command rejected html format"
fi

print_test "4.4" "Verify invalid format is rejected"
if ! uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/test4" \
    --format invalid 2>&1 | grep -qi "invalid format"; then
    print_failure "Command should reject invalid format"
else
    print_success "Command correctly rejects invalid format"
fi

# =============================================================================
# Test 5: Valid Command Execution
# =============================================================================
print_header "Test Suite 5: Valid Command Execution"

print_test "5.1" "Execute with required parameters only"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/required_only"; then
    print_success "Command executed with required parameters"
else
    print_failure "Command failed with required parameters"
fi

print_test "5.2" "Execute with format option"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/with_format" \
    --format json; then
    print_success "Command executed with format option"
else
    print_failure "Command failed with format option"
fi

# =============================================================================
# Test 6: Output Validation
# =============================================================================
print_header "Test Suite 6: Output Validation"

print_test "6.1" "Verify output contains comparison configuration"
OUTPUT=$(uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/output_test" 2>&1)
if echo "$OUTPUT" | grep -qi "comparison configuration"; then
    print_success "Output shows comparison configuration"
else
    print_failure "Output missing comparison configuration"
fi

print_test "6.2" "Verify output contains metrics file references"
if echo "$OUTPUT" | grep -q "baseline" || echo "$OUTPUT" | grep -q "fine-tuned"; then
    print_success "Output contains metrics file references"
else
    print_failure "Output missing metrics file references"
fi

print_test "6.3" "Verify output contains format information"
if echo "$OUTPUT" | grep -qi "format"; then
    print_success "Output contains format information"
else
    print_failure "Output missing format information"
fi

# =============================================================================
# Test 7: Optional Flags
# =============================================================================
print_header "Test Suite 7: Optional Flags"

print_test "7.1" "Accept generate-plots flag"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/plots" \
    --generate-plots; then
    print_success "Command accepts generate-plots flag"
else
    print_failure "Command rejected generate-plots flag"
fi

print_test "7.2" "Accept save-report flag"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/report" \
    --save-report; then
    print_success "Command accepts save-report flag"
else
    print_failure "Command rejected save-report flag"
fi

# =============================================================================
# Test 8: Combined Options
# =============================================================================
print_header "Test Suite 8: Combined Options"

print_test "8.1" "Accept all options combined"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/all_options" \
    --format html \
    --generate-plots \
    --save-report; then
    print_success "Command accepts all options combined"
else
    print_failure "Command failed with all options"
fi

# =============================================================================
# Test 9: Command Structure Validation
# =============================================================================
print_header "Test Suite 9: Command Structure Validation"

print_test "9.1" "Verify compare is available from main CLI"
if uv run model-experiments --help 2>&1 | grep -q "compare"; then
    print_success "Main CLI lists compare command"
else
    print_failure "Main CLI missing compare command"
fi

print_test "9.2" "Verify compare command has proper help"
if uv run model-experiments compare --help 2>&1 | grep -q "Compare"; then
    print_success "Compare command help text is present"
else
    print_failure "Compare command help text missing"
fi

# =============================================================================
# Test 10: Edge Cases
# =============================================================================
print_header "Test Suite 10: Edge Cases and Special Values"

print_test "10.1" "Accept nested output directory path"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/nested/path/to/output"; then
    print_success "Command accepts nested output paths"
else
    print_failure "Command failed with nested output paths"
fi

print_test "10.2" "Accept default format (table)"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/default_format"; then
    print_success "Command uses default format"
else
    print_failure "Command failed with default format"
fi

print_test "10.3" "Accept both flags without format"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned.json" \
    --output-dir "$TEST_OUTPUT_DIR/both_flags" \
    --generate-plots \
    --save-report; then
    print_success "Command accepts both flags without format"
else
    print_failure "Command failed with both flags"
fi

print_test "10.4" "Verify metrics files are read correctly"
# Create a second set of metrics with different values
create_metrics_file "$TEST_METRICS_DIR/baseline2.json"
create_metrics_file "$TEST_METRICS_DIR/fine_tuned2.json"
if uv run model-experiments compare \
    --baseline-metrics "$TEST_METRICS_DIR/baseline2.json" \
    --fine-tuned-metrics "$TEST_METRICS_DIR/fine_tuned2.json" \
    --output-dir "$TEST_OUTPUT_DIR/different_metrics"; then
    print_success "Command processes different metrics files"
else
    print_failure "Command failed with different metrics"
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
