#!/bin/bash

# =============================================================================
# ADFCRIS: Hardware-Aware Project Setup Script (v4.2 - FINAL)
# =============================================================================
# Detects GPU presence and uses a 3-stage installation for speed and reliability.
# Creates a complete, professional research project structure from scratch.
# =============================================================================

set -euo pipefail

# --- Configuration ---
CONDA_ENV_NAME="adfcris"
SETUP_LOG="adfcris-setup-$(date +%Y%m%d-%H%M%S).log"
PYTORCH_VERSION="2.1.0"
# --- Variables to be set by GPU detection ---
ENV_FILE=""
CUDA_VERSION=""

# --- Pretty Printing ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
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

# --- Hardware Detection ---
function detect_hardware() {
    print_header "DETECTING HARDWARE"
    if command -v nvidia-smi &> /dev/null; then
        print_success "NVIDIA GPU detected. Configuring for GPU environment."
        ENV_FILE="environment-gpu.yml"
        CUDA_VERSION="cu121"
    else
        print_info "No NVIDIA GPU detected. Configuring for CPU-only environment."
        ENV_FILE="environment-cpu.yml"
        CUDA_VERSION="cpu"
    fi

    if [ ! -f "$ENV_FILE" ]; then
        print_error "Required environment file '$ENV_FILE' not found. Aborting."
        exit 1
    fi
}

# --- Main Setup Functions ---
function create_core_environment() {
    print_header "STAGE 1: CREATING CORE '$CONDA_ENV_NAME' ENVIRONMENT"
    if conda env list | grep -q "^$CONDA_ENV_NAME "; then
        print_info "Removing existing environment for a clean install..."
        conda env remove -n "$CONDA_ENV_NAME" -y
    fi
    print_info "Creating base environment with Mamba from '$ENV_FILE'..."
    mamba env create -f "$ENV_FILE"
    print_success "Core environment created successfully."
}

function install_conda_packages() {
    print_header "STAGE 2: INSTALLING MAIN SCIENTIFIC PACKAGES"
    print_info "Adding packages from conda-forge..."
    mamba install -n "$CONDA_ENV_NAME" -c conda-forge --yes \
        'numpy>=1.21.0' 'scipy>=1.7.0' 'pandas>=1.3.0' 'networkx>=2.8.0' \
        'scikit-learn>=1.1.0' 'numba>=0.56.0' 'ray-default>=2.0.0' 'dask' \
        'joblib>=1.1.0' 'psutil>=5.8.0' 'htop' 'gpustat' 'matplotlib' \
        'seaborn' 'plotly' 'jupyterlab' 'ipykernel' 'black>=22.0.0' \
        'flake8>=5.0.0' 'pytest' 'pytest-cov' 'pre-commit' 'sphinx' \
        'sphinx-rtd-theme' 'git-lfs' 'dvc' 'graph-tool' 'gh'
    print_success "Main packages installed."
}

function install_pip_packages() {
    print_header "STAGE 3: INSTALLING PIP-SPECIFIC PACKAGES"
    print_info "Installing PyG and other packages with pip..."

    local pyg_url="https://data.pyg.org/whl/torch-${PYTORCH_VERSION}+${CUDA_VERSION}.html"
    print_info "Using PyG wheel source: $pyg_url"

    conda run -n "$CONDA_ENV_NAME" pip install --no-cache-dir \
        "torch-scatter" "torch-sparse" "torch-cluster" "torch-spline-conv" "torch-geometric" \
        -f "$pyg_url"

    conda run -n "$CONDA_ENV_NAME" pip install --no-cache-dir \
        'wandb' 'mlflow' 'hydra-core' 'optuna' 'memory_profiler' \
        'line-profiler' 'py-spy' 'python-igraph' 'python-dotenv'

    print_success "Pip packages installed successfully."
}

function create_project_structure() {
    print_header "BUILDING PROJECT STRUCTURE"
    mkdir -p src/adfcris/{core,utils,benchmarks,evaluation} \
             tests/{unit,integration,benchmarks} \
             data/{raw,processed,synthetic} \
             experiments/{configs,scripts,results} \
             docs/{api,tutorials} \
             paper/{figures,tables,manuscript} \
             notebooks scripts

    touch data/raw/.gitkeep data/processed/.gitkeep data/synthetic/.gitkeep
    find src/adfcris -type d -exec touch {}/__init__.py \;
    print_success "Project structure created."
}

