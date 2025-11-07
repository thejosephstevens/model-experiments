# Repository Structure

This document describes the organization of the Model Experiments Framework repository.

## 📁 Directory Layout

```
model-experiments/
├── scripts/                          # Executable scripts for setup and demos
│   ├── bootstrap.sh                 # Initial setup script (installs dependencies)
│   ├── quick_demo.sh                # Quick 5-minute demo
│   └── demo_usage.sh                # Full 30-minute demo with all features
├── src/                             # Main Python package source code
│   └── model_experiments/           # Package directory
│       ├── __init__.py              # Package initialization
│       ├── cli.py                   # Main CLI entry point
│       └── commands/                # CLI command modules
│           ├── __init__.py
│           ├── dataset.py           # Dataset download/management commands
│           ├── model.py             # Model download/management commands
│           ├── train.py             # Training commands
│           ├── evaluate.py          # Evaluation commands
│           ├── compare.py           # Comparison commands
│           └── utils.py             # Utility functions
├── tests/                           # Test suite
│   ├── README.md                    # Testing documentation
│   ├── run_all_tests.sh             # Run all tests
│   ├── test_*.sh                    # Individual test scripts
│   └── ...
├── docs/                            # Documentation
│   ├── README.md                    # Documentation index
│   ├── SCRIPTS_README.md            # Guide to demo scripts
│   ├── CLI_REFERENCE.md             # CLI command reference
│   ├── CLI_IMPLEMENTATION.md        # CLI implementation details
│   ├── USAGE.md                     # Usage guide and examples
│   ├── CACHING.md                   # Caching system documentation
│   ├── PYTORCH_INSTALLATION.md      # PyTorch setup guide
│   ├── COMPARE_IMPLEMENTATION.md    # Comparison feature details
│   ├── DATASET_DOWNLOAD_IMPLEMENTATION.md  # Dataset download details
│   ├── IMPLEMENTATION_STATUS.md     # Implementation status
│   ├── DEMO_ISSUES_FIXED.md         # Bug fixes and issues
│   ├── DEMO_FIXES_SUMMARY.md        # Summary of fixes
│   ├── SUMMARY.md                   # Project summary
│   └── ...
├── data/                            # Dataset storage (generated at runtime)
│   ├── train/                       # Training data
│   ├── test/                        # Test data
│   ├── unsupervised/                # Unsupervised data
│   ├── cache/                       # Cached datasets
│   └── metadata.json                # Dataset metadata
├── experiments/                     # Experiment runs (generated at runtime)
│   └── exp_*/                       # Individual experiment directories
│       ├── cache/                   # Cached models and datasets
│       ├── data/                    # Experiment-specific data
│       ├── models/                  # Trained models
│       ├── metrics/                 # Evaluation metrics
│       ├── predictions/             # Model predictions
│       ├── comparison/              # Comparison reports
│       └── experiment_metadata.json # Experiment metadata
├── outputs/                         # Default output directory
│   ├── models/                      # Trained models
│   ├── metrics/                     # Evaluation metrics
│   ├── predictions/                 # Model predictions
│   ├── comparison/                  # Comparison reports
│   └── cache/                       # Cached resources
├── models/                          # Model storage (if used)
├── test_cache_dataset/              # Test cache data
├── test_cache_model/                # Test cache models
├── test_quick_experiment/           # Quick test experiments
├── pyproject.toml                   # Python project configuration
├── requirements.txt                 # Python dependencies
├── uv.lock                          # uv lock file
├── README.md                        # Project overview
├── USAGE.md                         # Usage guide
├── REPOSITORY_STRUCTURE.md          # This file
├── LEARNINGS.md                     # Learning notes
├── bootstrap.sh → scripts/bootstrap.sh    # Symlink to bootstrap
└── .gitignore                       # Git ignore rules
```

## 🗂️ Organization Principles

### `/scripts/`
Contains executable shell scripts for common tasks:
- **bootstrap.sh** - First-time setup script that installs dependencies and PyTorch
- **quick_demo.sh** - Quick 5-minute demonstration (good for testing)
- **demo_usage.sh** - Full 30-minute demonstration with all features

### `/src/`
Contains the main Python package:
- **model_experiments/** - Main package directory
- **cli.py** - Typer-based CLI application (entry point)
- **commands/** - Modular command implementations
  - Each command (dataset, model, train, evaluate, compare) has its own module
  - utils.py contains shared utilities

### `/tests/`
Test suite with:
- Individual shell scripts for testing each command
- run_all_tests.sh to run the complete test suite
- Each test is self-contained and can run independently

### `/docs/`
Comprehensive documentation:
- **CLI_REFERENCE.md** - Quick command reference
- **USAGE.md** - Detailed usage guide with examples
- **SCRIPTS_README.md** - Guide to the demo scripts
- Implementation-specific docs for each major feature
- **README.md** - Index to all documentation

### `/data/`, `/experiments/`, `/outputs/`
Runtime-generated directories (created as needed):
- Store downloaded datasets, models, metrics, and predictions
- `/experiments/` - Isolated runs with their own caches
- `/outputs/` - Default output location for results

## 📝 Quick Start References

### To set up the environment:
```bash
./scripts/bootstrap.sh
```

### To run the quick demo:
```bash
./scripts/quick_demo.sh
```

### To run the full demo:
```bash
./scripts/demo_usage.sh
```

### To run tests:
```bash
./tests/run_all_tests.sh
```

### To use the CLI directly:
```bash
uv run model-experiments --help
```

## 🔄 Workflow

1. **Setup** → Run `./scripts/bootstrap.sh`
2. **Try it out** → Run `./scripts/quick_demo.sh`
3. **Read docs** → See `/docs/` for detailed information
4. **Run tests** → Run `./tests/run_all_tests.sh`
5. **Use CLI** → Run `uv run model-experiments <command>`

## 📦 Key Files

| File | Purpose |
|------|---------|
| `pyproject.toml` | Python project configuration and dependencies |
| `requirements.txt` | Alternative requirements specification |
| `uv.lock` | Locked dependency versions |
| `README.md` | Project overview and quick start |
| `USAGE.md` | Detailed usage guide |
| `REPOSITORY_STRUCTURE.md` | This file - explains the layout |
| `src/model_experiments/cli.py` | Main CLI entry point |

## 🚀 Development

### Adding a new command:
1. Create a new module in `src/model_experiments/commands/`
2. Implement the command function with proper type hints
3. Import and register in `src/model_experiments/cli.py`
4. Add tests in `tests/test_<command>.sh`
5. Document in `docs/USAGE.md`

### Running locally:
```bash
uv run model-experiments <command> [options]
```

### Debugging:
Check the experiment directories in `/experiments/` for logs and intermediate results.

## 🔍 Finding Things

- **How to use the CLI?** → See `docs/USAGE.md` or `docs/CLI_REFERENCE.md`
- **How to run demos?** → See `README.md` or `scripts/` directory
- **Implementation details?** → See `docs/`
- **Testing?** → See `tests/`
- **Source code?** → See `src/model_experiments/`

## 💡 Tips

- Scripts are in `/scripts/` for easy access
- Demos use standard configuration - customize by editing the scripts
- Each command is self-contained in its own module
- Test suite in `/tests/` shows expected behavior
- Documentation in `/docs/` explains everything in detail

