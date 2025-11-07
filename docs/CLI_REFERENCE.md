# CLI Reference Card

Quick reference for the Model Fine-Tuning Framework CLI commands.

## Command Structure

All commands follow the pattern:
```bash
uv run model-experiments <command> <subcommand> [options]
```

## Commands Overview

| Command | Subcommand | Description |
|---------|-----------|-------------|
| `dataset` | `download` | Download datasets from HuggingFace |
| `model` | `download` | Download pre-trained models |
| `model` | `upload` | Upload models to HuggingFace Hub |
| `train` | - | Fine-tune a model on training data |
| `evaluate` | - | Evaluate model performance on test data |
| `compare` | - | Compare baseline vs fine-tuned model metrics |

---

## Quick Commands

### Minimal Workflow
```bash
# 1. Download dataset
uv run model-experiments dataset download --name imdb --output-dir ./data

# 2. Download model
uv run model-experiments model download --name bert-base-uncased \
    --output-dir ./models/base

# 3. Train model
uv run model-experiments train --model-name bert-base-uncased \
    --train-data ./data/imdb/train.jsonl \
    --val-data ./data/imdb/validation.jsonl \
    --output-dir ./models/fine-tuned

# 4. Evaluate base model
uv run model-experiments evaluate --model-path ./models/base \
    --test-data ./data/imdb/validation.jsonl \
    --output-file ./metrics/base.json

# 5. Evaluate fine-tuned model
uv run model-experiments evaluate --model-path ./models/fine-tuned \
    --test-data ./data/imdb/validation.jsonl \
    --output-file ./metrics/fine_tuned.json

# 6. Compare performance
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison
```

---

### `dataset download`
**Purpose:** Download datasets from HuggingFace Hub

**Required:**
- `--name` - Dataset name (e.g., "imdb", "ag_news")
- `--output-dir` - Where to save the dataset

**Optional:**
- `--max-samples` - Limit number of samples (for testing)
- `--cache-dir` - HuggingFace cache directory

**Example:**
```bash
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./data \
    --max-samples 1000
```

---

### `model download`
**Purpose:** Download pre-trained models from HuggingFace Hub

**Required:**
- `--name` - Model name (e.g., "bert-base-uncased")
- `--output-dir` - Where to save the model

**Optional:**
- `--cache-dir` - HuggingFace cache directory

**Example:**
```bash
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/base
```

---

### `model upload`
**Purpose:** Upload a fine-tuned model to HuggingFace Hub

**Prerequisites:**
First, install the HuggingFace Hub CLI:
```bash
curl -LsSf https://hf.co/cli/install.sh | bash
```

Then, authenticate with your HuggingFace credentials:
```bash
hf auth login
```

**Required:**
- `--model-dir` - Directory containing the model files to upload
- `--repo-id` - HuggingFace Hub repository ID (e.g., "username/model-name")

**Optional:**
- `--commit-message, -m` - Commit message for the upload
- `--private` - Make the repository private

**Example:**
```bash
# Basic upload
uv run model-experiments model upload \
    --model-dir ./models/fine-tuned \
    --repo-id my-username/my-model

# With commit message
uv run model-experiments model upload \
    --model-dir ./models/fine-tuned \
    --repo-id my-username/my-model \
    --commit-message "v1.0: Initial fine-tuned model"

# Private repository
uv run model-experiments model upload \
    --model-dir ./models/fine-tuned \
    --repo-id my-username/my-model \
    --private
```

---

### `train`
**Purpose:** Fine-tune a model on training data

**Required:**
- `--model-name` - Model to fine-tune
- `--train-data` - Training data path (JSONL)
- `--val-data` - Validation data path (JSONL)
- `--output-dir` - Where to save fine-tuned model

**Optional (with defaults):**
- `--epochs` - Training epochs (default: 3)
- `--batch-size` - Batch size (default: 16)
- `--learning-rate` - Learning rate (default: 2e-5)
- `--warmup-steps` - Warmup steps (default: 100)
- `--save-steps` - Save checkpoint interval (default: 500)
- `--logging-steps` - Logging interval (default: 50)
- `--eval-steps` - Evaluation interval (default: 250)
- `--max-length` - Max sequence length (default: 512)
- `--gradient-accumulation-steps` - Gradient accumulation (default: 1)
- `--fp16` - Enable mixed precision training
- `--seed` - Random seed (default: 42)

**Example:**
```bash
uv run model-experiments train \
    --model-name bert-base-uncased \
    --train-data ./data/splits/train.jsonl \
    --val-data ./data/splits/val.jsonl \
    --output-dir ./models/fine-tuned \
    --epochs 3 \
    --batch-size 16 \
    --fp16
```

**Outputs:**
- Fine-tuned model files
- `logs/training_log.jsonl` - Training metrics

---

### `evaluate`
**Purpose:** Evaluate model performance on test data

