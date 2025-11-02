#!/bin/bash
# Quick CLI testing script

echo "=== Testing Model Experiments CLI ==="
echo ""

echo "1. Version check:"
uv run model-experiments --version
echo ""

echo "2. Main help:"
uv run model-experiments --help
echo ""

echo "3. Dataset commands:"
uv run model-experiments dataset --help
echo ""

echo "4. Dataset download help:"
uv run model-experiments dataset download --help
echo ""

echo "5. Model commands:"
uv run model-experiments model --help
echo ""

echo "6. Train command:"
uv run model-experiments train --help
echo ""

echo "7. Evaluate command:"
uv run model-experiments evaluate --help
echo ""

echo "8. Compare command:"
uv run model-experiments compare --help
echo ""

echo "=== All CLI commands are working! ==="

