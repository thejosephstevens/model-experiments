# Demo Script Fixes - Complete Summary

## Overview
The `demo_usage.sh` script was not working due to multiple issues across the codebase. All issues have been identified and fixed.

## Issues Fixed

### 1. Missing `accelerate` Package ✅
**Problem:** The `transformers` Trainer requires `accelerate>=0.26.0` but it was not in dependencies.

**Error:**
```
Using the `Trainer` with `PyTorch` requires `accelerate>=0.26.0`
```

**Fix:** Added `accelerate>=0.26.0` to `pyproject.toml` dependencies.

**File:** `pyproject.toml`

---

### 2. Dataset Sampling Not Balanced ✅
**Problem:** When limiting dataset samples with `--max-samples`, only the first N samples were taken, resulting in only one class (label 0) in the training data. This caused the model to use MSE loss (regression) instead of Cross Entropy loss (classification).

**Error:**
```
RuntimeError: mse_loss_out_mps: only defined for floating types
```

**Root Cause:** IMDB dataset is sorted by label, so first 1000 samples were all negative reviews (label=0). Model detected `num_labels=1` and switched to regression mode.

**Fix:** Added shuffling before selecting samples to ensure balanced classes.

**File:** `src/model_experiments/commands/dataset.py`
```python
# Shuffle before selecting to ensure balanced classes
split_data = split_data.shuffle(seed=42).select(range(max_samples))
```

---

### 3. Apple Silicon MPS Compatibility Issues ✅
**Problem:** PyTorch MPS backend has known issues with some operations used in transformer training.

**Errors:**
```
RuntimeError: mse_loss_out_mps: only defined for floating types
RuntimeError: Found dtype Long but expected Float
```

**Fix:** 
- Set environment variables to enable MPS fallback
- Disable MPS device usage in TrainingArguments
- Convert model to float32 explicitly

**File:** `src/model_experiments/commands/train.py`
```python
# At module level
os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
os.environ["PYTORCH_MPS_PREFER_METAL"] = "0"

# In training function
model = model.float()  # Ensure all parameters are float32
training_args = TrainingArguments(
    ...
    use_mps_device=False,  # Disable MPS
)
```

---

### 4. Model Download Missing Classification Head ✅
**Problem:** Model download used `AutoModel` instead of `AutoModelForSequenceClassification`, so the downloaded base model had no classification head for evaluation.

**Error:**
```
Some weights ... were not initialized from the model checkpoint
```

**Fix:** Changed model download to use `AutoModelForSequenceClassification`.

**File:** `src/model_experiments/commands/model.py`
```python
# Changed from AutoModel to AutoModelForSequenceClassification
model = AutoModelForSequenceClassification.from_pretrained(name, num_labels=2, **cache_kwargs)
```

---

### 5. Evaluation Pipeline Missing Truncation ✅
**Problem:** Some IMDB reviews are longer than 512 tokens, causing tensor size mismatch during evaluation.

**Error:**
```
The size of tensor a (632) must match the size of tensor b (512) at non-singleton dimension 1
```

**Fix:** Added truncation parameters to the text classification pipeline.

**File:** `src/model_experiments/commands/evaluate.py`
```python
classifier = pipeline(
    "text-classification",
    model=model,
    tokenizer=tokenizer,
    device=0 if __import__("torch").cuda.is_available() else -1,
    truncation=True,
    max_length=max_length,
)
```

---

### 6. Incorrect Metrics Syntax in Demo Script ✅
**Problem:** The evaluate command was passing multiple metrics as a single argument instead of separate `--metrics` flags.

**Error:**
```
Got unexpected extra arguments (f1 precision recall)
```

**Fix:** Updated demo script to use separate `--metrics` flags for each metric.

**File:** `demo_usage.sh`
```bash
# Before:
--metrics accuracy f1 precision recall

# After:
--metrics accuracy --metrics f1 --metrics precision --metrics recall
```

---

### 7. FP16 Flag Removed from Demo ✅
**Problem:** The demo script was using `--fp16` flag which doesn't work well on Apple Silicon MPS.

**Fix:** Removed the `--fp16` flag from the training command in the demo script.

**File:** `demo_usage.sh`

---

### 8. Problem Type Configuration ✅
**Problem:** Model wasn't explicitly configured for classification vs regression.

**Fix:** Added explicit `problem_type` configuration when loading model for training.

**File:** `src/model_experiments/commands/train.py`
```python
model = AutoModelForSequenceClassification.from_pretrained(
    model_name,
    num_labels=num_labels,
    problem_type="single_label_classification" if num_labels > 1 else None,
)
```

---

## Files Modified

1. `pyproject.toml` - Added `accelerate` dependency
2. `demo_usage.sh` - Fixed metrics syntax, removed `--fp16` flag
3. `src/model_experiments/commands/dataset.py` - Added shuffling for balanced sampling
4. `src/model_experiments/commands/train.py` - Fixed MPS issues, added device handling
5. `src/model_experiments/commands/model.py` - Changed to download classification models
6. `src/model_experiments/commands/evaluate.py` - Added truncation to pipeline

---

## Testing

The complete demo workflow now works successfully:

1. ✅ Dataset download (with balanced sampling)
2. ✅ Model download (with classification head)
3. ✅ Model training (3 epochs, ~86% accuracy)
4. ✅ Model evaluation (both base and fine-tuned)
5. ⚠️  Model comparison (not implemented, as documented)

### Expected Results

- Training completes in ~2 minutes on CPU
- Fine-tuned model achieves ~86% accuracy on test set
- Base (untrained) model achieves ~50% accuracy (random guessing)

---

## Usage

To run the complete demo:

```bash
./demo_usage.sh
```

Or run individual steps:

```bash
# 1. Download dataset
uv run model-experiments dataset download \\
    --name imdb \\
    --output-dir ./data \\
    --max-samples 1000

# 2. Download model
uv run model-experiments model download \\
    --name distilbert-base-uncased \\
    --output-dir ./outputs/models/base

# 3. Train model
uv run model-experiments train \\
    --model-name distilbert-base-uncased \\
    --train-data ./data/train/data.jsonl \\
    --val-data ./data/test/data.jsonl \\
    --output-dir ./outputs/models/fine-tuned \\
    --epochs 3

# 4. Evaluate model
uv run model-experiments evaluate \\
    --model-path ./outputs/models/fine-tuned \\
    --test-data ./data/test/data.jsonl \\
    --output-file ./outputs/metrics/metrics.json \\
    --metrics accuracy --metrics f1 --metrics precision --metrics recall
```

---

## Notes

- Training uses CPU by default on Apple Silicon due to MPS compatibility issues
- Dataset shuffling ensures balanced classes when limiting samples
- The compare command is not yet implemented (as noted in the demo script)

