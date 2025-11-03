# Test Suite

This directory contains comprehensive validation scripts for the model-experiments CLI commands.

## Test Scripts

### `test_dataset_download.sh`
Tests the `dataset download` subcommand with 19 test cases covering:
- Help text validation
- Required parameters validation
- Valid command execution with various parameter combinations
- Output validation
- Multiple dataset support (imdb, ag_news, yelp_polarity, squad, rotten_tomatoes)
- Edge cases (min/max samples, nested paths)

**Status:** ✅ All tests passing (100% pass rate)

### `test_model_download.sh`
Tests the `model download` subcommand with 19 test cases covering:
- Help text validation
- Required parameters validation
- Valid command execution with various parameter combinations
- Output validation
- Multiple model support (distilbert-base-uncased, bert-base-uncased, prajjwal1/bert-tiny, roberta-base)
- Edge cases (nested paths, hyphenated names, organization/model format)
- Command structure validation (model command group and main CLI integration)

**Status:** ✅ All tests passing (100% pass rate)

### `test_train.sh`
Tests the `train` subcommand with 24 test cases covering:
- Help text validation
- Required parameters validation (model-name, train-data, val-data, output-dir)
- Data file validation (checks for non-existent files)
- Valid command execution with default and custom parameters
- Output validation (model name, configuration, data paths)
- Optional parameters acceptance (learning rate, warmup steps, FP16, seed)
- Combined parameters (all training options together)
- Command structure validation (main CLI and help integration)
- Edge cases (batch size 1, large batch sizes, single epoch, nested paths)

**Status:** ✅ All tests passing (100% pass rate)

### `test_evaluate.sh`
Tests the `evaluate` subcommand with 27 test cases covering:
- Help text validation
- Required parameters validation (model-path, test-data, output-file)
- File validation (checks for non-existent model and test data)
- Valid command execution with default and custom parameters
- Output validation (evaluation configuration, model reference, metrics)
- Metrics configuration (accuracy, f1, precision, recall, multiple metrics)
- Optional parameters (log-predictions parameter)
- Combined parameters (all evaluation options together)
- Command structure validation (main CLI and help integration)
- Edge cases (batch size 1 and 256, max length variations, nested paths)

**Status:** ✅ All tests passing (100% pass rate)

### `test_compare.sh`
Tests the `compare` subcommand with 24 test cases covering:
- Help text validation
- Required parameters validation (baseline-metrics, fine-tuned-metrics, output-dir)
- File validation (checks for non-existent metrics files)
- Format validation (table, json, html formats)
- Valid command execution with default and custom parameters
- Output validation (comparison configuration, metrics references, format info)
- Optional flags (generate-plots, save-report)
- Combined options (all comparison options together)
- Command structure validation (main CLI and help integration)
- Edge cases (nested paths, default format, combined flags, multiple metric files)

**Status:** ✅ All tests passing (100% pass rate)

## Running Tests

### Run Individual Tests

```bash
# Test dataset download
./tests/test_dataset_download.sh

# Test model download
./tests/test_model_download.sh

# Test train command
./tests/test_train.sh

# Test evaluate command
./tests/test_evaluate.sh

# Test compare command
./tests/test_compare.sh
```

### Run All Tests

```
```