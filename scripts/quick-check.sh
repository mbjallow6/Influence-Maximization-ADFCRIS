#!/bin/bash

# Privacy-Safe Detailed Server Assessment for ADFCRIS Project Setup
# Collects only necessary information for project setup without exposing sensitive data

echo "=== ADFCRIS Detailed Capability Assessment ==="
echo "Assessment Date: $(date)"
echo ""

print_header() {
    echo -e "\n=== $1 ==="
}

print_safe_info() {
    echo "✓ $1"
}

print_warning() {
    echo "⚠ $1"
}

print_header "OPERATING SYSTEM"
if [ -f /etc/os-release ]; then
    # Only show basic OS info, not specific versions that could reveal vulnerabilities
    os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2 | cut -d' ' -f1)
    os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2 | cut -d'.' -f1)
    echo "OS Family: $os_name"
    echo "Major Version: $os_version"
fi
echo "Architecture: $(uname -m)"
echo "Kernel Type: $(uname -s)"

print_header "HARDWARE CAPABILITIES"
echo "CPU Cores: $(nproc)"
if [ -f /proc/meminfo ]; then
    # Show memory in general terms, not exact amounts
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [ "$total_mem_kb" -gt 8000000 ]; then
        echo "RAM: High (>8GB)"
    elif [ "$total_mem_kb" -gt 4000000 ]; then
        echo "RAM: Medium (4-8GB)"
    elif [ "$total_mem_kb" -gt 2000000 ]; then
        echo "RAM: Low (2-4GB)"
    else
        echo "RAM: Very Limited (<2GB)"
    fi
fi

print_header "DEVELOPMENT ENVIRONMENT"

# Check compilers and build tools
echo "Build Tools:"
for tool in gcc g++ make cmake gfortran; do
    if command -v "$tool" &>/dev/null; then
        echo "  $tool: Available"
    fi
done

# Check version control
echo "Version Control:"
for tool in git svn; do
    if command -v "$tool" &>/dev/null; then
        echo "  $tool: Available"
    fi
done

print_header "PYTHON ENVIRONMENT ANALYSIS"
if command -v python3 &>/dev/null; then
    py_major=$(python3 -c "import sys; print(sys.version_info.major)")
    py_minor=$(python3 -c "import sys; print(sys.version_info.minor)")
    echo "Python: $py_major.$py_minor"

    # Check package installation capabilities
    echo "Package Management:"
    if python3 -m pip --version &>/dev/null; then
        echo "  pip: Available"

        # Check if user can install packages
        if python3 -c "import site; print(site.getusersitepackages())" &>/dev/null; then
            echo "  User packages: Supported"
        fi
    fi

    # Check virtual environment capabilities
    for env_tool in venv virtualenv conda; do
        if command -v "$env_tool" &>/dev/null || python3 -m "$env_tool" --help &>/dev/null; then
            echo "  $env_tool: Available"
        fi
    done

    # Check scientific computing readiness
    echo "Scientific Computing Readiness:"
    required_packages=("numpy" "scipy" "pandas" "matplotlib" "jupyter")
    available_count=0

    for pkg in "${required_packages[@]}"; do
        if python3 -c "import $pkg" &>/dev/null; then
            ((available_count++))
        fi
    done

    echo "  Core packages: $available_count/${#required_packages[@]} available"

    # Check ML/Graph packages
    ml_packages=("networkx" "sklearn" "torch" "tensorflow")
    ml_count=0

    for pkg in "${ml_packages[@]}"; do
        if python3 -c "import $pkg" &>/dev/null; then
            ((ml_count++))
        fi
    done

    echo "  ML/Graph packages: $ml_count/${#ml_packages[@]} available"
fi

print_header "ENVIRONMENT ISOLATION CAPABILITIES"
isolation_methods=0

# Check virtual environment methods
if command -v conda &>/dev/null; then
    echo "✓ Conda: Available (Recommended)"
    ((isolation_methods++))
fi

if python3 -m venv --help &>/dev/null 2>&1; then
    echo "✓ Python venv: Available"
    ((isolation_methods++))
fi

if command -v virtualenv &>/dev/null; then
    echo "✓ Virtualenv: Available"
    ((isolation_methods++))
fi

if command -v docker &>/dev/null; then
    echo "✓ Docker: Available"
    ((isolation_methods++))
elif command -v podman &>/dev/null; then
    echo "✓ Podman: Available"
    ((isolation_methods++))
fi

if [ $isolation_methods -eq 0 ]; then
    print_warning "No isolation methods available - will use user packages"
else
    print_safe_info "$isolation_methods isolation method(s) available"
fi

print_header "CONNECTIVITY ASSESSMENT"
connectivity_score=0

if timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✓ Internet connectivity: Available"
    ((connectivity_score++))
fi

if timeout 5 curl -s https://pypi.org/simple/ &>/dev/null; then
    echo "✓ PyPI access: Available"
    ((connectivity_score++))
fi

if timeout 5 curl -s https://repo.anaconda.com &>/dev/null; then
    echo "✓ Conda repositories: Available"
    ((connectivity_score++))
fi

if timeout 5 curl -s https://github.com &>/dev/null; then
    echo "✓ GitHub access: Available"
    ((connectivity_score++))
fi

print_header "SETUP RECOMMENDATIONS"
echo "Based on capability assessment:"
echo ""

# Overall readiness score
readiness_score=0
[ -n "$(command -v python3)" ] && ((readiness_score++))
[ -n "$(command -v git)" ] && ((readiness_score++))
[ $isolation_methods -gt 0 ] && ((readiness_score++))
[ $connectivity_score -gt 2 ] && ((readiness_score++))

if [ $readiness_score -eq 4 ]; then
    echo "✅ EXCELLENT: Server is fully ready for ADFCRIS development"
    echo "   Recommended: Use conda for environment management"
elif [ $readiness_score -eq 3 ]; then
    echo "✅ GOOD: Server is ready with minor limitations"
    echo "   Recommended: Proceed with available tools"
elif [ $readiness_score -eq 2 ]; then
    echo "⚠️  BASIC: Server has essential tools but limited features"
    echo "   Recommended: User-space setup with pip"
else
    echo "❌ LIMITED: Server may not be suitable for complex development"
    echo "   Recommended: Contact administrator for tool installation"
fi

echo ""
echo "🛡️  Privacy Notice: This assessment collected only essential capability"
echo "   information needed for project setup. No sensitive system details,"
echo "   user data, or security information was gathered or displayed."
