# Usage Guide

This document explains how to use the Model Fine-Tuning Framework CLI.

## Quick Start

Run the quick demo script to see the full workflow in action:

```bash
./quick_demo.sh
```

This will:
- Download a small dataset (500 samples)
- Split it 90/10 for training/validation
- Download a tiny BERT model
- Fine-tune the model (2 epochs)
- Evaluate both base and fine-tuned models
- Generate a performance comparison report

## Full Demo

For a more comprehensive example with detailed configuration:

```bash
./demo_usage.sh
```

This demonstrates all available options and best practices.

## CLI Commands

### Dataset Commands

#### Download Dataset
```bash
uv run model-experiments dataset download \
    --name <dataset_name> \
    --output-dir <path> \
    [--max-samples <int>] \
    [--cache-dir <path>] \
    [--force]
```

**Arguments:**
- `--name`: HuggingFace dataset name (e.g., "imdb", "ag_news")
- `--output-dir`: Directory to save the dataset
- `--max-samples`: Optional limit on number of samples to download
- `--cache-dir`: Optional cache directory for HuggingFace datasets
- `--force`: Force re-download even if dataset already exists (bypasses cache)

**Caching:**
The command automatically caches downloaded datasets in the `--output-dir`. If you run the same command again with the same parameters, it will use the cached version instead of re-downloading. This is useful when working with limited internet connectivity.

**Example:**
```bash
# First download - fetches from HuggingFace
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000

# Second run - uses cached version (instant)
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000

# Force re-download if needed
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000 \
    --force
```

### Model Commands

#### Download Model
```bash
uv run model-experiments model download \
    --name <model_name> \
    --output-dir <path> \
    [--cache-dir <path>] \
    [--force]
```

**Arguments:**
- `--name`: HuggingFace model name (e.g., "bert-base-uncased")
- `--output-dir`: Directory to save the model
- `--cache-dir`: Optional cache directory
- `--force`: Force re-download even if model already exists (bypasses cache)

**Caching:**
The command automatically caches downloaded models in the `--output-dir`. If you run the same command again with the same model name, it will use the cached version instead of re-downloading. This is useful when working with limited internet connectivity.

**Example:**
```bash
# First download - fetches from HuggingFace
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base

# Second run - uses cached version (instant)
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base

# Force re-download if needed
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base \
    --force
```

### Training

#### Train Model
```bash
uv run model-experiments train \
    --model-name <name> \
    --train-data <path> \
    --val-data <path> \
    --output-dir <path> \
    [--epochs <int>] \
    [--batch-size <int>] \
    [--learning-rate <float>] \
    [--warmup-steps <int>] \
    [--save-steps <int>] \
    [--logging-steps <int>] \
    [--eval-steps <int>] \
    [--max-length <int>] \
    [--gradient-accumulation-steps <int>] \
    [--fp16] \
    [--seed <int>]
```

**Arguments:**
- `--model-name`: Model to fine-tune
- `--train-data`: Path to training data (JSONL format)
- `--val-data`: Path to validation data (JSONL format)
- `--output-dir`: Directory to save fine-tuned model
- `--epochs`: Number of training epochs (default: 3)
- `--batch-size`: Batch size (default: 16)
- `--learning-rate`: Learning rate (default: 2e-5)
- `--warmup-steps`: Warmup steps (default: 100)
- `--save-steps`: Save checkpoint every N steps (default: 500)
- `--logging-steps`: Log metrics every N steps (default: 50)
- `--eval-steps`: Evaluate every N steps (default: 250)
- `--max-length`: Maximum sequence length (default: 512)
- `--gradient-accumulation-steps`: Gradient accumulation (default: 1)
- `--fp16`: Enable mixed precision training
- `--seed`: Random seed (default: 42)

**Example:**
```bash
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/splits/train.jsonl \
    --val-data ./data/splits/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3 \
    --batch-size 16 \
    --fp16
```

### Evaluation

#### Evaluate Model
```bash
uv run model-experiments evaluate \
    --model-path <path> \
    --test-data <path> \
    --output-file <path> \
    [--batch-size <int>] \
    [--max-length <int>] \
    [--metrics <metric1> <metric2> ...] \
    [--log-predictions <path>]
```

**Arguments:**
- `--model-path`: Path to model (base or fine-tuned)
- `--test-data`: Path to test/validation data (JSONL format)
- `--output-file`: Path to save metrics JSON
- `--batch-size`: Batch size for inference (default: 32)
- `--max-length`: Maximum sequence length (default: 512)
- `--metrics`: Metrics to compute (default: accuracy, f1, precision, recall)
- `--log-predictions`: Optional path to save predictions

