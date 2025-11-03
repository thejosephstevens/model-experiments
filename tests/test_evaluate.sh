#!/bin/bash
# =============================================================================
# Evaluate Command Validation Script
# =============================================================================
# This script tests and validates the `evaluate` subcommand with various
# scenarios including:
# - Valid commands with all required parameters
# - Optional parameters
# - Error handling for missing/invalid parameters
# - Help text validation
# - Model and data file validation
# - Metrics configuration
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
TEST_OUTPUT_DIR="./test_evaluation"
TEST_DATA_DIR="./test_eval_data"
TEST_MODEL_DIR="./test_eval_model"

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

# Create sample test data (JSONL format)
create_sample_data() {
    local file=$1
    mkdir -p "$(dirname "$file")"
    
    # Create minimal JSONL test data
    cat > "$file" << 'EOF'
{"text": "This is a positive example", "label": 1}
{"text": "This is another positive example", "label": 1}
{"text": "This is a negative example", "label": 0}
{"text": "Another negative example", "label": 0}
{"text": "This is positive text", "label": 1}
EOF
}

# Create a mock model directory
create_mock_model() {
    local model_dir=$1
    mkdir -p "$model_dir"
    
    # Create minimal model files
    cat > "$model_dir/config.json" << 'EOF'
{
  "architectures": ["DistilBertForSequenceClassification"],
  "model_type": "distilbert",
  "num_labels": 2
}
EOF
    
    # Create tokenizer files
    cat > "$model_dir/tokenizer.json" << 'EOF'
{
  "type": "BertWordPiece",
  "vocab": {}
}
EOF
    
    touch "$model_dir/pytorch_model.bin"
}