**Required:**
- `--model-path` - Path to model (base or fine-tuned)
- `--test-data` - Test data path (JSONL)
- `--output-file` - Where to save metrics (JSON)

**Optional:**
- `--batch-size` - Inference batch size (default: 32)
- `--max-length` - Max sequence length (default: 512)
- `--metrics` - Metrics to compute (default: accuracy f1 precision recall)
- `--log-predictions` - Save predictions to file

**Example:**
```bash
uv run model-experiments evaluate \
    --model-path ./models/fine-tuned \
    --test-data ./data/splits/val.jsonl \
    --output-file ./metrics/results.json \
    --metrics accuracy f1 precision recall \
    --log-predictions ./predictions/output.jsonl
```

**Outputs:**
- Metrics JSON file
- Optional predictions JSONL file

---

### `compare`
**Purpose:** Compare baseline and fine-tuned model performance

**Required:**
- `--baseline-metrics` - Base model metrics JSON
- `--fine-tuned-metrics` - Fine-tuned model metrics JSON
- `--output-dir` - Where to save comparison results

**Optional:**
- `--generate-plots` - Create visualization charts
- `--format` - Output format (table/json/html)
- `--save-report` - Generate HTML report

**Example:**
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison \
    --generate-plots \
    --save-report
```

**Outputs:**
- `comparison.json` - Structured comparison data
- `report.html` - Visual comparison report (if --save-report)
- `plots/` - Visualization charts (if --generate-plots)

---

## Common Options Across Commands

| Option | Description | Default |
|--------|-------------|---------|
| `--seed` | Random seed for reproducibility | 42 |
| `--output-dir` | Output directory | (required) |
| `--batch-size` | Batch size for processing | Varies by command |
| `--max-length` | Maximum sequence length | 512 |

---

## Data Format Requirements

### Input Data (JSONL)
Each line must be a JSON object with:
```json
{"text": "Your input text here", "label": 0}
```

or for text pairs:
```json
{"text1": "First text", "text2": "Second text", "label": 1}
```

### Output Metrics (JSON)
```json
{
  "accuracy": 0.92,
  "f1": 0.91,
  "precision": 0.90,
  "recall": 0.92,
  "confusion_matrix": [[45, 5], [3, 47]],
  "latency_p50": 23.5,
  "latency_p95": 45.2,
  "latency_p99": 67.8,
  "samples_per_second": 42.3
}
```

---

## Tips & Best Practices

### 💡 Start Small
```bash
# Use --max-samples for quick testing
uv run model-experiments dataset download --name imdb --max-samples 100
```

### 💡 Use Smaller Models for Iteration
```bash
# Try these for faster experimentation:
# - prajjwal1/bert-tiny (very fast)
# - distilbert-base-uncased (good balance)
# - bert-base-uncased (full quality)
```

### 💡 Enable GPU Acceleration
```bash
# Add --fp16 for mixed precision training
uv run model-experiments train ... --fp16
```

### 💡 Monitor Training
```bash
# Training logs are continuously written to:
# <output-dir>/logs/training_log.jsonl

# Watch in real-time:
tail -f ./models/fine-tuned/logs/training_log.jsonl
```

### 💡 Reproducible Results
```bash
# Always set --seed for reproducibility
uv run model-experiments train ... --seed 42
```

---

## Troubleshooting

### Out of Memory
```bash
# Reduce batch size
--batch-size 8

# Reduce sequence length
--max-length 256

# Enable gradient accumulation
--gradient-accumulation-steps 4
```

### Slow Training
```bash
# Enable FP16
--fp16

# Increase batch size (if memory allows)
--batch-size 32

# Reduce logging frequency
--logging-steps 100
```

### Poor Performance
```bash
# Increase training epochs
--epochs 5

# Adjust learning rate
--learning-rate 3e-5

# Use more training data
# (remove or increase --max-samples)
```

---

## Example Use Cases

### Sentiment Analysis (IMDB)
- **Dataset**: `imdb`
- **Models**: `distilbert-base-uncased`, `bert-base-uncased`
- **Task**: Binary classification (positive/negative)

### News Classification (AG News)
- **Dataset**: `ag_news`
- **Models**: `bert-base-uncased`, `roberta-base`
- **Task**: Multi-class classification (4 categories)

### Question Answering (SQuAD)
- **Dataset**: `squad`
- **Models**: `bert-base-uncased`, `distilbert-base-uncased`
- **Task**: Extractive QA

---

## Getting Help

For detailed documentation and examples, see:
- **[USAGE.md](./USAGE.md)** - Complete usage guide
- **[README.md](./README.md)** - Project overview

Run the demo scripts to see everything in action:
- `./scripts/quick_demo.sh` - Fast 5-minute demo
- `./scripts/demo_usage.sh` - Comprehensive example

