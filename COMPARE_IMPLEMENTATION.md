# Compare Subcommand Implementation

## Overview

The `compare` subcommand has been fully implemented with comprehensive functionality for comparing baseline and fine-tuned model performance metrics.

## Features Implemented

### 1. Core Functionality
- **Metrics Loading**: Load metrics from JSON files for both baseline and fine-tuned models
- **Difference Calculation**: Compute absolute differences and percentage changes
- **Improvement Tracking**: Identify and track metrics with positive improvements

### 2. Output Formats

#### Table Format (Default)
- Rich formatted table display with color coding
- Shows: Metric, Baseline Value, Fine-Tuned Value, Absolute Difference, Percentage Change
- Color-coded improvements (green for positive, red for negative, yellow for neutral)
- Terminal-friendly output with proper alignment

#### JSON Format
- Structured comparison data saved to `comparison.json`
- Contains: baseline metrics, fine-tuned metrics, detailed comparisons
- Machine-readable format for programmatic use

#### HTML Format
- Automatically saves comparison data as JSON
- Optional comprehensive HTML report with `--save-report`

### 3. HTML Report Generation
- Modern, responsive design with gradient header
- Summary statistics showing:
  - Number and percentage of improved metrics
  - Samples evaluated
  - Baseline and fine-tuned model paths
- Detailed metrics table with color-coded improvements
- Professional styling with proper typography and spacing

### 4. Visualization (Optional)
- `--generate-plots`: Create comparison visualizations
- Two-panel plot showing:
  - Side-by-side metrics comparison bar chart
  - Percentage improvement bar chart
- Gracefully handles missing matplotlib dependency

### 5. Summary Output
- Progress indicators for all major steps
- Summary statistics displayed after comparison
- Top improvements ranked by percentage change

## Command Usage

### Basic Usage
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison
```

### With HTML Report
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison \
    --save-report
```

### With JSON Output Format
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison \
    --format json
```

### With All Options
```bash
uv run model-experiments compare \
    --baseline-metrics ./metrics/base.json \
    --fine-tuned-metrics ./metrics/fine_tuned.json \
    --output-dir ./comparison \
    --format html \
    --save-report \
    --generate-plots
```

## Implementation Details

### Functions

#### `load_metrics(metrics_file: Path) -> dict[str, Any]`
Loads metrics from a JSON file. Expected structure:
```json
{
  "model_path": "path/to/model",
  "num_samples": 1000,
  "metrics": {
    "accuracy": 0.85,
    "f1": 0.83,
    "precision": 0.82,
    "recall": 0.84
  },
  "requested_metrics": ["accuracy", "f1", "precision", "recall"]
}
```

#### `calculate_differences(baseline, fine_tuned) -> tuple[dict, dict]`
Compares two metric dictionaries and returns:
1. Differences dict: Contains baseline value, fine-tuned value, absolute difference, and percent change
2. Improvements dict: Subset of differences with positive improvements

#### `format_as_table(baseline, fine_tuned, differences) -> None`
Renders comparison as a Rich formatted table with color coding

#### `format_as_json(baseline, fine_tuned, differences, output_file) -> None`
Saves comparison data as structured JSON

#### `generate_html_report(baseline, fine_tuned, differences, improvements, output_file) -> None`
Generates a professional HTML report with:
- Gradient header
- Summary cards with key statistics
- Detailed metrics table
- CSS styling for responsive design

#### `generate_visualization_plots(differences, output_dir) -> None`
Creates matplotlib-based visualization charts (if available)

### Parameter Validation
- ✅ Baseline metrics file existence check
- ✅ Fine-tuned metrics file existence check
- ✅ Format validation (table/json/html)
- ✅ Output directory creation (with parent directories)

### Error Handling
- Clear error messages for missing files
- Invalid format rejection with available options
- Graceful handling of missing dependencies (matplotlib)
- Exception catching with informative error display

## Test Results

All 24 tests in `tests/test_compare.sh` pass with 100% success rate:

✅ **Test Suite 1: Help Text Validation** (1/1 passed)
✅ **Test Suite 2: Required Parameters Validation** (3/3 passed)
✅ **Test Suite 3: File Validation** (2/2 passed)
✅ **Test Suite 4: Format Validation** (4/4 passed)
✅ **Test Suite 5: Valid Command Execution** (2/2 passed)
✅ **Test Suite 6: Output Validation** (3/3 passed)
✅ **Test Suite 7: Optional Flags** (2/2 passed)
✅ **Test Suite 8: Combined Options** (1/1 passed)
✅ **Test Suite 9: Command Structure Validation** (2/2 passed)
✅ **Test Suite 10: Edge Cases and Special Values** (4/4 passed)

## Code Quality

- ✅ No linter errors (mypy, ruff)
- ✅ Full type annotations throughout
- ✅ Comprehensive docstrings
- ✅ Follows project style guidelines
- ✅ Uses Rich for formatted output
- ✅ Proper error handling and validation

## Integration

The compare command is fully integrated into the CLI:
- Available via `uv run model-experiments compare`
- Help accessible via `--help`
- Works seamlessly with output from `evaluate` command
- Outputs are machine-readable and human-friendly

## Example Output

### Table Format
```
                Model Performance Comparison                 
┏━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━┓
┃ Metric    ┃ Baseline ┃ Fine-Tuned ┃ Difference ┃ % Change ┃
┡━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━┩
│ Accuracy  │   0.5210 │     0.8600 │    +0.3390 │  +65.07% │
│ F1        │   0.4642 │     0.8599 │    +0.3957 │  +85.23% │
│ Precision │   0.5515 │     0.8604 │    +0.3090 │  +56.02% │
│ Recall    │   0.5210 │     0.8600 │    +0.3390 │  +65.07% │
└───────────┴──────────┴────────────┴────────────┴──────────┘
```

### Summary Output
```
Summary:
  Metrics improved: 4/4

Top Improvements:
  • F1: +85.23%
  • Accuracy: +65.07%
  • Recall: +65.07%
```

## Files Generated

When running with different options:

1. **Table Format**: Console output only
2. **JSON Format**: `comparison.json` with structured data
3. **HTML Report**: `report.html` with formatted report
4. **Plots**: `plots/comparison.png` with visualization charts

## Dependencies

- **typer**: CLI framework (already required)
- **rich**: Terminal formatting (already required)
- **matplotlib** (optional): For plot generation
- **numpy** (optional): For plot generation

## Future Enhancements

Potential improvements for future versions:
- Support for additional output formats (CSV, PDF)
- More advanced statistical analysis
- Confidence intervals
- Multiple model comparison
- Historical tracking of improvements
- Custom metric weighting

## Status

✅ **IMPLEMENTATION COMPLETE**

All required functionality has been implemented and tested. The compare command is production-ready and fully integrated with the CLI framework.