# Cleanup function
cleanup() {
    print_info "Cleaning up test directories..."
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_DATA_DIR" "$TEST_MODEL_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# =============================================================================
# Start Testing
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Evaluate Command Validation Suite                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Help Text Validation
# =============================================================================
print_header "Test Suite 1: Help Text Validation"

print_test "1.1" "Check evaluate help displays correctly"
if uv run model-experiments evaluate --help > /dev/null 2>&1; then
    OUTPUT=$(uv run model-experiments evaluate --help 2>&1)
    if echo "$OUTPUT" | grep -qi "Evaluate model" && \
       echo "$OUTPUT" | grep -q "model-path" && \
       echo "$OUTPUT" | grep -q "test-data" && \
       echo "$OUTPUT" | grep -q "output-file" && \
       echo "$OUTPUT" | grep -q "metrics"; then
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

# Create test data and model
mkdir -p "$TEST_DATA_DIR"
create_sample_data "$TEST_DATA_DIR/test.jsonl"
create_mock_model "$TEST_MODEL_DIR"

print_test "2.1" "Verify command fails without --model-path"
if ! uv run model-experiments evaluate \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics.json" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --model-path"
else
    print_success "Command correctly requires --model-path"
fi

print_test "2.2" "Verify command fails without --test-data"
if ! uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --output-file "$TEST_OUTPUT_DIR/metrics.json" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --test-data"
else
    print_success "Command correctly requires --test-data"
fi

print_test "2.3" "Verify command fails without --output-file"
if ! uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --output-file"
else
    print_success "Command correctly requires --output-file"
fi

# =============================================================================
# Test 3: File Validation
# =============================================================================
print_header "Test Suite 3: File Validation"

print_test "3.1" "Verify command fails with non-existent model"
if ! uv run model-experiments evaluate \
    --model-path ./nonexistent/model \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics.json" 2>&1 | grep -qi "not found"; then
    print_failure "Command should fail with non-existent model"
else
    print_success "Command correctly validates model existence"
fi

print_test "3.2" "Verify command fails with non-existent test data"
if ! uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data ./nonexistent/test.jsonl \
    --output-file "$TEST_OUTPUT_DIR/metrics.json" 2>&1 | grep -qi "not found"; then
    print_failure "Command should fail with non-existent test data"
else
    print_success "Command correctly validates test data existence"
fi

# =============================================================================
# Test 4: Valid Command Execution
# =============================================================================
print_header "Test Suite 4: Valid Command Execution"

print_test "4.1" "Execute with required parameters only"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_default.json"; then
    print_success "Command executed with required parameters"
else
    print_failure "Command failed with required parameters"
fi

print_test "4.2" "Execute with custom batch size"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_batch.json" \
    --batch-size 8; then
    print_success "Command executed with custom batch size"
else
    print_failure "Command failed with custom batch size"
fi

print_test "4.3" "Execute with custom max length"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_maxlen.json" \
    --max-length 256; then
    print_success "Command executed with custom max length"
else
    print_failure "Command failed with custom max length"
fi

# =============================================================================
# Test 5: Output Validation
# =============================================================================
print_header "Test Suite 5: Output Validation"

print_test "5.1" "Verify output contains evaluation configuration"
OUTPUT=$(uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/output_test.json" 2>&1)
if echo "$OUTPUT" | grep -qi "evaluation configuration"; then
    print_success "Output shows evaluation configuration"
else
    print_failure "Output missing evaluation configuration"
fi

print_test "5.2" "Verify output contains model path"
if echo "$OUTPUT" | grep -q "model"; then
    print_success "Output contains model path reference"
else
    print_failure "Output missing model path reference"
fi

print_test "5.3" "Verify output contains metrics list"
if echo "$OUTPUT" | grep -qi "metrics" || echo "$OUTPUT" | grep -q "accuracy"; then
    print_success "Output contains metrics information"
else
    print_failure "Output missing metrics information"
fi

# =============================================================================
# Test 6: Metrics Configuration
# =============================================================================
print_header "Test Suite 6: Metrics Configuration"

print_test "6.1" "Accept accuracy metric"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_acc.json" \
    --metrics accuracy; then
    print_success "Command accepts accuracy metric"
else
    print_failure "Command rejected accuracy metric"
fi

print_test "6.2" "Accept f1 metric"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_f1.json" \
    --metrics f1; then
    print_success "Command accepts f1 metric"
else
    print_failure "Command rejected f1 metric"
fi

print_test "6.3" "Accept precision metric"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_prec.json" \
    --metrics precision; then
    print_success "Command accepts precision metric"
else
    print_failure "Command rejected precision metric"
fi

print_test "6.4" "Accept recall metric"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_rec.json" \
    --metrics recall; then
    print_success "Command accepts recall metric"
else
    print_failure "Command rejected recall metric"
fi

print_test "6.5" "Accept multiple metrics"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_multi.json" \
    --metrics accuracy \
    --metrics f1 \
    --metrics precision \
    --metrics recall; then
    print_success "Command accepts multiple metrics"
else
    print_failure "Command rejected multiple metrics"
fi

# =============================================================================
# Test 7: Optional Parameters
# =============================================================================
print_header "Test Suite 7: Optional Parameters"

print_test "7.1" "Accept log-predictions parameter"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_pred.json" \
    --log-predictions "$TEST_OUTPUT_DIR/predictions.jsonl"; then
    print_success "Command accepts log-predictions parameter"
else
    print_failure "Command rejected log-predictions parameter"
fi

# =============================================================================
# Test 8: Combined Parameters
# =============================================================================
print_header "Test Suite 8: Combined Parameters"

print_test "8.1" "Accept all parameters combined"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/metrics_all.json" \
    --batch-size 16 \
    --max-length 384 \
    --metrics accuracy \
    --metrics f1 \
    --metrics precision \
    --metrics recall \
    --log-predictions "$TEST_OUTPUT_DIR/all_predictions.jsonl"; then
    print_success "Command accepts all parameters combined"
else
    print_failure "Command failed with all parameters"
fi

# =============================================================================
# Test 9: Command Structure Validation
# =============================================================================
print_header "Test Suite 9: Command Structure Validation"

print_test "9.1" "Verify evaluate is available from main CLI"
if uv run model-experiments --help 2>&1 | grep -q "evaluate"; then
    print_success "Main CLI lists evaluate command"
else
    print_failure "Main CLI missing evaluate command"
fi

print_test "9.2" "Verify evaluate command has proper help"
if uv run model-experiments evaluate --help 2>&1 | grep -q "Evaluate"; then
    print_success "Evaluate command help text is present"
else
    print_failure "Evaluate command help text missing"
fi

# =============================================================================
# Test 10: Edge Cases
# =============================================================================
print_header "Test Suite 10: Edge Cases and Special Values"

print_test "10.1" "Accept small batch size"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/batch_1.json" \
    --batch-size 1; then
    print_success "Command accepts batch size of 1"
else
    print_failure "Command rejected batch size of 1"
fi

print_test "10.2" "Accept large batch size"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/batch_256.json" \
    --batch-size 256; then
    print_success "Command accepts large batch size"
else
    print_failure "Command rejected large batch size"
fi

print_test "10.3" "Accept small max length"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/len_128.json" \
    --max-length 128; then
    print_success "Command accepts max length of 128"
else
    print_failure "Command rejected max length of 128"
fi

print_test "10.4" "Accept nested output paths"
if uv run model-experiments evaluate \
    --model-path "$TEST_MODEL_DIR" \
    --test-data "$TEST_DATA_DIR/test.jsonl" \
    --output-file "$TEST_OUTPUT_DIR/nested/path/metrics.json"; then
    print_success "Command accepts nested output paths"
else
    print_failure "Command failed with nested output paths"
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
