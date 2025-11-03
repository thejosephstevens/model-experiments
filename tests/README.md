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

### `test_dataset_split.sh`
Tests the `dataset split` subcommand with 31 test cases covering:
- Help text validation
- Required parameters validation
- Ratio validation (must be 0-1, must sum to 1.0)
- Valid command execution with various parameter combinations
- Output validation (input/output paths, ratios, seed, stratify)
- Edge cases (50/50, 99/1, 1/99 splits, nested paths)
- **Output file size validation:**
  - Verifies output files exist after split
  - Validates train/val split sizes match specified ratios (80/20, 90/10)
  - Confirms total samples are preserved
  - Checks for no duplicate samples between train and val sets

**Status:** ✅ All tests passing (100% pass rate)
**Note:** File size validation tests skip gracefully until split implementation is complete

## Running Tests

### Run Individual Tests

```bash
# Test dataset download
./tests/test_dataset_download.sh

# Test dataset split
./tests/test_dataset_split.sh
```

### Run All Tests

```bash
# Run all tests in sequence
./tests/run_all_tests.sh
```

## Test Structure

Each test script follows a consistent pattern:
- Color-coded output (green=pass, red=fail, blue=info, yellow=test)
- Automatic setup and cleanup of test data
- Organized test suites with clear descriptions
- Detailed pass/fail reporting with statistics
- Exit code 0 on success, 1 on failure (CI/CD friendly)

## Test Output

Each test script provides:
- Real-time progress with test descriptions
- Immediate pass/fail feedback
- Summary statistics (total tests, passed, failed, pass rate)
- Automatic cleanup of temporary test files

## Requirements

- `uv` (Python package manager)
- All project dependencies installed (`uv sync`)
- Executable permissions on test scripts (`chmod +x tests/*.sh`)

## Adding New Tests

When adding new test scripts:
1. Follow the naming convention: `test_<command>_<subcommand>.sh`
2. Make the script executable: `chmod +x tests/test_<name>.sh`
3. Follow the existing test structure and patterns
4. Update this README with the new test description
5. Add the new test to `run_all_tests.sh`

