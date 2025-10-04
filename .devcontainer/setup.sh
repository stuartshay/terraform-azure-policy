#!/bin/bash
# Optimized DevContainer Setup Script
# Most tools are now installed via DevContainer features for faster parallel installation
set -e

echo "🚀 Starting Azure Policy Development Container Setup..."

# Detect CI environment
IS_CI="${CI:-false}"
IS_GITHUB_ACTIONS="${GITHUB_ACTIONS:-false}"

if [ "$IS_CI" = "true" ] || [ "$IS_GITHUB_ACTIONS" = "true" ]; then
    echo "Running in CI environment - adapting setup..."
    export CI_MODE=true
else
    export CI_MODE=false
fi

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine workspace root
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspaces/terraform-azure-policy}"
if [ ! -d "$WORKSPACE_ROOT" ]; then
    # Try to find it from current directory
    if [ -f "$(pwd)/requirements.psd1" ]; then
        WORKSPACE_ROOT="$(pwd)"
    elif [ -f "$(pwd)/../requirements.psd1" ]; then
        WORKSPACE_ROOT="$(cd .. && pwd)"
    else
        print_warning "Could not determine workspace root, using: $(pwd)"
        WORKSPACE_ROOT="$(pwd)"
    fi
fi

print_status "Workspace root: $WORKSPACE_ROOT"
cd "$WORKSPACE_ROOT"

# Disable exit on error for optional installations
set +e

# Install minimal additional dependencies only (most now via features)
print_status "Installing additional system packages..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    jq \
    tree \
    shellcheck \
    yamllint

# Install markdownlint-cli
print_status "Installing markdownlint-cli..."
if command -v npm &> /dev/null; then
    if ! command -v markdownlint &> /dev/null; then
        if sudo npm install -g markdownlint-cli 2>/dev/null; then
            print_success "markdownlint-cli installed"
        else
            print_warning "Failed to install markdownlint-cli - continuing anyway"
        fi
    else
        print_success "markdownlint-cli already installed"
    fi
else
    print_warning "npm not found, skipping markdownlint-cli installation"
fi

# Install terraform-docs
print_status "Installing terraform-docs..."
if ! command -v terraform-docs &> /dev/null; then
    TERRAFORM_DOCS_VERSION="${TERRAFORM_DOCS_VERSION:-v0.19.0}"
    curl -Lo /tmp/terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
    tar -xzf /tmp/terraform-docs.tar.gz -C /tmp terraform-docs
    sudo mv /tmp/terraform-docs /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform-docs
    rm -f /tmp/terraform-docs.tar.gz
    print_success "terraform-docs ${TERRAFORM_DOCS_VERSION} installed"
else
    terraform-docs --version
    print_success "terraform-docs already installed"
fi

# Install tfsec
print_status "Installing tfsec..."
if ! command -v tfsec &> /dev/null; then
    TFSEC_VERSION="${TFSEC_VERSION:-latest}"
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
    print_success "tfsec installed"
else
    tfsec --version
    print_success "tfsec already installed"
fi

# Install Python packages for development
print_status "Installing Python packages..."
pip3 install --upgrade pip --quiet
pip3 install commitizen detect-secrets pre-commit --quiet
print_success "Python packages installed (commitizen, detect-secrets, pre-commit)"

# Install PowerShell modules using centralized script
print_status "Installing PowerShell modules..."
if [ -f "$WORKSPACE_ROOT/scripts/Install-Requirements.ps1" ]; then
    if command -v pwsh &> /dev/null; then
        print_status "Running Install-Requirements.ps1 script..."
        if pwsh -NoProfile -ExecutionPolicy Bypass -File "$WORKSPACE_ROOT/scripts/Install-Requirements.ps1" -IncludeOptional; then
            print_success "PowerShell modules installed via centralized script"
        else
            print_warning "Install-Requirements.ps1 completed with warnings/errors"
        fi
    else
        print_warning "PowerShell not found, skipping module installation"
    fi
else
    print_warning "Install-Requirements.ps1 not found at $WORKSPACE_ROOT/scripts/, skipping module installation"
fi

# Setup Git configuration for the container
print_status "Setting up Git configuration..."
git config --global --add safe.directory /workspaces/terraform-azure-policy

