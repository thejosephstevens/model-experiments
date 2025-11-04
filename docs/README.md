# Documentation

This directory contains detailed technical documentation for the Model Experiments Framework.

## Files

### Core Documentation
- **CLI_REFERENCE.md** - Complete CLI command reference with all options
- **CLI_IMPLEMENTATION.md** - Technical implementation details of the CLI system
- **IMPLEMENTATION_STATUS.md** - Current status of features and roadmap

### Component Documentation
- **DATASET_DOWNLOAD_IMPLEMENTATION.md** - Dataset downloading and processing details
- **COMPARE_IMPLEMENTATION.md** - Model comparison and reporting implementation
- **PYTORCH_INSTALLATION.md** - PyTorch installation guide for different platforms

### Development Documentation
- **SCRIPTS_README.md** - Guide to all scripts in the repository
- **DEMO_FIXES_SUMMARY.md** - Summary of fixes and improvements
- **DEMO_ISSUES_FIXED.md** - Detailed list of resolved issues
- **SUMMARY.md** - High-level project summary

## Architecture Overview

The framework follows a modular architecture:

```
model-experiments/
├── src/model_experiments/
│   ├── cli.py                 # Main CLI entry point
│   └── commands/               # Command modules
│       ├── dataset.py          # Dataset operations
│       ├── model.py            # Model management
│       ├── train.py            # Training logic
│       ├── evaluate.py         # Evaluation metrics
│       └── compare.py          # Comparison reports
├── tests/                      # Test suite
└── outputs/                    # Generated outputs
```

## Key Design Decisions

1. **Modular Commands**: Each operation is a separate command for flexibility
2. **Type Safety**: Full type hints for better IDE support and catching errors
3. **Rich Output**: Beautiful console output with progress bars and tables
4. **HuggingFace Integration**: Seamless integration with HF ecosystem
5. **Reproducibility**: Seed control and deterministic operations

## Data Flow

1. **Input**: Raw datasets from HuggingFace or custom JSONL files
2. **Processing**: Tokenization and batching for model input
3. **Training**: Fine-tuning with monitoring and checkpointing
4. **Evaluation**: Comprehensive metrics computation
5. **Output**: JSON metrics and HTML comparison reports

## Contributing

When adding new features:
1. Add type hints to all functions
2. Include docstrings for all public APIs
3. Add tests in the `tests/` directory
4. Update relevant documentation
