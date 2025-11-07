#!/bin/bash
set -e

# =============================================================================
# Quick Demo - Minimal example with default settings
# =============================================================================

echo "🚀 Running quick demo with minimal configuration..."
echo ""

# Use small defaults for fast execution
DATASET="ag_news"  # Small news classification dataset
MODEL="prajjwal1/bert-tiny"  # Smallest BERT variant
OUTPUT="./demo_output"

echo "Configuration: Dataset=$DATASET, Model=$MODEL"
echo ""

# 1. Download dataset
echo "📥 Downloading dataset..."
uv run model-experiments dataset download --name "$DATASET" --output-dir "$OUTPUT/data" --max-samples 500

# 2. Download model
echo "📦 Downloading model..."
uv run model-experiments model download --name "$MODEL" --output-dir "$OUTPUT/models/base"

# 3. Train model
echo "🏋️  Training model..."
uv run model-experiments train \
    --model-name "$MODEL" \
    --train-data "$OUTPUT/data/train/data.jsonl" \
    --val-data "$OUTPUT/data/test/data.jsonl" \
    --output-dir "$OUTPUT/models/fine-tuned" \
    --epochs 2 \
    --batch-size 16

# 4. Evaluate both models
echo "📊 Evaluating base model..."
uv run model-experiments evaluate \
    --model-path "$OUTPUT/models/base" \
    --test-data "$OUTPUT/data/test/data.jsonl" \
    --output-file "$OUTPUT/metrics/base.json"

echo "📊 Evaluating fine-tuned model..."
uv run model-experiments evaluate \
    --model-path "$OUTPUT/models/fine-tuned" \
    --test-data "$OUTPUT/data/test/data.jsonl" \
    --output-file "$OUTPUT/metrics/fine_tuned.json"

# 5. Compare performance
echo "📈 Comparing performance..."
uv run model-experiments compare \
    --baseline-metrics "$OUTPUT/metrics/base.json" \
    --fine-tuned-metrics "$OUTPUT/metrics/fine_tuned.json" \
    --output-dir "$OUTPUT/comparison"

echo ""
echo "✅ Demo complete! Check $OUTPUT/comparison/ for results"

