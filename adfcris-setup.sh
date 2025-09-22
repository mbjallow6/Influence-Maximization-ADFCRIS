#!/bin/bash

# =============================================================================
# ADFCRIS: Unified High-Performance & Secure Project Setup Script (v3 - FINAL)
# =============================================================================
# Uses a 3-stage installation process for maximum speed and reliability.
# 1. Core GPU env (PyTorch/CUDA)
# 2. Main tools from conda-forge
# 3. PyG from pip
# =============================================================================

set -euo pipefail

# --- Configuration ---
CONDA_ENV_NAME="adfcris"
ENV_FILE="environment.yml"
SETUP_LOG="adfcris-setup-$(date +%Y%m%d-%H%M%S).log"

# CRITICAL FIX: These versions MUST be correct and consistent.
PYTORCH_VERSION="2.1.0"
CUDA_VERSION="cu121" # Corresponds to pytorch-cuda=12.1

# --- Pretty Printing ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# --- Error Handling & Cleanup ---
cleanup_on_error() {
    print_error "Setup failed. To clean up, run: conda env remove -n $CONDA_ENV_NAME -y"
    print_error "Please check the log file: $SETUP_LOG"
    exit 1
}
trap cleanup_on_error ERR

# --- Main Setup Functions ---

function setup_core_environment() {
    print_header "STAGE 1: CREATING CORE '$CONDA_ENV_NAME' GPU ENVIRONMENT"
    if conda env list | grep -q "^$CONDA_ENV_NAME "; then
        print_info "Removing existing environment for a clean install..."
        conda env remove -n "$CONDA_ENV_NAME" -y
    fi
    print_info "Creating base PyTorch/CUDA environment with Mamba from '$ENV_FILE'..."
    mamba env create -f "$ENV_FILE"
    print_success "Core GPU environment created successfully."
}

function install_conda_packages() {
    print_header "STAGE 2: INSTALLING MAIN SCIENTIFIC PACKAGES"
    print_info "Adding packages from conda-forge. This may take a few minutes..."
    mamba install -n "$CONDA_ENV_NAME" -c conda-forge --yes \
        'numpy>=1.21.0' 'scipy>=1.7.0' 'pandas>=1.3.0' 'networkx>=2.8.0' \
        'scikit-learn>=1.1.0' 'numba>=0.56.0' 'ray-default>=2.0.0' \
        'dask>=2022.8.0' 'joblib>=1.1.0' 'psutil>=5.8.0' 'htop' 'gpustat' \
        'matplotlib>=3.5.0' 'seaborn>=0.11.0' 'plotly>=5.10.0' \
        'jupyterlab>=3.4.0' 'ipykernel' 'black>=22.0.0' 'flake8>=5.0.0' \
        'pytest>=7.0.0' 'pre-commit>=2.20.0' 'sphinx>=5.0.0' \
        'sphinx-rtd-theme>=1.0.0' 'git-lfs' 'dvc>=2.12.0' 'graph-tool'
    print_success "Main packages installed."
}

function install_pip_packages() {
    print_header "STAGE 3: INSTALLING PIP-SPECIFIC PACKAGES"
    print_info "Installing PyG and other packages with pip..."
    
    # Install PyG and its dependencies matching the PyTorch and CUDA versions
    conda run -n "$CONDA_ENV_NAME" pip install --no-cache-dir \
        "torch-scatter" "torch-sparse" "torch-cluster" "torch-spline-conv" "torch-geometric" \
        -f "https://data.pyg.org/whl/torch-${PYTORCH_VERSION}+${CUDA_VERSION}.html"

    # Install other pip packages
    conda run -n "$CONDA_ENV_NAME" pip install --no-cache-dir \
        'wandb>=0.13.0' 'mlflow>=1.28.0' 'hydra-core>=1.2.0' 'optuna>=3.0.0' \
        'memory_profiler>=0.60.0' 'line-profiler' 'py-spy' 'python-igraph'

    print_success "Pip packages installed successfully."
}

