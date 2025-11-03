#!/bin/bash
# =============================================================================
# Model Download Command Validation Script
# =============================================================================
# This script tests and validates the `model download` subcommand with
# various scenarios including:
# - Valid commands with all required parameters
# - Optional parameters
# - Error handling for missing/invalid parameters
# - Help text validation
# - Multiple HuggingFace model names
# - Edge cases (nested paths, special characters)
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
TEST_OUTPUT_DIR="./test_models"
TEST_CACHE_DIR="./test_model_cache"

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
echo "║       Model Download Command Validation Suite               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Help Text Validation
# =============================================================================
print_header "Test Suite 1: Help Text Validation"

print_test "1.1" "Check model download help displays correctly"
if uv run model-experiments model download --help > /dev/null 2>&1; then
    OUTPUT=$(uv run model-experiments model download --help 2>&1)
    if echo "$OUTPUT" | grep -qi "Download a pre-trained model" && \
       echo "$OUTPUT" | grep -q "name" && \
       echo "$OUTPUT" | grep -q "output-dir" && \
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
if ! uv run model-experiments model download --output-dir "$TEST_OUTPUT_DIR" 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --name parameter"
else
    print_success "Command correctly requires --name parameter"
fi

print_test "2.2" "Verify command fails without --output-dir parameter"
if ! uv run model-experiments model download --name "bert-base-uncased" 2>&1 | grep -qE "(Error|Missing|required)"; then
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
if uv run model-experiments model download \
    --name "distilbert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/model1"; then
    print_success "Command executed successfully with required parameters"
else
    print_failure "Command failed with required parameters"
fi

print_test "3.2" "Execute with --cache-dir option"
mkdir -p "$TEST_CACHE_DIR"
if uv run model-experiments model download \
    --name "bert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/model2" \
    --cache-dir "$TEST_CACHE_DIR"; then
    print_success "Command executed successfully with --cache-dir option"
else
    print_failure "Command failed with --cache-dir option"
fi

print_test "3.3" "Execute with all parameters"
if uv run model-experiments model download \
    --name "distilbert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/model3" \
    --cache-dir "$TEST_CACHE_DIR"; then
    print_success "Command executed successfully with all parameters"
else
    print_failure "Command failed with all parameters"
fi

# =============================================================================
# Test 4: Output Validation
# =============================================================================
print_header "Test Suite 4: Output Validation"

print_test "4.1" "Verify output contains model name"
OUTPUT=$(uv run model-experiments model download \
    --name "distilbert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/test" 2>&1)
if echo "$OUTPUT" | grep -q "distilbert-base-uncased"; then
    print_success "Output contains model name"
else
    print_failure "Output missing model name"
fi

print_test "4.2" "Verify output contains output directory"
OUTPUT=$(uv run model-experiments model download \
    --name "bert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/models/bert" 2>&1)
# Extract basename to handle Path normalization
DIR_BASENAME=$(basename "$TEST_OUTPUT_DIR")
if echo "$OUTPUT" | grep -qi "output.*directory"; then
    print_success "Output contains output directory reference"
else
    print_failure "Output missing output directory reference"
fi

print_test "4.3" "Verify output shows cache directory when specified"
OUTPUT=$(uv run model-experiments model download \
    --name "distilbert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/test2" \
    --cache-dir "$TEST_CACHE_DIR" 2>&1)
if echo "$OUTPUT" | grep -qi "cache"; then
    print_success "Output displays cache directory information"
else
    print_failure "Output missing cache directory information"
fi

# =============================================================================
# Test 5: Different Model Names
# =============================================================================
print_header "Test Suite 5: Different Model Names"

MODELS=("distilbert-base-uncased" "bert-base-uncased" "prajjwal1/bert-tiny" "roberta-base")

for model in "${MODELS[@]}"; do
    print_test "5.x" "Test with model: $model"
    if uv run model-experiments model download \
        --name "$model" \
        --output-dir "$TEST_OUTPUT_DIR/models/$(basename "$model")"; then
        print_success "Command accepted model: $model"
    else
        print_failure "Command failed for model: $model"
    fi
done

# =============================================================================
# Test 6: Edge Cases and Special Values
# =============================================================================
print_header "Test Suite 6: Edge Cases and Special Values"

print_test "6.1" "Test with nested output directory path"
if uv run model-experiments model download \
    --name "distilbert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/nested/path/to/models"; then
    print_success "Command accepts nested directory path"
else
    print_failure "Command failed with nested directory path"
fi

print_test "6.2" "Test with nested cache directory path"
if uv run model-experiments model download \
    --name "bert-base-uncased" \
    --output-dir "$TEST_OUTPUT_DIR/model_output" \
    --cache-dir "$TEST_CACHE_DIR/nested/cache/path"; then
    print_success "Command accepts nested cache directory path"
else
    print_failure "Command failed with nested cache directory path"
fi

print_test "6.3" "Test with hyphenated model name"
if uv run model-experiments model download \
    --name "distilbert-base-uncased-finetuned" \
    --output-dir "$TEST_OUTPUT_DIR/finetuned_model"; then
    print_success "Command accepts hyphenated model names"
else
    print_failure "Command failed with hyphenated model name"
fi

print_test "6.4" "Test with organization/model format"
if uv run model-experiments model download \
    --name "huggingface/bert-base" \
    --output-dir "$TEST_OUTPUT_DIR/org_model"; then
    print_success "Command accepts organization/model format"
else
    print_failure "Command failed with organization/model format"
fi

# =============================================================================
# Test 7: Command Structure Validation
# =============================================================================
print_header "Test Suite 7: Command Structure Validation"

print_test "7.1" "Verify model command group help"
if uv run model-experiments model --help 2>&1 | grep -q "download"; then
    print_success "Model command group lists download subcommand"
else
    print_failure "Model command group missing download subcommand"
fi

print_test "7.2" "Verify model download is available from main CLI"
if uv run model-experiments --help 2>&1 | grep -q "model"; then
    print_success "Main CLI lists model command group"
else
    print_failure "Main CLI missing model command group"
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
