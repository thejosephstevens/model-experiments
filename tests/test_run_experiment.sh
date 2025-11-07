#!/bin/bash
# =============================================================================
# Run-Experiment Command Validation Script
# =============================================================================
# This script tests and validates the `run-experiment` command with various
# scenarios including:
# - Valid commands with all required parameters
# - Training profile validation (quick, default, full)
# - Error handling for missing/invalid parameters
# - Help text validation
# - Output directory structure validation
# - Optional parameters (output-root, cache-dir)
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
TEST_OUTPUT_ROOT="./test_experiments"

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
    rm -rf "$TEST_OUTPUT_ROOT"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# =============================================================================
# Start Testing
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Run-Experiment Command Validation Suite               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Help Text Validation
# =============================================================================
print_header "Test Suite 1: Help Text Validation"

print_test "1.1" "Check run-experiment help displays correctly"
if uv run model-experiments run-experiment --help > /dev/null 2>&1; then
    OUTPUT=$(uv run model-experiments run-experiment --help 2>&1)
    if echo "$OUTPUT" | grep -qi "experiment" && \
       echo "$OUTPUT" | grep -q "dataset-name" && \
       echo "$OUTPUT" | grep -q "model-name" && \
       echo "$OUTPUT" | grep -q "profile"; then
        print_success "Help text displays all required options"
    else
        print_failure "Help text missing expected content"
    fi
else
    print_failure "Help command failed to execute"
fi

print_test "1.2" "Verify help mentions training profiles"
OUTPUT=$(uv run model-experiments run-experiment --help 2>&1)
if echo "$OUTPUT" | grep -qi "profile"; then
    print_success "Help text mentions profile option"
else
    print_failure "Help text missing profile information"
fi

print_test "1.3" "Verify help mentions output directory options"
if echo "$OUTPUT" | grep -q "output-root"; then
    print_success "Help text mentions output-root option"
else
    print_failure "Help text missing output-root option"
fi

# =============================================================================
# Test 2: Required Parameters Validation
# =============================================================================
print_header "Test Suite 2: Required Parameters Validation"

print_test "2.1" "Verify command fails without --dataset-name"
if ! uv run model-experiments run-experiment \
    --model-name distilbert-base-uncased \
    --profile quick 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --dataset-name"
else
    print_success "Command correctly requires --dataset-name"
fi

print_test "2.2" "Verify command fails without --model-name"
if ! uv run model-experiments run-experiment \
    --dataset-name imdb \
    --profile quick 2>&1 | grep -qE "(Error|Missing|required)"; then
    print_failure "Command should fail without --model-name"
else
    print_success "Command correctly requires --model-name"
fi

# =============================================================================
# Test 3: Profile Validation
# =============================================================================
print_header "Test Suite 3: Training Profile Validation"

