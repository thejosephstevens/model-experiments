# Caching Implementation

## Overview

The `model download`, `dataset download`, and `train` commands now include intelligent caching to avoid unnecessary re-downloads and re-training. This is especially useful when working with limited or unreliable internet connectivity, and for faster iteration during model development.

## How It Works

### Model Download Caching

When you run `model-experiments model download`, the command:

1. **Checks for existing cache**: Looks for `model_metadata.json` in the output directory
2. **Validates cache**: Verifies that:
   - The cached model name matches the requested model
   - Essential files exist (`config.json`, model weights, tokenizer files)
3. **Uses cache or downloads**: 
   - If cache is valid → uses cached version (instant)
   - If cache is invalid/missing → downloads from HuggingFace

### Dataset Download Caching

When you run `model-experiments dataset download`, the command:

1. **Checks for existing cache**: Looks for `metadata.json` in the output directory
2. **Validates cache**: Verifies that:
   - The cached dataset name matches the requested dataset
   - The `--max-samples` parameter matches (if specified)
   - All expected split files exist (`data.jsonl` in each split directory)
3. **Uses cache or downloads**:
   - If cache is valid → uses cached version (instant)
   - If cache is invalid/missing → downloads from HuggingFace

### Train Command Caching

When you run `model-experiments train`, the command:

1. **Checks for existing cache**: Looks for `training_metadata.json` in the output directory
2. **Validates cache**: Verifies that:
   - Training completed successfully (`completed: true` flag)
   - Model name matches the requested model
   - Dataset file paths exist and modification times match
   - All training parameters match (epochs, batch_size, learning_rate, etc.)
   - Configuration hash matches
   - Essential model files exist (config.json, model weights, tokenizer files)
3. **Uses cache or trains**:
   - If cache is valid → uses cached trained model (instant)
   - If cache is invalid/missing → trains the model

## Cache Validation

The caching system performs several checks to ensure data integrity:

### Model Cache Validation
- Metadata file exists and is valid JSON
- Model name in metadata matches requested model
- Essential files present (`config.json`)

### Dataset Cache Validation
- Metadata file exists and is valid JSON
- Dataset name in metadata matches requested dataset
- Max samples parameter matches (if specified)
- All split directories exist with `data.jsonl` files

### Train Cache Validation
- Metadata file exists and is valid JSON
- Training completed successfully (completed flag is true)
- Model name in metadata matches requested model
- Dataset file paths exist and modification times match
- All training parameters match (epochs, batch_size, learning_rate, warmup_steps, save_steps, logging_steps, eval_steps, max_length, gradient_accumulation_steps, fp16, seed)
- Configuration hash matches
- Essential model files exist (config.json, model weights)

## Force Re-download / Re-training

All commands support a `--force` flag to bypass the cache and force a fresh operation:

```bash
# Force model re-download
uv run model-experiments model download \
    --name bert-base-uncased \
    --output-dir ./models/base \
    --force

# Force dataset re-download
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --force

# Force re-training
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./models/fine-tuned \
    --force
```

## Cache Invalidation

The cache is automatically invalidated and re-downloaded when:

### For Models
- Different model name is requested for the same output directory
- Essential files are missing (corrupted cache)
- Metadata file is corrupted or invalid
- `--force` flag is used

### For Datasets
- Different dataset name is requested for the same output directory
- Different `--max-samples` value is used
- Split files are missing (corrupted cache)
- Metadata file is corrupted or invalid
- `--force` flag is used

### For Training
- Different model name is requested
- Different dataset paths are provided
- Dataset files have been modified (modification time changed)
- Any training parameter has changed (epochs, batch_size, learning_rate, etc.)
- Training did not complete successfully (completed flag is false or missing)
- Essential model files are missing (corrupted cache)
- Metadata file is corrupted or invalid
- `--force` flag is used

## Benefits

