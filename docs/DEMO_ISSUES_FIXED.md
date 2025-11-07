# Demo Script Issues - Fixed

## Summary
The `demo_usage.sh` script had several issues that prevented it from working correctly. These have been identified and fixed.

## Issues Found and Fixed

### 0. Transformers API Version Incompatibility ❌ → ✅
**Problem:** The training command was using an outdated parameter name from an older version of the `transformers` library.

**Error Message:**
```
✗ Error during training: TrainingArguments.__init__() got an unexpected keyword argument 'evaluation_strategy'
```

**Root Cause:** In newer versions of transformers (4.x+), the parameter `evaluation_strategy` was renamed to `eval_strategy`.

**Fix Applied:**
Changed line 246 in `src/model_experiments/commands/train.py`:
```python
# Before:
evaluation_strategy="steps",

# After:
eval_strategy="steps",
```

**File changed:** `src/model_experiments/commands/train.py` (line 246)

---

### 1. Dataset Path Mismatch ❌ → ✅
**Problem:** The dataset download command creates a different directory structure than what the script references.

**What the dataset download creates:**
```
./data/
  ├── train/
  │   └── data.jsonl
  ├── test/
  │   └── data.jsonl
  └── unsupervised/
      └── data.jsonl
```

**What the script was looking for:**
```
./data/imdb/train.jsonl          ❌
./data/imdb/validation.jsonl     ❌
```

**Fixed to:**
```
./data/train/data.jsonl          ✅
./data/test/data.jsonl           ✅
```

**Lines changed:** 73, 74, 102, 115

---

### 2. Wrong Split Name ❌ → ✅
**Problem:** The IMDB dataset has splits named `train`, `test`, and `unsupervised`, but the script referenced a `validation` split that doesn't exist.

**Before:**
- Training: `train` split ✅
- Validation: `validation` split ❌ (doesn't exist)

**After:**
- Training: `train` split ✅
- Validation/Testing: `test` split ✅

**Lines changed:** 73-74, 95, 102, 115

---

### 3. Compare Command Not Implemented ⚠️
**Problem:** The `compare` command in `src/model_experiments/commands/compare.py` only contains a TODO placeholder and doesn't actually perform any comparison.

**Fix Applied:**
- Commented out the `compare` command invocation
- Added a clear warning message explaining the limitation
- Updated the results summary to remove references to comparison reports
- Provided instructions for manually comparing metrics files

**Lines changed:** 131-143, 150-159

---

## Changes Made to demo_usage.sh

### Training Command (Lines 73-74)
```bash
# Before:
--train-data "$DATA_DIR/$DATASET_NAME/train.jsonl"
--val-data "$DATA_DIR/$DATASET_NAME/validation.jsonl"

# After:
--train-data "$DATA_DIR/train/data.jsonl"
--val-data "$DATA_DIR/test/data.jsonl"
```

### Evaluate Commands (Lines 102, 115)
```bash
# Before:
--test-data "$DATA_DIR/$DATASET_NAME/validation.jsonl"

# After:
--test-data "$DATA_DIR/test/data.jsonl"
```

### Compare Command (Lines 131-143)
```bash
# Before:
uv run model-experiments compare \
    --baseline-metrics "$OUTPUT_DIR/metrics/base_model_metrics.json" \
    --fine-tuned-metrics "$OUTPUT_DIR/metrics/fine_tuned_metrics.json" \
    --output-dir "$OUTPUT_DIR/comparison" \
    --generate-plots \
    --format table \
    --save-report

# After:
echo "⚠️  Note: The compare command is not yet fully implemented."
echo "    You can manually compare the metrics files:"
echo "    - $OUTPUT_DIR/metrics/base_model_metrics.json"
echo "    - $OUTPUT_DIR/metrics/fine_tuned_metrics.json"
echo ""
# [command commented out]
```

---

## How to Verify the Fix

Run the demo script:
```bash
./scripts/demo_usage.sh
```

The script should now:
1. ✅ Successfully download the IMDB dataset
2. ✅ Successfully download the base model
3. ✅ Successfully train the model using correct data paths
4. ✅ Successfully evaluate both models using correct data paths
5. ⚠️  Display a warning about the compare command (not implemented yet)

---

## Remaining Work

To fully complete the demo workflow, the `compare` command needs to be implemented in:
- `src/model_experiments/commands/compare.py`

This should:
- Load both metrics JSON files
- Calculate improvement percentages
- Generate comparison tables/charts
- Save an HTML report (if requested)