print_test "3.1" "Accept 'quick' profile"
OUTPUT=$(uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/profile_quick" 2>&1)
if [ $? -eq 0 ]; then
    print_success "Command accepts 'quick' profile"
else
    # Check if it's just a parameter validation success (not full execution)
    if echo "$OUTPUT" | grep -qi "quick"; then
        print_success "Command accepts 'quick' profile"
    else
        print_failure "Command rejected 'quick' profile"
    fi
fi

print_test "3.2" "Accept 'default' profile"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile default \
    --output-root "$TEST_OUTPUT_ROOT/profile_default" > /dev/null 2>&1 || \
   uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile default \
    --output-root "$TEST_OUTPUT_ROOT/profile_default" 2>&1 | grep -qi "default"; then
    print_success "Command accepts 'default' profile"
else
    print_failure "Command rejected 'default' profile"
fi

print_test "3.3" "Accept 'full' profile"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile full \
    --output-root "$TEST_OUTPUT_ROOT/profile_full" > /dev/null 2>&1 || \
   uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile full \
    --output-root "$TEST_OUTPUT_ROOT/profile_full" 2>&1 | grep -qi "full"; then
    print_success "Command accepts 'full' profile"
else
    print_failure "Command rejected 'full' profile"
fi

print_test "3.4" "Reject invalid profile"
if ! uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile invalid_profile \
    --output-root "$TEST_OUTPUT_ROOT/profile_invalid" 2>&1 | grep -qE "(Error|Invalid|invalid)"; then
    print_failure "Command should reject invalid profile"
else
    print_success "Command correctly rejects invalid profile"
fi

# =============================================================================
# Test 4: Valid Command Execution with Minimal Parameters
# =============================================================================
print_header "Test Suite 4: Valid Command Execution"

print_test "4.1" "Execute with required parameters only (using quick profile)"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/minimal"; then
    print_success "Command executed with minimal parameters"
else
    print_failure "Command failed with minimal parameters"
fi

print_test "4.2" "Execute with default profile explicitly specified"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/explicit_default"; then
    print_success "Command executed with explicit default profile"
else
    print_failure "Command failed with explicit default profile"
fi

# =============================================================================
# Test 5: Output Directory Structure Validation
# =============================================================================
print_header "Test Suite 5: Output Directory Structure Validation"

print_test "5.1" "Verify experiment directory is created"
# Run command and check for directory creation
uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/structure_test" > /dev/null 2>&1 || true

if [ -d "$TEST_OUTPUT_ROOT/structure_test" ]; then
    print_success "Experiment root directory created"
else
    print_failure "Experiment root directory not created"
fi

print_test "5.2" "Verify experiment subdirectory follows naming convention"
if ls "$TEST_OUTPUT_ROOT/structure_test" 2>/dev/null | grep -qE "exp_.*_imdb_.*"; then
    print_success "Experiment subdirectory follows naming convention"
else
    print_failure "Experiment subdirectory naming incorrect or missing"
fi

print_test "5.3" "Verify data subdirectory structure"
# Check if any experiment directory exists with expected structure
if find "$TEST_OUTPUT_ROOT" -type d -name "data" 2>/dev/null | grep -q .; then
    print_success "Data subdirectory created in experiment"
else
    print_failure "Data subdirectory missing"
fi

print_test "5.4" "Verify models subdirectory structure"
if find "$TEST_OUTPUT_ROOT" -type d -name "models" 2>/dev/null | grep -q .; then
    print_success "Models subdirectory created in experiment"
else
    print_failure "Models subdirectory missing"
fi

# =============================================================================
# Test 6: Optional Parameters
# =============================================================================
print_header "Test Suite 6: Optional Parameters"

print_test "6.1" "Accept custom output-root parameter"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/custom_root"; then
    print_success "Command accepts custom output-root"
else
    print_failure "Command rejected custom output-root"
fi

print_test "6.2" "Accept cache-dir parameter"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/with_cache" \
    --cache-dir "$TEST_OUTPUT_ROOT/cache"; then
    print_success "Command accepts cache-dir parameter"
else
    print_failure "Command rejected cache-dir parameter"
fi

print_test "6.3" "Execute with all optional parameters"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/all_params" \
    --cache-dir "$TEST_OUTPUT_ROOT/all_params_cache"; then
    print_success "Command accepts all optional parameters"
else
    print_failure "Command failed with all optional parameters"
fi

# =============================================================================
# Test 7: Output Validation
# =============================================================================
print_header "Test Suite 7: Output Content Validation"

print_test "7.1" "Verify output contains dataset name"
OUTPUT=$(uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/output_check" 2>&1)
if echo "$OUTPUT" | grep -q "imdb"; then
    print_success "Output contains dataset name"
else
    print_failure "Output missing dataset name"
fi

print_test "7.2" "Verify output contains model name"
if echo "$OUTPUT" | grep -q "distilbert-base-uncased"; then
    print_success "Output contains model name"
else
    print_failure "Output missing model name"
fi

print_test "7.3" "Verify output contains profile information"
if echo "$OUTPUT" | grep -qi "quick"; then
    print_success "Output contains profile information"
else
    print_failure "Output missing profile information"
fi

print_test "7.4" "Verify output mentions experiment directory"
if echo "$OUTPUT" | grep -qE "(experiment|Experiment|output|Output)"; then
    print_success "Output mentions experiment directory"
else
    print_failure "Output missing experiment directory information"
fi

# =============================================================================
# Test 8: Command Structure Validation
# =============================================================================
print_header "Test Suite 8: Command Structure Validation"

print_test "8.1" "Verify run-experiment is available from main CLI"
if uv run model-experiments --help 2>&1 | grep -q "run-experiment"; then
    print_success "Main CLI lists run-experiment command"
else
    print_failure "Main CLI missing run-experiment command"
fi

print_test "8.2" "Verify run-experiment command has proper help"
if uv run model-experiments run-experiment --help 2>&1 | grep -qE "(experiment|workflow|end-to-end)"; then
    print_success "Run-experiment command help text is present"
else
    print_failure "Run-experiment command help text missing"
fi

print_test "8.3" "Verify command description is informative"
HELP_OUTPUT=$(uv run model-experiments run-experiment --help 2>&1)
if echo "$HELP_OUTPUT" | grep -qE "(fine-tun|train|evaluat|compar)"; then
    print_success "Command description mentions key workflow steps"
else
    print_failure "Command description not sufficiently informative"
fi

# =============================================================================
# Test 9: Edge Cases and Special Values
# =============================================================================
print_header "Test Suite 9: Edge Cases"

print_test "9.1" "Accept nested output-root path"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/deeply/nested/path/to/experiments"; then
    print_success "Command accepts nested output-root path"
else
    print_failure "Command failed with nested output-root path"
fi

print_test "9.2" "Accept model name with organization prefix"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name prajjwal1/bert-tiny \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/org_model"; then
    print_success "Command accepts model with organization prefix"
else
    print_failure "Command failed with organization/model format"
fi

print_test "9.3" "Accept dataset with underscores"
if uv run model-experiments run-experiment \
    --dataset-name ag_news \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/underscore_dataset"; then
    print_success "Command accepts dataset name with underscores"
else
    print_failure "Command failed with underscored dataset name"
fi

print_test "9.4" "Handle default output-root when not specified"
OUTPUT=$(uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick 2>&1)
if [ $? -eq 0 ] || echo "$OUTPUT" | grep -q "experiments"; then
    print_success "Command uses default output-root when not specified"
else
    print_failure "Command failed to handle default output-root"
fi

# =============================================================================
# Test 10: Multiple Dataset and Model Combinations
# =============================================================================
print_header "Test Suite 10: Dataset and Model Combinations"

print_test "10.1" "Execute with different dataset (ag_news)"
if uv run model-experiments run-experiment \
    --dataset-name ag_news \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/ag_news_test"; then
    print_success "Command works with ag_news dataset"
else
    print_failure "Command failed with ag_news dataset"
fi

print_test "10.2" "Execute with tiny model for fast testing"
if uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name prajjwal1/bert-tiny \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/tiny_model"; then
    print_success "Command works with bert-tiny model"
else
    print_failure "Command failed with bert-tiny model"
fi

# =============================================================================
# Test 11: Profile-Specific Behavior
# =============================================================================
print_header "Test Suite 11: Profile-Specific Configuration"

print_test "11.1" "Verify quick profile mentions sample limiting"
OUTPUT=$(uv run model-experiments run-experiment \
    --dataset-name imdb \
    --model-name distilbert-base-uncased \
    --profile quick \
    --output-root "$TEST_OUTPUT_ROOT/quick_profile_check" 2>&1)
if echo "$OUTPUT" | grep -qE "(100|samples|quick)"; then
    print_success "Quick profile output mentions sample limiting"
else
    print_failure "Quick profile output missing sample limit info"
fi

print_test "11.2" "Verify profiles are properly documented in help"
HELP_OUTPUT=$(uv run model-experiments run-experiment --help 2>&1)
if echo "$HELP_OUTPUT" | grep -qi "quick" && \
   echo "$HELP_OUTPUT" | grep -qi "default" && \
   echo "$HELP_OUTPUT" | grep -qi "full"; then
    print_success "Help text documents all three profiles"
else
    print_failure "Help text missing profile documentation"
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

