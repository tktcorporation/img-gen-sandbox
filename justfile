# Flux2 Image Generation - Task Runner
# Usage: just <command>

# Default: show help
default:
    @just --list

# Set shell for recipes
set shell := ["bash", "-cu"]

# Variables
venv := ".venv"
python := venv + "/bin/python"
uv := "uv"

# ====================
# Setup Commands
# ====================

# Create virtual environment and install dependencies
setup:
    @echo "Creating virtual environment with uv..."
    {{uv}} venv {{venv}} --python python3.12
    @echo ""
    @echo "Installing dependencies..."
    {{uv}} pip install -e . --python {{venv}}/bin/python
    @echo ""
    @echo "Setup complete!"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Login to Hugging Face: just login"
    @echo "  2. Generate an image: just generate \"your prompt\""

# Install development dependencies
setup-dev: setup
    {{uv}} pip install -e ".[dev]" --python {{venv}}/bin/python

# Login to Hugging Face
login:
    {{venv}}/bin/huggingface-cli login

# Check Hugging Face authentication status
auth-status:
    {{venv}}/bin/huggingface-cli whoami

# ====================
# Generation Commands
# ====================

# Generate an image with a prompt
generate prompt output="output.png" model="black-forest-labs/FLUX.1-schnell":
    {{python}} generate.py "{{prompt}}" -o "{{output}}" -m "{{model}}"

# Generate with FLUX.1-schnell (fast, 4 steps)
generate-fast prompt output="output.png":
    {{python}} generate.py "{{prompt}}" -o "{{output}}" \
        -m "black-forest-labs/FLUX.1-schnell" \
        --steps 4 --guidance 0.0

# Generate with FLUX.1-dev (high quality, 20 steps)
generate-quality prompt output="output.png":
    {{python}} generate.py "{{prompt}}" -o "{{output}}" \
        -m "black-forest-labs/FLUX.1-dev" \
        --steps 20 --guidance 3.5

# Generate high resolution image (768x768)
generate-hires prompt output="output.png":
    {{python}} generate.py "{{prompt}}" -o "{{output}}" \
        --width 768 --height 768

# ====================
# Utility Commands
# ====================

# Check MPS (Metal) availability
check-mps:
    {{python}} -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'MPS available: {torch.backends.mps.is_available()}')"

# Check all dependencies
check-deps:
    {{python}} -c "import torch, diffusers, transformers; print('All dependencies OK')"

# Run linter
lint:
    {{venv}}/bin/ruff check .

# Format code
fmt:
    {{venv}}/bin/ruff format .

# Clean generated files and cache
clean:
    rm -rf {{venv}}
    rm -rf __pycache__ .mypy_cache .ruff_cache
    rm -rf *.egg-info
    rm -f output.png

# Deep clean including model cache (warning: will re-download models)
clean-all: clean
    rm -rf ~/.cache/huggingface/hub/models--black-forest-labs*
    @echo "Model cache cleaned. Models will be re-downloaded on next run."

# ====================
# Info Commands
# ====================

# Show environment info
info:
    @echo "=== Environment Info ==="
    @echo "Python: $({{python}} --version 2>&1)"
    @echo "PyTorch: $({{python}} -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not installed')"
    @echo "Diffusers: $({{python}} -c 'import diffusers; print(diffusers.__version__)' 2>/dev/null || echo 'Not installed')"
    @echo "MPS: $({{python}} -c 'import torch; print(torch.backends.mps.is_available())' 2>/dev/null || echo 'N/A')"
    @echo "CUDA: $({{python}} -c 'import torch; print(torch.cuda.is_available())' 2>/dev/null || echo 'N/A')"

# Show disk usage for models
disk-usage:
    @echo "=== Model Cache Size ==="
    @du -sh ~/.cache/huggingface/hub/models--black-forest-labs* 2>/dev/null || echo "No models cached yet"

# ====================
# Browser Automation
# ====================

# Get Playwright Chromium executable path
chromium-path:
    @ls ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome 2>/dev/null | head -1 || \
        echo "$PLAYWRIGHT_BROWSERS_PATH/chromium-*/chrome-linux/chrome" | head -1

# ====================
# Devenv Commands
# ====================

# Run create-devenv CLI
create-devenv:
    npx @tktco/create-devenv@latest

# Reinstall npm global packages
reinstall-npm:
    rm -f .npm-global/.installed
    @echo "Run 'nix develop' or 'direnv reload' to reinstall npm packages"
