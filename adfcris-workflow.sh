#!/bin/bash

# =============================================================================
# ADFCRIS - Git & GitHub Research Workflow Automation Script
# =============================================================================
# Automates the complete Git/GitHub workflow for ADFCRIS feature development.
# Usage: ./adfcris-workflow.sh [command] [options]
# =============================================================================

set -e # Exit on any error

# --- Configuration ---
MAIN_BRANCH="main"
FEATURE_PREFIX="feature/"
REMOTE_NAME="origin"
CONDA_ENV="adfcris"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Utility Functions ---
print_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository."
        exit 1
    fi
}

check_github_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Run 'conda activate $CONDA_ENV && mamba install gh'"
        exit 1
    fi
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub CLI. Please run 'gh auth login'."
        exit 1
    fi
}

get_current_branch() {
    git branch --show-current
}

# --- Main Workflow Functions ---

start_day() {
    print_header "🚀 STARTING DAY"
    print_info "Switching to '$MAIN_BRANCH' and syncing..."
    git checkout $MAIN_BRANCH
    git fetch --all --prune
    git pull $REMOTE_NAME $MAIN_BRANCH
    print_info "Cleaning up old merged branches..."
    git branch --merged | grep -v "\*\|$MAIN_BRANCH" | xargs -r git branch -d
    print_success "Repository is up-to-date. Happy coding!"
}

create_feature() {
    local feature_name=$1
    if [[ -z "$feature_name" ]]; then
        print_error "Feature name is required. Usage: ./adfcris-workflow.sh feature <name>"
        exit 1
    fi
    
    local branch_name="${FEATURE_PREFIX}${feature_name}"
    print_header "🌿 CREATING NEW FEATURE: $branch_name"
    
    start_day # Always start from an up-to-date main branch
    
    print_info "Creating and switching to new branch..."
    git checkout -b "$branch_name"
    print_success "Ready to work on feature '$branch_name'."
}

save_work() {
    local commit_message=${1:-"WIP: Save progress"}
    print_header "💾 SAVING WORK"
    
    if ! git diff-index --quiet HEAD --; then
        git add -A
        git commit -m "$commit_message"
        print_success "Changes committed locally."
    else
        print_info "No changes to commit."
    fi
    
    print_info "Pushing to remote..."
    git push -u $REMOTE_NAME $(get_current_branch)
    print_success "Work pushed to GitHub!"
}

create_pr() {
    local current_branch=$(get_current_branch)
    local pr_title=${1:-"feat: ${current_branch#$FEATURE_PREFIX}"}
    
    print_header "📬 CREATING PULL REQUEST"
    
    # Save any final changes before creating the PR
    save_work "Ready for review: ${pr_title}"
    
    # Best Practice: Run tests before opening a PR
    print_info "Running project tests..."
    if make test; then
        print_success "All tests passed!"
    else
        print_error "Tests failed! Please fix them before creating a pull request."
        exit 1
    fi
    
    print_info "Creating pull request on GitHub..."
    gh pr create --title "$pr_title" --body "PR for the ${current_branch#$FEATURE_PREFIX} feature." --base $MAIN_BRANCH
    
    print_success "Pull request created!"
    gh pr view --web
}

complete_feature() {
    local current_branch=$(get_current_branch)
    print_header "🎉 COMPLETING FEATURE"
    
    print_info "Merging pull request via GitHub CLI..."
    gh pr merge "$current_branch" --squash --delete-branch
    
    # Go back to main and clean up
    start_day
    
    print_success "Feature '$current_branch' has been merged and cleaned up!"
}

# --- Main Script Logic ---
main() {
    check_git_repo
    check_github_cli
    
    local command=${1:-help}
    shift || true
    
    case $command in
        start) start_day ;;
        feature) create_feature "$1" ;;
        save) save_work "$1" ;;
        pr) create_pr "$1" ;;
        complete) complete_feature ;;
        *)
            echo "Usage: ./adfcris-workflow.sh [start|feature|save|pr|complete]"
            ;;
    esac
}

main "$@"