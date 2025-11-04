# PyTorch Installation Guide

This guide explains how to install PyTorch to enable the `model download` subcommand.

## Overview

PyTorch is required for downloading and using pre-trained models from HuggingFace Hub. The model-experiments framework provides optional dependency groups to easily install PyTorch.

## Quick Start

### CPU-Only Installation (Recommended)

```bash
uv sync --extra torch-cpu
```

This installs PyTorch CPU version, which is:
- ✅ Lightweight (~2GB)
- ✅ Fast to install
- ✅ Good for inference
- ✅ Works on any machine
- ❌ Slower than GPU for training

### GPU Installation (CUDA)

For NVIDIA GPU support:

```bash
# CUDA 12.1 (recommended for newer GPUs)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# CUDA 11.8 (for older GPUs)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

Then sync with uv:
```bash
uv sync --extra torch-gpu
```

> **Note:** GPU installation requires NVIDIA drivers and CUDA toolkit to be installed separately.

## Installation Methods

### Method 1: Using `uv sync` (Recommended)

#### CPU Version:
```bash
uv sync --extra torch-cpu
```

#### GPU Version (after installing CUDA):
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
uv sync --extra torch-gpu
```

### Method 2: Using `uv pip`

#### CPU Version:
```bash
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
```

#### GPU Version (CUDA 12.1):
```bash
uv pip install torch --index-url https://download.pytorch.org/whl/cu121
```

### Method 3: Direct pip (without uv)

```bash
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

## Verification

After installation, verify PyTorch is working:

```bash
uv run python -c "import torch; print(f'PyTorch {torch.__version__} installed')"
```

You should see output like:
```
PyTorch 2.1.0 installed
```

## Testing Model Download

Once PyTorch is installed, test the model download:

```bash
# Create a test directory
mkdir -p ./test_models

# Download a small model
uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./test_models/distilbert
```

Expected output:
```
Downloading model: distilbert-base-uncased
Output directory: test_models/distilbert
⠋ Downloading model from HuggingFace Hub...
✓ Model downloaded successfully
⠙ Downloading tokenizer from HuggingFace Hub...
✓ Tokenizer downloaded successfully
✓ Model and tokenizer saved to test_models/distilbert
Metadata saved to test_models/distilbert/model_metadata.json
```

## CUDA Installation Guide

### Check GPU Support

```bash
nvidia-smi
```

If this command fails, you need to install NVIDIA drivers first.

### Installation Steps

1. **Install NVIDIA Drivers** (if not already installed)
   ```bash
   # macOS: Not needed (no NVIDIA GPU support)
   # Windows: Download from https://www.nvidia.com/Download/driverDetails.aspx
   # Linux: sudo apt install nvidia-driver-535 (or newer)
   ```

2. **Install CUDA Toolkit**
   - Download from: https://developer.nvidia.com/cuda-downloads
   - Choose your OS and version (12.1 recommended)
   - Follow installation instructions

3. **Verify CUDA Installation**
   ```bash
   nvcc --version
   ```

4. **Install PyTorch for CUDA**
   ```bash
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
   ```

5. **Verify GPU Support**
   ```bash
   uv run python -c "import torch; print(f'GPU available: {torch.cuda.is_available()}')"
   ```

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'torch'"

**Solution:** Install PyTorch using one of the methods above.

### Issue: PyTorch installed but model download still fails

**Solution:** Ensure you're using `uv run` to execute commands:
```bash
uv run model-experiments model download --name bert-base-uncased --output-dir ./models
```

### Issue: "AutoModel requires the PyTorch library"

**Solution:** PyTorch is not installed. Run:
```bash
uv sync --extra torch-cpu
```

### Issue: CUDA-related errors when using GPU

**Solution:** Verify CUDA installation:
```bash
nvidia-smi
uv run python -c "import torch; print(torch.cuda.get_device_name(0))"
```

If issues persist, reinstall with correct CUDA version.

## System Requirements

### CPU-Only
- **Disk Space:** ~2GB for PyTorch + model
- **RAM:** 4GB minimum, 8GB recommended
- **Internet:** For downloading models

### GPU (CUDA)
- **GPU:** NVIDIA GPU with CUDA Compute Capability 3.5+
- **Disk Space:** ~4GB for PyTorch + model
- **RAM:** 8GB minimum, 16GB recommended
- **VRAM:** 2GB minimum for most models, 6GB+ recommended
- **CUDA:** Version 11.8 or 12.1
- **NVIDIA Drivers:** Updated drivers required

## Optional Dependencies Summary

| Name | Purpose | Size | Install Command |
|------|---------|------|-----------------|
| `torch-cpu` | CPU inference | ~2GB | `uv sync --extra torch-cpu` |
| `torch-gpu` | GPU acceleration | ~3GB | `pip install torch[cu121]` + `uv sync --extra torch-gpu` |
| `dev` | Development tools | ~500MB | `uv sync --extra dev` |

## Using with model-experiments

### Download a Model (CPU)

```bash
uv sync --extra torch-cpu

uv run model-experiments model download \
    --name distilbert-base-uncased \
    --output-dir ./models/distilbert
```

### Download a Model (GPU)

```bash
# Install CUDA version of PyTorch first
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

uv run model-experiments model download \
    --name bert-base-uncased \
    --output-dir ./models/bert
```

### Train a Model (Requires GPU for good performance)

```bash
uv run model-experiments train \
    --model-name bert-base-uncased \
    --train-data ./data/train.jsonl \
    --val-data ./data/val.jsonl \
    --output-dir ./output \
    --epochs 3
```

## Performance Tips

### For CPU Training
- Use smaller models: `prajjwal1/bert-tiny`, `distilbert-base-uncased`
- Reduce batch size: `--batch-size 4` or `--batch-size 8`
- Reduce epochs: `--epochs 1` for testing
- Use gradient accumulation: `--gradient-accumulation-steps 4`

### For GPU Training
- Use larger batch size: `--batch-size 32` or `--batch-size 64`
- Enable FP16: `--fp16` for faster training
- Use more epochs: `--epochs 3` or higher
- Monitor GPU: `nvidia-smi -l 1` in another terminal

## Model Sizes

| Model | Size | CPU Time | GPU Time |
|-------|------|----------|----------|
| `prajjwal1/bert-tiny` | 50MB | ~2 min | ~10 sec |
| `distilbert-base-uncased` | 300MB | ~10 min | ~30 sec |
| `bert-base-uncased` | 400MB | ~15 min | ~1 min |
| `bert-large-uncased` | 1.3GB | ~30 min | ~2 min |

## Next Steps

1. ✅ Install PyTorch
2. ✅ Verify installation
3. ✅ Download a model
4. 📖 Read [USAGE.md](./USAGE.md) for complete workflow
5. 🚀 Start downloading and training models

## Additional Resources

- **PyTorch Docs:** https://pytorch.org/docs/stable/index.html
- **HuggingFace Models:** https://huggingface.co/models
- **CUDA Toolkit:** https://developer.nvidia.com/cuda-toolkit
- **Project README:** [README.md](./README.md)

## Support

For issues:
1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [USAGE.md](./USAGE.md) for command examples
3. Check [README.md](./README.md) for project overview

---

**Last Updated:** 2025
**PyTorch Version:** 2.0.0+
**Python Version:** 3.12+