# The utility functions (create_project_structure, configure_git, etc.) remain unchanged.
# They are included here for completeness.
function create_project_structure() {
    print_header "BUILDING PROJECT STRUCTURE"
    mkdir -p src/adfcris/{core,utils,benchmarks,evaluation} tests/{unit,integration,benchmarks} \
             data/{raw,processed,synthetic} experiments/{configs,scripts,results} \
             docs/{api,tutorials} paper/{figures,tables,manuscript} notebooks
    find src/adfcris -type d -exec touch {}/__init__.py \;
    print_success "Project structure created."
}
function configure_git() {
    print_header "CONFIGURING GIT"
    if [ ! -d .git ]; then
        print_info "Initializing Git repository..."
        git init && git branch -M main
    fi
    print_info "Creating .gitignore and setting up Git LFS..."
    cat > .gitignore << 'EOF'
__pycache__/, *.py[cod], .Python, *.so, *.egg-info/, dist/, build/, venv/, env/
.ipynb_checkpoints/, .idea/, .vscode/, *.swp
data/, *.pkl, *.h5, *.hdf5, *.pt, *.pth, *.npz
experiments/results/, *.log, logs/, .wandb/, mlruns/
.DS_Store, Thumbs.db, *.tmp, .env, *.key
EOF
    git lfs install
    git lfs track "*.h5" "*.hdf5" "*.pkl" "*.pt" "*.pth" "*.npz"
    print_success "Git configured."
}
function create_dev_tools() {
    print_header "CREATING DEVELOPMENT FILES"
    # Makefile, pre-commit, README, setup.py
    cat > Makefile << 'EOF'
.PHONY: help install test format lint jupyter clean
SHELL := /bin/bash
CONDA_ENV := adfcris
CONDA_RUN := conda run -n $(CONDA_ENV)
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
install: ## Install package in editable mode
	$(CONDA_RUN) pip install -e .
test: ## Run tests
	$(CONDA_RUN) pytest tests/ -v
format: ## Format code
	$(CONDA_RUN) black src/ tests/
lint: ## Lint code
	$(CONDA_RUN) flake8 src/ tests/
jupyter: ## Start Jupyter Lab
	$(CONDA_RUN) jupyter lab --ip=0.0.0.0 --port=8889 --no-browser
EOF
    cat > .pre-commit-config.yaml << 'EOF'
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.4.0
  hooks:
  - id: trailing-whitespace
  - id: end-of-file-fixer
- repo: https://github.com/psf/black
  rev: 22.12.0
  hooks:
  - id: black
EOF
    cat > README.md << 'EOF'
# ADFCRIS - Quick Start
1.  **Run Setup**: `./setup-project.sh`
2.  **Activate**: `conda activate adfcris`
3.  **Install Package**: `make install`
EOF
    cat > setup.py << 'EOF'
from setuptools import setup, find_packages
setup(name="adfcris", version="0.1.0", packages=find_packages(where="src"), package_dir={"": "src"})
EOF
    print_success "Development files created."
}
function finalize_setup() {
    print_header "FINALIZING SETUP"
    (
        source ~/miniconda3/etc/profile.d/conda.sh
        conda activate "$CONDA_ENV_NAME"
        print_info "Installing pre-commit hooks..."
        pre-commit install
        print_info "Installing 'adfcris' package in editable mode..."
        pip install -e .
    )
    print_success "Finalization complete."
}


# =============================================================================
# MAIN EXECUTION
# =============================================================================
function main() {
    exec > >(tee -a "$SETUP_LOG") 2>&1
    echo "🚀 Starting ADFCRIS 3-Stage Project Setup..."
    echo "========================================================"
    
    setup_core_environment
    install_conda_packages
    install_pip_packages
    
    create_project_structure
    configure_git
    create_dev_tools
    finalize_setup

    trap - ERR

    print_header "🎉 SETUP COMPLETED SUCCESSFULLY! 🎉"
    echo "Your environment is ready."
    echo ""
    echo "--> NEXT STEP: Activate the environment with: ${YELLOW}conda activate $CONDA_ENV_NAME${NC}"
    echo ""
}

main "$@"