# Caching Implementation

## Overview

The `model download` and `dataset download` commands now include intelligent caching to avoid unnecessary re-downloads. This is especially useful when working with limited or unreliable internet connectivity.

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

## Force Re-download

Both commands support a `--force` flag to bypass the cache and force a fresh download:

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

## Benefits

1. **Faster iteration**: Instant access to previously downloaded models/datasets
2. **Bandwidth savings**: No need to re-download large files
3. **Offline work**: Use cached resources when internet is unavailable
4. **Hotel-friendly**: Perfect for working with limited/expensive internet

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
```

## Testing

A test script is provided to verify caching functionality:

```bash
./test_caching.sh
```

This script tests:
1. First model download (downloads)
2. Second model download (uses cache)
3. Force model re-download
4. First dataset download (downloads)
5. Second dataset download (uses cache)
6. Different max-samples (re-downloads)
7. Force dataset re-download

