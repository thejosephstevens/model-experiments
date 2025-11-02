#!/bin/bash
set -e  # Exit on error

# =============================================================================
# Model Fine-Tuning Framework - Demo Usage Script
# =============================================================================
# This script demonstrates the complete workflow for fine-tuning a model:
# 1. Download dataset
# 2. Split into train/validation sets (90%/10%)
# 3. Download base model
# 4. Train the model on training data
# 5. Evaluate both original and fine-tuned models on validation data
# 6. Compare performance metrics
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Model Fine-Tuning Framework - Demo Workflow           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
DATASET_NAME="imdb"  # Example: IMDB sentiment analysis dataset
MODEL_NAME="distilbert-base-uncased"  # Small, fast model for demo
TRAIN_SPLIT="0.9"
VAL_SPLIT="0.1"
OUTPUT_DIR="./outputs"
DATA_DIR="./data"
MAX_SAMPLES="1000"  # Limit for faster demo
EPOCHS="3"

echo "Configuration:"
echo "  Dataset: $DATASET_NAME"
echo "  Model: $MODEL_NAME"
echo "  Train/Val Split: ${TRAIN_SPLIT}/${VAL_SPLIT}"
echo "  Output Directory: $OUTPUT_DIR"
echo "  Max Samples: $MAX_SAMPLES"
echo "  Training Epochs: $EPOCHS"
echo ""

# =============================================================================
# Step 1: Download Dataset
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/6: Downloading dataset..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
uv run model-experiments dataset download \
    --name "$DATASET_NAME" \
    --output-dir "$DATA_DIR" \
    --max-samples "$MAX_SAMPLES" \
    --cache-dir "$DATA_DIR/cache"

echo "✓ Dataset downloaded successfully"
echo ""

# =============================================================================
# Step 2: Split Dataset
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/6: Splitting dataset into train/validation sets..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
uv run model-experiments dataset split \
    --input-path "$DATA_DIR/$DATASET_NAME" \
    --output-dir "$DATA_DIR/splits" \
    --train-ratio "$TRAIN_SPLIT" \
    --val-ratio "$VAL_SPLIT" \
    --seed 42 \
    --stratify

echo "✓ Dataset split completed"
echo "  Training set: ${TRAIN_SPLIT} of data"
echo "  Validation set: ${VAL_SPLIT} of data"
echo ""

# =============================================================================
# Step 3: Download Model
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/6: Downloading base model..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
uv run model-experiments model download \
    --name "$MODEL_NAME" \
    --output-dir "$OUTPUT_DIR/models/base" \
    --cache-dir "$OUTPUT_DIR/cache"

echo "✓ Base model downloaded successfully"
echo ""

# =============================================================================
# Step 4: Train Model
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4/6: Fine-tuning model on training data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
uv run model-experiments train \
    --model-name "$MODEL_NAME" \
    --train-data "$DATA_DIR/splits/train.jsonl" \
    --val-data "$DATA_DIR/splits/val.jsonl" \
    --output-dir "$OUTPUT_DIR/models/fine-tuned" \
    --epochs "$EPOCHS" \
    --batch-size 16 \
    --learning-rate 2e-5 \
    --warmup-steps 100 \
    --save-steps 500 \
    --logging-steps 50 \
    --eval-steps 250 \
    --max-length 512 \
    --gradient-accumulation-steps 2 \
    --fp16 \
    --seed 42

echo "✓ Model fine-tuning completed"
echo ""

# =============================================================================
# Step 5: Evaluate Models
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5/6: Evaluating models on validation data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Evaluating original base model..."
uv run model-experiments evaluate \
    --model-path "$OUTPUT_DIR/models/base" \
    --test-data "$DATA_DIR/splits/val.jsonl" \
    --output-file "$OUTPUT_DIR/metrics/base_model_metrics.json" \
    --batch-size 32 \
    --max-length 512 \
    --metrics accuracy f1 precision recall \
    --log-predictions "$OUTPUT_DIR/predictions/base_predictions.jsonl"

echo "✓ Base model evaluation completed"
echo ""

echo "Evaluating fine-tuned model..."
uv run model-experiments evaluate \
    --model-path "$OUTPUT_DIR/models/fine-tuned" \
    --test-data "$DATA_DIR/splits/val.jsonl" \
    --output-file "$OUTPUT_DIR/metrics/fine_tuned_metrics.json" \
    --batch-size 32 \
    --max-length 512 \
    --metrics accuracy f1 precision recall \
    --log-predictions "$OUTPUT_DIR/predictions/fine_tuned_predictions.jsonl"

echo "✓ Fine-tuned model evaluation completed"
echo ""

# =============================================================================
# Step 6: Compare Performance
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6/6: Comparing model performance..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
uv run model-experiments compare \
    --baseline-metrics "$OUTPUT_DIR/metrics/base_model_metrics.json" \
    --fine-tuned-metrics "$OUTPUT_DIR/metrics/fine_tuned_metrics.json" \
    --output-dir "$OUTPUT_DIR/comparison" \
    --generate-plots \
    --format table \
    --save-report

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Workflow Complete!                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Results Summary:"
echo "  • Base model metrics: $OUTPUT_DIR/metrics/base_model_metrics.json"
echo "  • Fine-tuned metrics: $OUTPUT_DIR/metrics/fine_tuned_metrics.json"
echo "  • Comparison report: $OUTPUT_DIR/comparison/report.html"
echo "  • Training logs: $OUTPUT_DIR/models/fine-tuned/logs/"
echo ""
echo "To view the comparison report:"
echo "  open $OUTPUT_DIR/comparison/report.html"
echo ""

