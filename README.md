# Model Experiments Framework

A modular framework for fine-tuning language models with comprehensive evaluation and monitoring capabilities.

## 🚀 Quick Start

Run the quick demo to see the framework in action:

```bash
# Install dependencies (using UV package manager)
uv sync

# Run the quick demo
./quick_demo.sh
```

This will download a small dataset, fine-tune a model, and generate a performance comparison report in ~5 minutes.

## 📋 Prerequisites

- Python 3.12+
- UV package manager ([install UV](https://docs.astral.sh/uv/getting-started/installation/))
- 4GB+ RAM for small models
- GPU optional (CPU-only mode supported)

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/thejosephstevens/model-experiments.git
cd model-experiments

# Install dependencies with UV
uv sync

# (Optional) For GPU support with CUDA
uv sync --extra torch-gpu
```

## 🎯 Features

- **Modular Design**: Separate commands for each step of the ML workflow
- **HuggingFace Integration**: Seamless dataset and model downloading
- **Smart Caching**: Automatic caching of downloaded models and datasets to avoid re-downloading
- **Comprehensive Metrics**: Accuracy, F1, precision, recall, and confusion matrices
- **Beautiful Reports**: HTML comparison reports with visualizations
- **Progress Tracking**: Rich console output with progress bars
- **Type-Safe**: Full type hints throughout the codebase
- **Well-Tested**: Comprehensive test suite included

## 📚 Documentation

- **[USAGE.md](./USAGE.md)** - Complete CLI reference and examples
- **[docs/](./docs/)** - Implementation details and technical documentation
- **[tests/](./tests/)** - Test suite and examples

## 🔄 Complete Workflow

The framework supports the following workflow:

1. **Download Dataset** - Fetch datasets from HuggingFace
2. **Split Data** - Create train/validation splits (90/10)
3. **Download Model** - Get pre-trained models
4. **Train** - Fine-tune models with comprehensive logging
5. **Evaluate** - Test models with multiple metrics
6. **Compare** - Generate performance comparison reports

## 💻 Usage Examples

### Quick Demo (5 minutes)
```bash
./quick_demo.sh
```
- Small dataset (500 samples)
- Tiny BERT model
- 2 training epochs
- Perfect for testing

### Full Demo (30 minutes)
```bash
./demo_usage.sh
```
- Full dataset
- Production model
- Complete metrics
- Detailed logging

### Custom Workflow
```bash
# Download dataset
uv run model-experiments dataset download \
    --name imdb \
    --output-dir data \
    --max-samples 1000

# Download model
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir models/base

# Train model
uv run model-experiments train \
    --model-name distilbert-base-uncased \
    --train-data data/train/data.jsonl \
    --val-data data/test/data.jsonl \
    --output-dir outputs/models/fine-tuned \
    --epochs 3 \
    --batch-size 16

# Evaluate models
uv run model-experiments evaluate \
    --model-path outputs/models/fine-tuned \
    --test-data data/test/data.jsonl \
    --output-file outputs/metrics/fine_tuned_metrics.json

# Compare performance
uv run model-experiments compare \
    --baseline-metrics outputs/metrics/base_metrics.json \
    --fine-tuned-metrics outputs/metrics/fine_tuned_metrics.json \
    --output-format html \
    --output-file outputs/comparison/report.html
```

## 🧪 Testing

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific test
./tests/test_train.sh
```

## 📊 Output Structure

```
outputs/
├── models/           # Trained models
├── metrics/          # Evaluation metrics
├── predictions/      # Model predictions
└── comparison/       # Comparison reports
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License - see LICENSE file for details

## 👤 Author

Jo Stevens

## 🙏 Acknowledgments

- HuggingFace Transformers library
- Rich console library for beautiful CLI output
- Typer for CLI framework
