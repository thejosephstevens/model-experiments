# Demo Scripts Overview

This document explains the demonstration scripts created for the Model Fine-Tuning Framework.

## 📁 Files Created

### Executable Scripts

1. **`demo_usage.sh`** (8.5 KB) - Comprehensive demonstration
   - Full workflow with detailed configuration
   - Shows all available CLI options
   - Production-ready settings
   - Extensive logging and comments
   - Estimated runtime: 20-30 minutes (with full dataset)

2. **`quick_demo.sh`** (2.1 KB) - Fast minimal example
   - Streamlined workflow for quick testing
   - Small dataset (500 samples)
   - Tiny model for speed
   - Minimal configuration
   - Estimated runtime: 5-10 minutes

### Documentation

3. **`USAGE.md`** (10 KB) - Complete CLI documentation
   - Detailed command reference
   - All available options explained
   - Multiple example workflows
   - Output structure guide
   - Tips and best practices

4. **`CLI_REFERENCE.md`** (9.1 KB) - Quick reference card
   - Command cheat sheet
   - Common usage patterns
   - Troubleshooting guide
   - Use case examples
   - Data format specifications

5. **`README.md`** (updated) - Project overview with quick start

## 🎯 Purpose

These scripts serve as:

1. **Usage Examples** - Show how the CLI should be used
2. **Specification** - Define the expected CLI interface
3. **Testing Tools** - Validate the implementation works correctly
4. **Documentation** - Explain the complete workflow

## 🚀 Quick Start

### Run the Fast Demo
```bash
./quick_demo.sh
```

This executes the complete workflow in ~5 minutes:
- Downloads 500 samples from a small dataset
- Splits data 90/10 for train/validation
- Downloads a tiny BERT model
- Fine-tunes for 2 epochs
- Evaluates both models
- Generates performance comparison

### Run the Full Demo
```bash
./demo_usage.sh
```

This shows all features and options:
- Larger dataset (1000 samples, configurable)
- More training epochs (3, configurable)
- All CLI options demonstrated
- Comprehensive metrics and logging
- Visual comparison reports

## 📋 Complete Workflow Demonstrated

Both scripts implement the following 5-step workflow:

### Step 1: Download Dataset
```bash
uv run model-experiments dataset download \
    --name <dataset_name> \
    --output-dir <path> \
    --max-samples <int>
```

Downloads datasets from HuggingFace Hub (e.g., IMDB, AG News, etc.)

### Step 2: Download Model
```bash
uv run model-experiments model download \
    --name <model_name> \
    --output-dir <path>
```

Downloads pre-trained models from HuggingFace Hub.

### Step 3: Train Model with Training Data
```bash
uv run model-experiments train \
    --model-name <name> \
    --train-data <path>/train.jsonl \
    --val-data <path>/validation.jsonl \
    --output-dir <path> \
    --epochs <int> \
    --batch-size <int> \
    --learning-rate <float> \
    --fp16
```

Fine-tunes the model with comprehensive logging and metrics.

### Step 4: Run Both Models Against Validation Data
```bash
# Evaluate original base model
uv run model-experiments evaluate \
    --model-path <path>/base \
    --test-data <path>/validation.jsonl \
    --output-file <path>/base_metrics.json \
    --metrics accuracy f1 precision recall \
    --log-predictions <path>/base_predictions.jsonl

# Evaluate fine-tuned model
uv run model-experiments evaluate \
    --model-path <path>/fine-tuned \
    --test-data <path>/validation.jsonl \
    --output-file <path>/fine_tuned_metrics.json \
    --metrics accuracy f1 precision recall \
    --log-predictions <path>/fine_tuned_predictions.jsonl
```

Records comprehensive metrics and prediction logs for analysis.

### Step 5: Print Performance Comparison
```bash
uv run model-experiments compare \
    --baseline-metrics <path>/base_metrics.json \
    --fine-tuned-metrics <path>/fine_tuned_metrics.json \
    --output-dir <path>/comparison \
    --generate-plots \
    --save-report
```

Generates visual reports showing improvement from fine-tuning.

## 📊 Expected Output Structure

After running a demo script, you'll have:

```
demo_output/  (or ./outputs/)
├── data/
│   ├── <dataset_name>/          # Raw downloaded data
│   │   ├── train.jsonl
│   │   └── validation.jsonl
├── models/
│   ├── base/                    # Original model
│   │   ├── config.json
│   │   ├── pytorch_model.bin
│   │   └── tokenizer/
│   └── fine-tuned/              # Trained model
│       ├── config.json
│       ├── pytorch_model.bin
│       ├── tokenizer/
│       └── logs/
│           └── training_log.jsonl  # Training metrics
├── metrics/
│   ├── base.json                # Base model performance
│   └── fine_tuned.json          # Fine-tuned performance
├── predictions/
│   ├── base_predictions.jsonl   # Base model outputs
│   └── fine_tuned_predictions.jsonl  # Fine-tuned outputs
└── comparison/
    ├── report.html              # Visual comparison
    ├── comparison.json          # Structured data
    └── plots/
        ├── accuracy.png
        ├── f1_score.png
        ├── precision.png
        ├── recall.png
        └── confusion_matrix.png
```

## 🎨 Key Features Demonstrated

### 1. Reusability
Both scripts can be easily modified to use different:
- Datasets (change `DATASET_NAME`)
- Models (change `MODEL_NAME`)
- Train/val splits (change `TRAIN_SPLIT`, `VAL_SPLIT`)
- Training parameters (epochs, batch size, learning rate)

