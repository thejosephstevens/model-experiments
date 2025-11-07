# Model Experiments Framework

A modular framework for fine-tuning language models with comprehensive evaluation and monitoring capabilities.

## 🚀 Quick Start

### First Time Setup

If you're setting up this project for the first time, run the bootstrap script:

```bash
# Run bootstrap script (installs uv and all dependencies)
./scripts/bootstrap.sh
```

The bootstrap script will:
- Install `uv` package manager (if not already installed)
- Set up Python 3.12+ environment
- Install all project dependencies
- Install PyTorch (prompts for CPU or GPU version)
- Verify the installation

### Run the Demo

After setup, run the quick demo to see the framework in action:

```bash
# Run the quick demo
./scripts/quick_demo.sh
```

This will download a small dataset, fine-tune a model, and generate a performance comparison report in ~5 minutes.

## 📋 Prerequisites

- Python 3.12+ (automatically managed by uv)
- 4GB+ RAM for small models
- GPU optional (CPU-only mode supported)

**Note:** The bootstrap script will install `uv` for you, so you don't need to install it manually.

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/thejosephstevens/model-experiments.git
cd model-experiments

# Run bootstrap script (recommended for first-time setup)
# This will prompt you for CPU vs GPU PyTorch installation
./scripts/bootstrap.sh

# Or manually install dependencies with UV
uv sync
uv sync --extra torch-cpu    # For CPU-only
uv sync --extra torch-gpu    # For GPU with CUDA support
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

- **[REPOSITORY_STRUCTURE.md](./REPOSITORY_STRUCTURE.md)** - Repository layout and organization
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
./scripts/quick_demo.sh
```
- Small dataset (500 samples)
- Tiny BERT model
- 2 training epochs
- Perfect for testing

### Full Demo (30 minutes)
```bash
./scripts/demo_usage.sh
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
