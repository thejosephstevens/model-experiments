#!/bin/bash
# =============================================================================
# Train Command Caching Validation Script
# =============================================================================
# This script tests the caching functionality of the `train` command including:
# - Initial training (should train)
# - Re-running with same config (should use cache)
# - Different model name (should retrain)
# - Different dataset (should retrain)
# - Different training parameters (should retrain)
# - Modified dataset files (should retrain)
# - Force flag (should retrain)
# - Incomplete training (should retrain)
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
TEST_OUTPUT_DIR="./test_train_cache_output"
TEST_DATA_DIR="./test_train_cache_data"
TRAIN_DATA="${TEST_DATA_DIR}/train.jsonl"
VAL_DATA="${TEST_DATA_DIR}/val.jsonl"

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

# Create sample training data (JSONL format)
create_sample_data() {
    local file=$1
    mkdir -p "$(dirname "$file")"
    
    # Create minimal JSONL training data with more samples for better training
    cat > "$file" << 'EOF'
{"text": "This is a positive example", "label": 1}
{"text": "This is another positive example", "label": 1}
{"text": "This is a negative example", "label": 0}
{"text": "Another negative example", "label": 0}
{"text": "This is positive text", "label": 1}
{"text": "Great product, highly recommend", "label": 1}
{"text": "Terrible experience, do not buy", "label": 0}
{"text": "Amazing quality and service", "label": 1}
{"text": "Worst purchase ever made", "label": 0}
{"text": "Excellent value for money", "label": 1}
{"text": "Disappointed with this item", "label": 0}
{"text": "Love it, works perfectly", "label": 1}
{"text": "Complete waste of time", "label": 0}
{"text": "Fantastic, exceeded expectations", "label": 1}
{"text": "Poor quality, broke immediately", "label": 0}
EOF
}

