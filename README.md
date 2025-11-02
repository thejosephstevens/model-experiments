# Model Experiments Framework

A modular framework for fine-tuning language models with comprehensive evaluation and monitoring capabilities.

## Quick Start

Run the quick demo to see the framework in action:

```bash
./quick_demo.sh
```

This will download a small dataset, fine-tune a model, and generate a performance comparison report.

## Usage Examples

We provide two demonstration scripts:

1. **`quick_demo.sh`** - Fast minimal example (~5 minutes)
   - Small dataset (500 samples)
   - Tiny model for speed
   - 2 training epochs
   - Perfect for testing the framework

2. **`demo_usage.sh`** - Comprehensive example with full configuration
   - Demonstrates all CLI options
   - Detailed logging and metrics
   - Production-ready settings

See **[USAGE.md](./USAGE.md)** for complete CLI documentation and examples.

## Complete Workflow

The framework supports the following workflow:

1. **Download Dataset** - Fetch datasets from HuggingFace
2. **Split Data** - Create train/validation splits (90/10)
3. **Download Model** - Get pre-trained models
4. **Train** - Fine-tune models with comprehensive logging
5. **Evaluate** - Test models with multiple metrics
6. **Compare** - Generate performance comparison reports

All commands use the `uv run model-experiments` CLI interface.
