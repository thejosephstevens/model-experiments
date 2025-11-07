#!/bin/bash
# =============================================================================
# Bootstrap Script for Model Experiments Framework
# =============================================================================
# This script installs all necessary dependencies and sets up the environment
# so you can run training locally.
#
# Usage: ./bootstrap.sh
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

print_header "🚀 Model Experiments Framework - Bootstrap"

echo "This script will:"
echo "  1. Install uv (Python package manager)"
echo "  2. Install all project dependencies (uv manages Python 3.12+ automatically)"
echo "  3. Verify the installation"
echo "  4. Install PyTorch (CPU or GPU based on your hardware)"
echo ""
echo "After completion, you'll be ready to run training locally!"
echo ""

# Ask for confirmation
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# =============================================================================
# Step 1: Check and Install UV
# =============================================================================

print_header "📦 Step 1: Installing UV Package Manager"

if command_exists uv; then
    UV_VERSION=$(uv --version 2>/dev/null || echo "unknown")
    print_success "uv is already installed: $UV_VERSION"
else
    print_info "Installing uv..."
    
    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            print_info "Using Homebrew to install uv..."
            brew install uv
        else
            print_info "Using curl to install uv..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        print_info "Using curl to install uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        print_error "Unsupported OS: $OSTYPE"
        print_info "Please install uv manually from: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
    
    # Add uv to PATH for current session if it was installed to ~/.cargo/bin
    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Verify installation
    if command_exists uv; then
        UV_VERSION=$(uv --version)
        print_success "uv installed successfully: $UV_VERSION"
    else
        print_error "Failed to install uv"
        print_info "Please install manually from: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
fi

# =============================================================================
# Step 2: Install Dependencies
# =============================================================================

print_header "📚 Step 2: Installing Project Dependencies"

print_info "uv will automatically manage Python version (3.12+)"
echo ""

print_info "Running: uv sync"
echo ""

# Install dependencies (CPU version by default)
uv sync

print_success "Dependencies installed successfully!"

# =============================================================================
# Step 3: Verify Installation
# =============================================================================

print_header "✅ Step 3: Verifying Installation"

# Check if CLI is accessible
if uv run model-experiments --help >/dev/null 2>&1; then
    print_success "CLI is working correctly"
else
    print_error "CLI verification failed"
    exit 1
fi

# Check if we can import key libraries
print_info "Checking key dependencies..."

uv run python -c "
import sys
try:
    import transformers
    import datasets
    import sklearn
    import typer
    import rich
    print('✓ All key dependencies imported successfully')
    sys.exit(0)
except ImportError as e:
    print(f'✗ Failed to import: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    print_success "All key dependencies verified"
else
    print_error "Dependency verification failed"
    exit 1
fi

# =============================================================================
# Step 4: PyTorch Installation
# =============================================================================

print_header "🎮 Step 4: Installing PyTorch"

echo "Do you have a compatible NVIDIA GPU with CUDA support?"
echo ""
read -p "Install GPU version? (y/n) " -n 1 -r
echo ""
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing PyTorch with GPU support..."
    uv sync --extra torch-gpu
    print_success "PyTorch GPU version installed"
    echo ""
    print_warning "Note: Ensure you have CUDA 12.1+ drivers installed on your system"
else
    print_info "Installing PyTorch CPU-only version..."
    uv sync --extra torch-cpu
    print_success "PyTorch CPU version installed"
fi

# =============================================================================
# COMPLETION
# =============================================================================

print_header "🎉 Bootstrap Complete!"

echo "Your environment is now set up and ready to use!"
echo ""
echo "Next steps:"
echo ""
echo "  1. Run the quick demo (5 minutes):"
echo "     ${GREEN}./quick_demo.sh${NC}"
echo ""
echo "  2. Or run a custom training job:"
echo "     ${GREEN}uv run model-experiments --help${NC}"
echo ""
echo "  3. Check out the documentation:"
echo "     ${GREEN}cat README.md${NC}"
echo "     ${GREEN}cat USAGE.md${NC}"
echo ""
echo "For more information:"
echo "  - Documentation: ./docs/"
echo "  - Test suite: ./tests/"
echo "  - Full demo: ./demo_usage.sh"
echo ""

print_success "Happy experimenting! 🚀"
echo ""

# =============================================================================
# Optional: Shell Profile Setup
# =============================================================================

# Check if uv needs to be added to shell profile
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    echo ""
    print_warning "Note: uv was installed to ~/.cargo/bin"
    print_info "You may need to add it to your PATH by adding this to your shell profile:"
    echo ""
    echo "  ${YELLOW}export PATH=\"\$HOME/.cargo/bin:\$PATH\"${NC}"
    echo ""
    
    # Detect shell and suggest profile file
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "  For zsh, add to: ${YELLOW}~/.zshrc${NC}"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "  For bash, add to: ${YELLOW}~/.bashrc${NC} or ${YELLOW}~/.bash_profile${NC}"
    fi
    echo ""
fi

