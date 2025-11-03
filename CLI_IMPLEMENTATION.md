# CLI Implementation Documentation

## Overview

The core CLI entrypoints have been implemented using Typer. All command structures are in place with placeholder implementations.

## Project Structure

```
src/model_experiments/
├── __init__.py                    # Package initialization
├── cli.py                         # Main CLI entry point
└── commands/
    ├── __init__.py                # Commands module
    ├── dataset.py                 # Dataset management commands
    ├── model.py                   # Model management commands
    ├── train.py                   # Training command
    ├── evaluate.py                # Evaluation command
    └── compare.py                 # Comparison command
```

## CLI Structure

### Main App (`cli.py`)
- Entry point: `model-experiments`
- Framework: Typer with Rich formatting
- Features:
  - Version flag (`--version`, `-v`)
  - Help documentation
  - Shell completion support
  - Command groups and standalone commands

### Command Groups

#### Dataset Commands (`dataset.py`)
```bash
model-experiments dataset download
```

**download** - Download datasets from HuggingFace Hub
- Required: `--name`, `--output-dir`
- Optional: `--max-samples`, `--cache-dir`

#### Model Commands (`model.py`)
```bash
model-experiments model download
```

**download** - Download pre-trained models from HuggingFace Hub
- Required: `--name`, `--output-dir`
- Optional: `--cache-dir`

### Standalone Commands

#### Train (`train.py`)
```bash
model-experiments train
```
Fine-tune a model on training data
- Required: `--model-name`, `--train-data`, `--val-data`, `--output-dir`
- Optional: Many training parameters (epochs, batch size, learning rate, etc.)
- Validation: Checks that data files exist

#### Evaluate (`evaluate.py`)
```bash
model-experiments evaluate
```
Evaluate model performance on test data
- Required: `--model-path`, `--test-data`, `--output-file`
- Optional: `--batch-size`, `--max-length`, `--metrics`, `--log-predictions`
- Validation: Checks that model and data files exist

#### Compare (`compare.py`)
```bash
model-experiments compare
```
Compare baseline and fine-tuned model performance
- Required: `--baseline-metrics`, `--fine-tuned-metrics`, `--output-dir`
- Optional: `--generate-plots`, `--format`, `--save-report`
- Validation: Checks that metrics files exist and format is valid

## Testing

### Run all CLI tests
```bash
./test_cli.sh
```

### Individual command tests
```bash
# Version
uv run model-experiments --version

# Help
uv run model-experiments --help

# Dataset commands
uv run model-experiments dataset --help
uv run model-experiments dataset download --help

# Model commands
uv run model-experiments model --help
uv run model-experiments model download --help

# Standalone commands
uv run model-experiments train --help
uv run model-experiments evaluate --help
uv run model-experiments compare --help
```

### Test placeholder execution
```bash
# This will show the "not yet implemented" message
uv run model-experiments dataset download --name test --output-dir ./test
```

## Dependencies

Added to `pyproject.toml`:
```toml
[project]
dependencies = [
    "typer>=0.9.0",
    "rich>=13.0.0",
    "shellingham>=1.5.0",
]

[project.scripts]
model-experiments = "model_experiments.cli:app"

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]
```

## Key Features

### 1. Type Hints
All command functions use proper type hints with `Path`, `Optional`, etc.

### 2. Rich Output
Using Rich library for:
- Colored console output
- Formatted help text
- Progress indicators (ready for implementation)

### 3. Validation
Built-in validation for:
- File/directory existence
- Numeric ranges (ratios, etc.)
- Enum values (format options)

### 4. Help Documentation
Every command includes:
- Descriptive help text
- Usage examples
- Parameter descriptions

### 5. Consistent Interface
All commands follow consistent patterns:
- Required options use `typer.Option(...)`
- Optional options have sensible defaults
- Error messages are clear and actionable

## Implementation Status

### ✅ Complete
- [x] Project structure created
- [x] Dependencies installed
- [x] Main CLI entry point
- [x] All command structures defined
- [x] Type hints throughout
- [x] Help documentation
- [x] Parameter validation
- [x] Error handling structure
- [x] Shell completion support

### ⏳ Not Yet Implemented
- [ ] Dataset download logic
- [ ] Model download logic
- [ ] Training logic
- [ ] Evaluation logic
- [ ] Comparison logic
- [ ] Unit tests
- [ ] Integration tests

## Next Steps

1. **Implement dataset commands**
   - Use HuggingFace `datasets` library
   - Handle various dataset formats
   - Implement caching

2. **Implement model commands**
   - Use HuggingFace `transformers` library
   - Handle model and tokenizer downloads
   - Implement caching

3. **Implement training**
   - Set up training loop
   - Add logging and metrics
   - Implement checkpointing

4. **Implement evaluation**
   - Calculate metrics (accuracy, F1, etc.)
   - Generate predictions
   - Log results

5. **Implement comparison**
   - Parse metrics files
   - Generate comparison report
   - Create visualizations

6. **Add tests**
   - Unit tests for each command
   - Integration tests for full workflow
   - Mock external dependencies

## Usage Examples

All commands match the interface specified in the demo scripts:

### Complete Workflow
```bash
# 1. Download dataset
uv run model-experiments dataset download \\
    --name imdb \\
    --output-dir ./data \\
    --max-samples 1000

# 2. Download model
uv run model-experiments model download \\
    --name distilbert-base-uncased \\
    --output-dir ./models/base

# 3. Train model
uv run model-experiments train \\
    --model-name distilbert-base-uncased \\
    --train-data ./data/splits/train.jsonl \\
    --val-data ./data/splits/val.jsonl \\
    --output-dir ./models/fine-tuned \\
    --epochs 3

# 4. Evaluate models
uv run model-experiments evaluate \\
    --model-path ./models/base \\
    --test-data ./data/splits/val.jsonl \\
    --output-file ./metrics/base.json

uv run model-experiments evaluate \\
    --model-path ./models/fine-tuned \\
    --test-data ./data/splits/val.jsonl \\
    --output-file ./metrics/fine_tuned.json

# 5. Compare performance
uv run model-experiments compare \\
    --baseline-metrics ./metrics/base.json \\
    --fine-tuned-metrics ./metrics/fine_tuned.json \\
    --output-dir ./comparison \\
    --generate-plots \\
    --save-report
```

## Notes

- All placeholder implementations print configuration and show "not yet implemented" warning
- The CLI is fully functional for testing the interface
- All demo scripts (`demo_usage.sh`, `quick_demo.sh`) will work once implementations are added
- No breaking changes should be needed - the interface is stable
- Type checking passes (mypy compatible)
- No linter errors

## Troubleshooting

### CLI not found
```bash
# Reinstall the package
uv sync
```

### Import errors
```bash
# Ensure you're in the project directory
cd /Users/josephstevens/.cursor/worktrees/model-experiments/krsAL

# Use uv run to execute
uv run model-experiments --help
```

### Module not found
```bash
# Check the virtual environment
uv sync

# Verify installation
uv pip list | grep model-experiments
```

## Contributing

When implementing commands:
1. Keep the function signatures as-is
2. Replace the placeholder message with actual logic
3. Maintain all validation checks
4. Add appropriate error handling
5. Update progress indicators using Rich
6. Add logging as appropriate
7. Write unit tests

## Summary

The core CLI infrastructure is complete and ready for implementation. All commands are properly structured with:
- ✅ Type hints
- ✅ Validation
- ✅ Help documentation
- ✅ Consistent interface
- ✅ Error handling
- ✅ Rich formatting

The CLI matches the specifications in the demo scripts exactly and is ready for the actual implementation work.