**Example:**
```bash
uv run model-experiments evaluate \
    --model-path ./models/fine-tuned \
    --test-data ./data/splits/val.jsonl \
    --output-file ./metrics/results.json \
    --metrics accuracy f1 precision recall
```

### Comparison

#### Compare Models
```bash
uv run model-experiments compare \
    --baseline-metrics <path> \
    --fine-tuned-metrics <path> \
    --output-dir <path> \
    [--generate-plots] \
    [--format <table|json|html>] \
    [--save-report]
```

**Arguments:**
- `--baseline-metrics`: Path to base model metrics JSON
- `--fine-tuned-metrics`: Path to fine-tuned model metrics JSON
- `--output-dir`: Directory to save comparison results
- `--generate-plots`: Generate visualization charts
- `--format`: Output format (table, json, or html)
- `--save-report`: Save an HTML report

**Example:**
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison \
    --generate-plots \
    --save-report
```

## Example Workflows

### Text Classification (IMDB Sentiment)
```bash
# Download data
uv run model-experiments dataset download --name imdb --output-dir ./data

# Fine-tune model
uv run model-experiments model download --name distilbert-base-uncased --output-dir ./models/base
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data ./data/imdb/train.jsonl \
    --val-data ./data/imdb/validation.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3

# Evaluate and compare
uv run model-experiments evaluate --model-path ./models/base --test-data ./data/imdb/validation.jsonl --output-file ./metrics/base.json
uv run model-experiments evaluate --model-path ./models/fine-tuned --test-data ./data/imdb/validation.jsonl --output-file ./metrics/fine_tuned.json
uv run model-experiments compare --baseline-metrics ./metrics/base.json --fine-tuned-metrics ./metrics/fine_tuned.json --output-dir ./comparison
```

### News Classification (AG News)
```bash
# Download data
uv run model-experiments dataset download --name ag_news --output-dir ./data --max-samples 5000

# Fine-tune smaller model for speed
uv run model-experiments model download --name prajjwal1/bert-tiny --output-dir ./models/base
uv run model-experiments train \
    --model-name prajjwal1/bert-tiny \
    --train-data ./data/ag_news/train.jsonl \
    --val-data ./data/ag_news/validation.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 5 \
    --batch-size 32

# Evaluate and compare
uv run model-experiments evaluate --model-path ./models/base --test-data ./data/ag_news/validation.jsonl --output-file ./metrics/base.json
uv run model-experiments evaluate --model-path ./models/fine-tuned --test-data ./data/ag_news/validation.jsonl --output-file ./metrics/fine_tuned.json
uv run model-experiments compare --baseline-metrics ./metrics/base.json --fine-tuned-metrics ./metrics/fine_tuned.json --output-dir ./comparison --generate-plots
```

## Output Structure

After running a complete workflow, your output directory will look like:

```
outputs/
├── data/
│   ├── imdb/                    # Downloaded dataset
│   │   ├── train.jsonl
│   │   └── validation.jsonl
├── models/
│   ├── base/                    # Original base model
│   │   ├── config.json
│   │   ├── pytorch_model.bin
│   │   └── tokenizer/
│   └── fine-tuned/              # Fine-tuned model
│       ├── config.json
│       ├── pytorch_model.bin
│       ├── tokenizer/
│       └── logs/
│           └── training_log.jsonl
├── metrics/
│   ├── base_model_metrics.json      # Base model performance
│   └── fine_tuned_metrics.json      # Fine-tuned model performance
├── predictions/
│   ├── base_predictions.jsonl       # Base model predictions
│   └── fine_tuned_predictions.jsonl # Fine-tuned predictions
└── comparison/
    ├── report.html              # Visual comparison report
    ├── comparison.json          # Structured comparison data
    └── plots/
        ├── accuracy.png
        ├── f1_score.png
        └── confusion_matrix.png
```

## Tips

1. **Start Small**: Use `--max-samples` to test with a small dataset first
2. **Use Smaller Models**: For quick iterations, try `prajjwal1/bert-tiny` or `distilbert-base-uncased`
3. **Monitor Training**: Training logs are saved in `<output-dir>/logs/training_log.jsonl`
4. **Reproducibility**: Always set `--seed` for reproducible results
5. **GPU Usage**: Add `--fp16` flag to enable mixed precision training on GPU
6. **Memory Issues**: Reduce `--batch-size` or `--max-length` if you run out of memory

## Monitoring and Metrics

The framework automatically logs:
- **Training Metrics**: Loss, learning rate, training speed
- **Validation Metrics**: Accuracy, F1, precision, recall
- **System Metrics**: GPU usage, memory consumption, request latency
- **Predictions**: Individual predictions for error analysis

All metrics are saved in structured JSON format for easy analysis and visualization.