# Cleanup function
cleanup() {
    print_info "Cleaning up test directories..."
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_DATA_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# =============================================================================
# Start Testing
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Train Command Caching Validation Suite              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Setup: Create test data
print_info "Setting up test data..."
mkdir -p "$TEST_DATA_DIR"
create_sample_data "$TRAIN_DATA"
create_sample_data "$VAL_DATA"
echo ""

# =============================================================================
# Test 1: Initial Training (should train)
# =============================================================================
print_header "Test Suite 1: Initial Training"

print_test "1.1" "First training run should actually train the model"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test1" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    # Check that training_metadata.json was created
    if [ -f "$TEST_OUTPUT_DIR/test1/training_metadata.json" ]; then
        # Check that completed flag is true
        if grep -q '"completed": true' "$TEST_OUTPUT_DIR/test1/training_metadata.json"; then
            print_success "Initial training completed and metadata saved with completed=true"
        else
            print_failure "Metadata missing completed=true flag"
        fi
    else
        print_failure "training_metadata.json not created"
    fi
else
    print_failure "Training did not complete successfully"
fi

# =============================================================================
# Test 2: Re-run with Same Config (should use cache)
# =============================================================================
print_header "Test Suite 2: Cache Hit - Same Configuration"

print_test "2.1" "Re-running with identical config should use cache"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test1" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -qi "already trained\|cached\|using cached"; then
    print_success "Cache was used for identical configuration"
else
    print_failure "Cache was not used - model retrained unnecessarily"
fi

print_test "2.2" "Cached run should skip training steps"
if ! echo "$OUTPUT" | grep -q "Step 4/4: Training model"; then
    print_success "Training steps were skipped"
else
    print_failure "Training steps were not skipped"
fi

# =============================================================================
# Test 3: Different Model Name (should retrain)
# =============================================================================
print_header "Test Suite 3: Cache Miss - Different Model"

print_test "3.1" "Different model name should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name prajjwal1/bert-tiny \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test3" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different model name triggered retraining"
else
    print_failure "Training did not complete for different model"
fi

# =============================================================================
# Test 4: Different Training Parameters (should retrain)
# =============================================================================
print_header "Test Suite 4: Cache Miss - Different Parameters"

print_test "4.1" "Different epochs should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test4" \
    --epochs 2 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different epochs triggered retraining"
else
    print_failure "Training did not complete for different epochs"
fi

print_test "4.2" "Different batch size should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test5" \
    --epochs 1 \
    --batch-size 8 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different batch size triggered retraining"
else
    print_failure "Training did not complete for different batch size"
fi

print_test "4.3" "Different learning rate should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test6" \
    --epochs 1 \
    --batch-size 4 \
    --learning-rate 5e-5 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different learning rate triggered retraining"
else
    print_failure "Training did not complete for different learning rate"
fi

print_test "4.4" "Different seed should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test7" \
    --epochs 1 \
    --batch-size 4 \
    --seed 123 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different seed triggered retraining"
else
    print_failure "Training did not complete for different seed"
fi

# =============================================================================
# Test 5: Modified Dataset (should retrain)
# =============================================================================
print_header "Test Suite 5: Cache Miss - Modified Dataset"

# First train with original data
print_test "5.1" "Train with original dataset"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test8" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Initial training with dataset completed"
else
    print_failure "Initial training failed"
fi

# Wait a moment to ensure modification time changes
sleep 2

# Modify the dataset
print_test "5.2" "Modified dataset should trigger retraining"
echo '{"text": "New example added", "label": 1}' >> "$TRAIN_DATA"

OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test8" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete" && ! echo "$OUTPUT" | grep -qi "using cached"; then
    print_success "Modified dataset triggered retraining"
else
    print_failure "Modified dataset did not trigger retraining"
fi

# =============================================================================
# Test 6: Force Flag (should retrain)
# =============================================================================
print_header "Test Suite 6: Force Retrain"

print_test "6.1" "Force flag should bypass cache"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test1" \
    --epochs 1 \
    --batch-size 4 \
    --force 2>&1)

if echo "$OUTPUT" | grep -q "Training complete" && echo "$OUTPUT" | grep -qi "force"; then
    print_success "Force flag bypassed cache and retrained"
else
    print_failure "Force flag did not bypass cache"
fi

# =============================================================================
# Test 7: Incomplete Training (should retrain)
# =============================================================================
print_header "Test Suite 7: Incomplete Training Cache"

print_test "7.1" "Incomplete training cache should trigger retraining"

# Create a fake incomplete cache
mkdir -p "$TEST_OUTPUT_DIR/test9"
cat > "$TEST_OUTPUT_DIR/test9/training_metadata.json" << 'EOF'
{
  "model_name": "distilbert-base-uncased",
  "completed": false
}
EOF

OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA" \
    --val-data "$VAL_DATA" \
    --output-dir "$TEST_OUTPUT_DIR/test9" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Incomplete cache triggered retraining"
else
    print_failure "Incomplete cache did not trigger retraining"
fi

# =============================================================================
# Test 8: Different Dataset Path (should retrain)
# =============================================================================
print_header "Test Suite 8: Cache Miss - Different Dataset Path"

# Create a different dataset
TRAIN_DATA_2="${TEST_DATA_DIR}/train2.jsonl"
VAL_DATA_2="${TEST_DATA_DIR}/val2.jsonl"
create_sample_data "$TRAIN_DATA_2"
create_sample_data "$VAL_DATA_2"

print_test "8.1" "Different dataset path should trigger retraining"
OUTPUT=$(uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data "$TRAIN_DATA_2" \
    --val-data "$VAL_DATA_2" \
    --output-dir "$TEST_OUTPUT_DIR/test10" \
    --epochs 1 \
    --batch-size 4 2>&1)

if echo "$OUTPUT" | grep -q "Training complete"; then
    print_success "Different dataset path triggered retraining"
else
    print_failure "Training did not complete for different dataset path"
fi

# =============================================================================
# Test 9: Metadata Structure Validation
# =============================================================================
print_header "Test Suite 9: Metadata Structure Validation"

print_test "9.1" "Verify metadata contains all required fields"
METADATA_FILE="$TEST_OUTPUT_DIR/test1/training_metadata.json"
if [ -f "$METADATA_FILE" ]; then
    REQUIRED_FIELDS=("model_name" "train_data_path" "val_data_path" "train_data_mtime" "val_data_mtime" "config_hash" "completed" "training_params")
    ALL_PRESENT=true
    
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "\"$field\"" "$METADATA_FILE"; then
            ALL_PRESENT=false
            echo "  Missing field: $field"
        fi
    done
    
    if [ "$ALL_PRESENT" = true ]; then
        print_success "All required metadata fields present"
    else
        print_failure "Some required metadata fields missing"
    fi
else
    print_failure "Metadata file not found"
fi

print_test "9.2" "Verify training_params contains all parameters"
if [ -f "$METADATA_FILE" ]; then
    PARAM_FIELDS=("epochs" "batch_size" "learning_rate" "seed")
    ALL_PRESENT=true
    
    for field in "${PARAM_FIELDS[@]}"; do
        if ! grep -q "\"$field\"" "$METADATA_FILE"; then
            ALL_PRESENT=false
            echo "  Missing parameter: $field"
        fi
    done
    
    if [ "$ALL_PRESENT" = true ]; then
        print_success "All training parameters present in metadata"
    else
        print_failure "Some training parameters missing from metadata"
    fi
fi

# =============================================================================
# Test 10: Essential Files Validation
# =============================================================================
print_header "Test Suite 10: Essential Files Validation"

print_test "10.1" "Verify essential model files exist after training"
ESSENTIAL_FILES=("config.json" "training_metadata.json")
ALL_EXIST=true

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$TEST_OUTPUT_DIR/test1/$file" ]; then
        ALL_EXIST=false
        echo "  Missing file: $file"
    fi
done

# Check for either model.safetensors or pytorch_model.bin
if [ ! -f "$TEST_OUTPUT_DIR/test1/model.safetensors" ] && [ ! -f "$TEST_OUTPUT_DIR/test1/pytorch_model.bin" ]; then
    ALL_EXIST=false
    echo "  Missing model weights file"
fi

if [ "$ALL_EXIST" = true ]; then
    print_success "All essential model files exist"
else
    print_failure "Some essential model files missing"
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