if [ -d "/home/vscode/.ssh-localhost" ] && [ "$CI_MODE" = "false" ]; then
    print_status "Copying SSH keys from host..."
    mkdir -p /home/vscode/.ssh
    cp -r /home/vscode/.ssh-localhost/* /home/vscode/.ssh/ 2>/dev/null || true
    chmod 700 /home/vscode/.ssh
    chmod 600 /home/vscode/.ssh/* 2>/dev/null || true
    print_success "SSH keys configured"
fi
# Configure pre-commit hooks using PowerShell script
print_status "Configuring pre-commit hooks..."
if [ -f "$WORKSPACE_ROOT/scripts/Setup-PreCommit.ps1" ]; then
    if command -v pwsh &> /dev/null; then
        print_status "Running Setup-PreCommit.ps1 script..."
        if pwsh -NoProfile -ExecutionPolicy Bypass -File "$WORKSPACE_ROOT/scripts/Setup-PreCommit.ps1" -SkipInstall -SkipTest; then
            print_success "Pre-commit hooks configured via PowerShell script"
        else
            print_warning "Setup-PreCommit.ps1 completed with warnings/errors"
        fi
    else
        print_warning "PowerShell not found, using fallback configuration"
        # Fallback: basic pre-commit setup
        if command -v pre-commit &> /dev/null && [ -f "$WORKSPACE_ROOT/.pre-commit-config.yaml" ]; then
            pre-commit install --install-hooks 2>/dev/null || print_warning "Failed to install pre-commit hooks"
            pre-commit install --hook-type commit-msg 2>/dev/null || print_warning "Failed to install commit-msg hook"
            print_success "Pre-commit hooks configured (basic setup)"
        else
            print_warning "pre-commit not available or config not found"
        fi
    fi
else
    print_warning "Setup-PreCommit.ps1 not found at $WORKSPACE_ROOT/scripts/, skipping pre-commit setup"
fi

# Initialize Terraform (if terraform files exist)
print_status "Initializing Terraform..."
if [ -f "$WORKSPACE_ROOT/policies/main.tf" ]; then
    cd "$WORKSPACE_ROOT/policies"
    terraform init -backend=false 2>/dev/null || print_warning "Terraform init failed (this is expected without backend configuration)"
    cd "$WORKSPACE_ROOT"
fi

# Setup PowerShell profile
print_status "Setting up PowerShell profile..."
PROFILE_DIR="/home/vscode/.config/powershell"
mkdir -p "$PROFILE_DIR"
if [ -f "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" ]; then
    cp "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" "$PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
    print_success "PowerShell profile configured"
fi

# Create reports directory
mkdir -p "$WORKSPACE_ROOT/reports"

# Display environment information
print_status "Environment Information:"
echo "----------------------------------------"
echo "PowerShell: $(pwsh -Version 2>/dev/null || echo 'Not installed')"
echo "Terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || echo 'Not installed')"
echo "Azure CLI: $(az version --output json 2>/dev/null | jq -r '."azure-cli"' 2>/dev/null || echo 'Not installed')"
echo "Git: $(git --version 2>/dev/null || echo 'Not installed')"
echo "Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "Pre-commit: $(pre-commit --version 2>/dev/null || echo 'Not installed')"
echo "TFLint: $(tflint --version 2>/dev/null | head -n1 || echo 'Not installed')"
echo "terraform-docs: $(terraform-docs --version 2>/dev/null || echo 'Not installed')"
echo "tfsec: $(tfsec --version 2>/dev/null || echo 'Not installed')"
echo "Terragrunt: $(terragrunt --version 2>/dev/null || echo 'Not installed')"
echo "Actionlint: $(actionlint --version 2>/dev/null || echo 'Not installed')"
echo "Markdownlint: $(markdownlint --version 2>/dev/null || echo 'Not installed')"
echo "Shellcheck: $(shellcheck --version 2>/dev/null | head -n2 | tail -n1 || echo 'Not installed')"
echo "Yamllint: $(yamllint --version 2>/dev/null || echo 'Not installed')"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo ""
echo "PowerShell Modules:"
if command -v pwsh &> /dev/null; then
    pwsh -NoProfile -Command "Get-Module -ListAvailable | Where-Object { @('Pester', 'PSScriptAnalyzer', 'Az.Accounts', 'Az.Resources', 'Az.PolicyInsights', 'Az.Storage') -contains \$_.Name } | ForEach-Object { Write-Host \"  \$(\$_.Name) \$(\$_.Version)\" }" 2>/dev/null || echo "  Failed to list modules"  # pragma: allowlist secret
else
    echo "  PowerShell not available"
fi
echo "----------------------------------------"

print_success "✨ Azure Policy Development Container setup complete!"
echo ""
print_status "Next steps:"
echo "  1. Authenticate with Azure: az login"
echo "  2. Set subscription: az account set --subscription <subscription-id>"
echo "  3. Run tests: ./scripts/Invoke-PolicyTests.ps1"
echo "  4. Run pre-commit: pre-commit run --all-files"
echo ""
print_status "Happy coding! 🎉"

# Exit successfully
exit 0
