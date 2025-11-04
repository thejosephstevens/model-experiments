#!/bin/bash
# Test script to demonstrate caching functionality

set -e

echo "=========================================="
echo "Testing Model Download Caching"
echo "=========================================="
echo ""

# Clean up any existing test data
echo "Cleaning up test directories..."
rm -rf ./test_cache_model ./test_cache_dataset
echo ""

# Test 1: First model download (should download)
echo "Test 1: First model download (should download from HuggingFace)"
echo "-----------------------------------------------------------"
uv run model-experiments model download \
    --name prajjwal1/bert-tiny \
    --output-dir ./test_cache_model
echo ""

# Test 2: Second model download (should use cache)
echo "Test 2: Second model download (should use cache)"
echo "-----------------------------------------------------------"
uv run model-experiments model download \
    --name prajjwal1/bert-tiny \
    --output-dir ./test_cache_model
echo ""

# Test 3: Force re-download
echo "Test 3: Force re-download (should re-download despite cache)"
echo "-----------------------------------------------------------"
uv run model-experiments model download \
    --name prajjwal1/bert-tiny \
    --output-dir ./test_cache_model \
    --force
echo ""

echo "=========================================="
echo "Testing Dataset Download Caching"
echo "=========================================="
echo ""

# Test 4: First dataset download (should download)
echo "Test 4: First dataset download (should download from HuggingFace)"
echo "-----------------------------------------------------------"
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./test_cache_dataset \
    --max-samples 100
echo ""

# Test 5: Second dataset download (should use cache)
echo "Test 5: Second dataset download (should use cache)"
echo "-----------------------------------------------------------"
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./test_cache_dataset \
    --max-samples 100
echo ""

# Test 6: Different max-samples (should re-download)
echo "Test 6: Different max-samples (should re-download)"
echo "-----------------------------------------------------------"
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./test_cache_dataset \
    --max-samples 200
echo ""

# Test 7: Force re-download
echo "Test 7: Force re-download (should re-download despite cache)"
echo "-----------------------------------------------------------"
uv run model-experiments dataset download \
    --name imdb \
    --output-dir ./test_cache_dataset \
    --max-samples 200 \
    --force
echo ""

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
echo ""
echo "Checking cached files:"
echo "Model cache:"
ls -lh ./test_cache_model/ | head -10
echo ""
echo "Dataset cache:"
ls -lh ./test_cache_dataset/ | head -10

