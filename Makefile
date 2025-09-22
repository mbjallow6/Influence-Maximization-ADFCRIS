# Makefile for the ADFCRIS project

.PHONY: help install test format lint jupyter

# Use bash and activate the conda environment for all commands
SHELL := /bin/bash
CONDA_ENV := adfcris
CONDA_RUN := conda run -n $(CONDA_ENV)

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install the project package in editable mode
	$(CONDA_RUN) pip install -e .

test: ## Run the pytest test suite
	$(CONDA_RUN) pytest --cov=src/adfcris tests/ -v

format: ## Format code with black
	$(CONDA_RUN) black src/ tests/

lint: ## Lint code with flake8
	$(CONDA_RUN) flake8 src/ tests/

jupyter: ## Start Jupyter Lab for development
	$(CONDA_RUN) jupyter lab --ip=0.0.0.0 --port=8889 --no-browser