1. **Faster iteration**: Instant access to previously downloaded models/datasets and trained models
2. **Time savings**: Skip lengthy training when configuration hasn't changed
3. **Bandwidth savings**: No need to re-download large files
4. **Offline work**: Use cached resources when internet is unavailable
5. **Reproducibility**: Ensures same configuration produces consistent results
6. **Hotel-friendly**: Perfect for working with limited/expensive internet

## Usage Examples

### Model Caching Example

```bash
# First download - fetches from HuggingFace (~30 seconds)
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base

# Second run - uses cache (instant)
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base
# Output: ℹ Model already downloaded and cached
#         Using cached model from ./models/base

# Force re-download if needed
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base \
    --force
```

### Dataset Caching Example

```bash
# First download - fetches from HuggingFace (~10 seconds)
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000

# Second run - uses cache (instant)
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000
# Output: ℹ Dataset already downloaded and cached
#         Using cached dataset from ./data
#         Splits: train, test, unsupervised
#         Total samples: 3000

# Different max-samples triggers re-download
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 2000
# Output: ⚠ Cache has different max_samples (1000 vs 2000), re-downloading...
```

### Train Caching Example

```bash
# First training - actually trains the model (takes several minutes)
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3 \
    --batch-size 16

# Second run - uses cache (instant)
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3 \
    --batch-size 16
# Output: ℹ Model already trained with this configuration
#         Using cached trained model from ./models/fine-tuned
#         Training samples: 25000
#         Validation samples: 25000
#         Epochs: 3
#         Use --force to re-train

# Different parameters trigger re-training
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 5 \
    --batch-size 16
# Output: ⚠ Training configuration changed, re-training...

# Force re-training even with same config
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3 \
    --batch-size 16 \
    --force
# Output: Force flag set, re-training even if cache exists...
```

## Implementation Details

### Files Used for Caching

**Models**:
- `model_metadata.json` - Contains model name, type, and cache info
- `config.json` - Model configuration (used for validation)
- Model weight files (`.bin`, `.safetensors`)
- Tokenizer files

**Datasets**:
- `metadata.json` - Contains dataset name, splits, sample counts
- `<split>/data.jsonl` - Dataset files for each split (train, test, etc.)

**Trained Models**:
- `training_metadata.json` - Contains training configuration, dataset info, and completion status
- `config.json` - Model configuration
- `model.safetensors` or `pytorch_model.bin` - Model weights
- Tokenizer files
- `logs/` - Training logs directory

### Cache Location

Caches are stored in the directories specified by `--output-dir`:

```
./models/base/           # Model cache
├── config.json
├── model_metadata.json
├── pytorch_model.bin
├── tokenizer_config.json
└── vocab.txt

./data/imdb/            # Dataset cache
├── metadata.json
├── train/
│   └── data.jsonl
├── test/
│   └── data.jsonl
└── unsupervised/
    └── data.jsonl

./models/fine-tuned/   # Trained model cache
├── config.json
├── training_metadata.json
├── model.safetensors
├── tokenizer_config.json
├── tokenizer.json
├── vocab.txt
└── logs/
    └── events.out.tfevents...
```

## Testing

Test scripts are provided to verify caching functionality:

### Download Caching Tests

```bash
./tests/test_caching.sh
```

This script tests:
1. First model download (downloads)
2. Second model download (uses cache)
3. Force model re-download
4. First dataset download (downloads)
5. Second dataset download (uses cache)
6. Different max-samples (re-downloads)
7. Force dataset re-download

### Train Caching Tests

```bash
./tests/test_train_caching.sh
```

This script tests:
1. Initial training (should train)
2. Re-running with same config (should use cache)
3. Different model name (should retrain)
4. Different dataset (should retrain)
5. Different training parameters (should retrain)
6. Modified dataset files (should retrain)
7. Force flag (should retrain)
8. Incomplete training (should retrain)
9. Metadata structure validation
10. Essential files validation