### 2. Comprehensive Metrics
The framework tracks:
- **Accuracy** - Overall correctness
- **F1 Score** - Harmonic mean of precision and recall
- **Precision** - True positive rate
- **Recall** - Coverage of actual positives
- **Latency** - P50, P95, P99 response times
- **Throughput** - Samples processed per second

### 3. Monitoring & Logging
- Training progress logged in real-time
- Validation metrics computed at intervals
- Individual predictions saved for error analysis
- System metrics (GPU, memory) tracked

### 4. Visual Reporting
- HTML reports with charts and graphs
- Side-by-side metric comparisons
- Confusion matrices
- Performance trend plots

## 🔧 Customization

### Change Dataset
Edit the `DATASET_NAME` variable:
```bash
DATASET_NAME="ag_news"      # News classification
DATASET_NAME="imdb"         # Sentiment analysis
DATASET_NAME="squad"        # Question answering
```

### Change Model
Edit the `MODEL_NAME` variable:
```bash
MODEL_NAME="prajjwal1/bert-tiny"        # Fastest
MODEL_NAME="distilbert-base-uncased"    # Good balance
MODEL_NAME="bert-base-uncased"          # Full quality
MODEL_NAME="roberta-base"               # Alternative
```

### Adjust Dataset Size
For quick testing:
```bash
MAX_SAMPLES="100"    # Very fast
MAX_SAMPLES="500"    # Quick demo
MAX_SAMPLES="1000"   # Standard demo
# MAX_SAMPLES=""     # Full dataset (remove limit)
```

### Modify Training Duration
```bash
EPOCHS="1"    # Quick test
EPOCHS="3"    # Standard
EPOCHS="5"    # Better quality
```

### Change Split Ratio
```bash
TRAIN_SPLIT="0.8"   # 80/20 split
VAL_SPLIT="0.2"

TRAIN_SPLIT="0.9"   # 90/10 split (default)
VAL_SPLIT="0.1"

TRAIN_SPLIT="0.95"  # 95/5 split (more training data)
VAL_SPLIT="0.05"
```

## 🔍 Verification

To verify the scripts work correctly, check:

1. **Files Created** - All expected output files exist
2. **Metrics Improved** - Fine-tuned model shows better metrics
3. **Logs Generated** - Training logs show expected progress
4. **Report Created** - HTML comparison report opens properly

### Expected Improvement
For most tasks, you should see:
- **Accuracy**: +5-20% improvement
- **F1 Score**: +5-20% improvement
- Fine-tuned model clearly outperforms base model

## 💡 Tips

### For Development
- Use `quick_demo.sh` during implementation
- Verify each command works before moving to next
- Check log files if something fails

### For Testing
- Run `demo_usage.sh` with different datasets
- Verify metrics are computed correctly
- Ensure reports generate properly

### For Documentation
- Use these scripts as examples in README
- Show users the expected workflow
- Demonstrate best practices

## 🐛 Troubleshooting

### Script Fails at Step 1
- Check internet connection (downloads from HuggingFace)
- Verify `uv run` command works
- Ensure Python environment is set up

### Out of Memory
- Reduce `MAX_SAMPLES` in script
- Use smaller model (e.g., `bert-tiny`)
- Reduce `batch-size` parameter

### Slow Execution
- Use smaller dataset (`MAX_SAMPLES="100"`)
- Use tiny model (`prajjwal1/bert-tiny`)
- Reduce epochs to 1

### Scripts Won't Run
```bash
# Make scripts executable
chmod +x demo_usage.sh
chmod +x quick_demo.sh

# Run with bash explicitly
bash demo_usage.sh
bash quick_demo.sh
```

## 📚 Related Documentation

- **[USAGE.md](./USAGE.md)** - Complete CLI documentation with all options
- **[CLI_REFERENCE.md](./CLI_REFERENCE.md)** - Quick reference card
- **[README.md](./README.md)** - Project overview and setup
- **[task.md](./.localonly/task.md)** - Original project requirements

## ✅ Validation Checklist

Use this checklist to verify the implementation matches the scripts:

- [ ] `dataset download` command works as shown
- [ ] `model download` fetches models successfully
- [ ] `train` command fine-tunes and saves model
- [ ] Training logs are generated
- [ ] `evaluate` command computes metrics
- [ ] Metrics JSON files are created
- [ ] Predictions can be logged
- [ ] `compare` command generates report
- [ ] Fine-tuned model shows improvement
- [ ] HTML report displays correctly
- [ ] All output directories are created
- [ ] Scripts run without errors

## 🎓 Learning Outcomes

By studying these scripts, you can learn:

1. **CLI Design** - How to structure a multi-command CLI
2. **Workflow Design** - How to break down ML tasks into steps
3. **Best Practices** - Proper logging, metrics, and reporting
4. **Modularity** - How to make tools reusable
5. **Documentation** - How to document technical tools effectively

## 📝 Next Steps

1. **Implement the CLI** - Use typer to create these commands
2. **Test with Scripts** - Verify each command matches expected behavior
3. **Add Unit Tests** - Test each component independently
4. **Host Model** - Upload fine-tuned model to HuggingFace
5. **Create Demo Video** - Record the scripts running successfully

---

**Note**: These scripts are **reference implementations** showing how the CLI should work. They serve as both documentation and specification for building the actual framework.