function configure_git() {
    print_header "CONFIGURING GIT"
    if [ ! -d .git ]; then
        git init && git branch -M main
    fi
    print_info "Setting up Git LFS..."
    # Activate conda env in a subshell to ensure git-lfs is found
    # Temporarily disable 'set -u' to prevent MKL script error
    (
        set +u
        source "${HOME}/miniconda3/etc/profile.d/conda.sh"
        conda activate "$CONDA_ENV_NAME"
        set -u
        git lfs install
        git lfs track "*.h5" "*.hdf5" "*.pkl" "*.pt" "*.pth" "*.npz"
    )
    print_success "Git configured."
}

function create_dev_tools() {
    print_header "CREATING DEVELOPMENT FILES"

    print_info "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# ============== Python ==============
__pycache__/
*.py[cod]
*.so

# ============== Environment & Packaging ==============
.env
.venv
env/
venv/
dist/
build/
*.egg-info/

# ============== IDEs & Editor Files ==============
.idea/
.vscode/
*.swp
.ipynb_checkpoints/

# ============== Testing & Caching ==============
.pytest_cache/
.coverage

# ============== Data & Models (Track folders with .gitkeep, not content) ==============
data/raw/*
data/processed/*
data/synthetic/*
!data/raw/.gitkeep
!data/processed/.gitkeep
!data/synthetic/.gitkeep
*.pkl
*.h5
*.hdf5
*.pt
*.pth
*.npz

# ============== Logs & Experiment Results ==============
experiments/results/
logs/
*.log
mlruns/
.wandb/

# ============== OS-specific Files ==============
.DS_Store
Thumbs.db
EOF

    print_info "Creating Makefile..."
    cat > Makefile << 'EOF'
.PHONY: help install test format lint jupyter
SHELL := /bin/bash
CONDA_ENV := adfcris
CONDA_RUN := conda run -n $(CONDA_ENV)
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
install: ## Install package in editable mode
	$(CONDA_RUN) pip install -e .
test: ## Run test suite with coverage
	$(CONDA_RUN) pytest --cov=src/adfcris tests/ -v
format: ## Format code
	$(CONDA_RUN) black src/ tests/
lint: ## Lint code
	$(CONDA_RUN) flake8 src/ tests/
jupyter: ## Start Jupyter Lab
	$(CONDA_RUN) jupyter lab --ip=0.0.0.0 --port=8889 --no-browser
EOF

    print_info "Creating .pre-commit-config.yaml..."
    cat > .pre-commit-config.yaml << 'EOF'
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
-   repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
    -   id: black
-   repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
    -   id: flake8
EOF

    print_info "Creating README.md..."
    cat > README.md << 'EOF'
# ADFCRIS - Advanced Distributed Fair-Competitive RIS

## Quick Start

1.  **Run Setup**: `bash scripts/setup-project.sh`
2.  **Activate**: `conda activate adfcris`
3.  **Install Package**: `make install`
4.  **Run Tests**: `make test`

See `docs/` for detailed documentation.
EOF

    print_info "Creating setup.py..."
    cat > setup.py << 'EOF'
from setuptools import setup, find_packages
setup(
    name="adfcris",
    version="0.1.0",
    author="Momodou Jallow",
    description="A high-performance implementation of the ADFCRIS algorithm.",
    url="https://github.com/mbjallow6/Influence-Maximization-ADFCRIS",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9"
)
EOF
    print_success "Development files created."
}

function finalize_setup() {
    print_header "FINALIZING SETUP"
    # Temporarily disable 'set -u' to prevent MKL script error
    (
        set +u
        source "${HOME}/miniconda3/etc/profile.d/conda.sh"
        conda activate "$CONDA_ENV_NAME"
        set -u
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
    echo "🚀 Starting ADFCRIS Hardware-Aware Project Setup..."
    echo "========================================================"

    detect_hardware

    create_core_environment
    install_conda_packages
    install_pip_packages

    create_project_structure
    create_dev_tools
    configure_git
    finalize_setup

    trap - ERR

    print_header "🎉 SETUP COMPLETED SUCCESSFULLY! 🎉"
    echo "Your environment is ready."
    echo ""
    echo "--> NEXT STEP: Activate the environment with: ${YELLOW}conda activate $CONDA_ENV_NAME${NC}"
    echo ""
}

main "$@"
