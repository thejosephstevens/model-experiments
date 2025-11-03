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

## Running Tests

### Run Individual Tests

```bash
# Test dataset download
./tests/test_dataset_download.sh

# Test model download
./tests/test_model_download.sh
```

### Run All Tests

```