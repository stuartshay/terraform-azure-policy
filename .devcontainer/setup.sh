#!/bin/bash
set -e

echo "🚀 Starting Azure Policy Development Container Setup..."

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Update package lists
print_status "Updating package lists..."
sudo apt-get update -qq

# Install additional dependencies
print_status "Installing additional system packages..."
sudo apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    jq \
    tree \
    shellcheck \
    yamllint \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install actionlint for GitHub Actions validation
print_status "Installing actionlint..."
if ! command -v actionlint &> /dev/null; then
    bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash) latest /usr/local/bin
    sudo chmod +x /usr/local/bin/actionlint
    print_success "actionlint installed"
else
    print_success "actionlint already installed"
fi

# Install markdownlint-cli
print_status "Installing markdownlint-cli..."
if ! command -v markdownlint &> /dev/null; then
    sudo npm install -g markdownlint-cli
    print_success "markdownlint-cli installed"
else
    print_success "markdownlint-cli already installed"
fi

# Install Python packages for development
print_status "Installing Python packages..."
pip3 install --upgrade pip
pip3 install commitizen detect-secrets pre-commit
print_success "Python packages installed (commitizen, detect-secrets, pre-commit)"

# Verify Terraform installation
print_status "Verifying Terraform installation..."
if command -v terraform &> /dev/null; then
    terraform version
    print_success "Terraform is installed"
else
    print_warning "Terraform is not installed"
fi

# Verify TFLint installation
print_status "Verifying TFLint installation..."
if command -v tflint &> /dev/null; then
    tflint --version
    print_success "TFLint is installed"
else
    print_warning "TFLint is not installed"
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

# Verify Azure CLI installation
print_status "Verifying Azure CLI installation..."
if command -v az &> /dev/null; then
    az version
    print_success "Azure CLI is installed"
else
    print_warning "Azure CLI is not installed"
fi

# Verify PowerShell installation
print_status "Verifying PowerShell installation..."
if command -v pwsh &> /dev/null; then
    pwsh -Version
    print_success "PowerShell is installed"
else
    print_warning "PowerShell is not installed"
fi

# Install PowerShell modules
print_status "Installing PowerShell modules..."
pwsh -NoProfile -Command "
    Write-Host 'Setting PSGallery as trusted repository...'
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

    Write-Host 'Installing required PowerShell modules...'
    \$modules = @(
        @{ Name = 'Pester'; Version = '5.4.0'; Priority = 1 },
        @{ Name = 'PSScriptAnalyzer'; Version = '1.21.0'; Priority = 1 },
        @{ Name = 'PowerShellGet'; Version = '2.2.5'; Priority = 2 },
        @{ Name = 'PackageManagement'; Version = '1.4.8.1'; Priority = 2 },
        @{ Name = 'Az.Accounts'; Version = '2.12.1'; Priority = 3 },
        @{ Name = 'Az.Resources'; Version = '6.6.0'; Priority = 3 },
        @{ Name = 'Az.PolicyInsights'; Version = '1.6.1'; Priority = 3 },
        @{ Name = 'Az.Storage'; Version = '6.0.0'; Priority = 3 }
    )

    # Sort by priority to install critical testing modules first
    \$modules | Sort-Object Priority | ForEach-Object {
        Write-Host \"Installing \$(\$_.Name) version \$(\$_.Version)...\"
        try {
            if (-not (Get-Module -ListAvailable -Name \$_.Name | Where-Object Version -eq \$_.Version)) {
                Install-Module -Name \$_.Name -RequiredVersion \$_.Version -Scope CurrentUser -Force -AllowClobber -AllowPrerelease:\$false -ErrorAction Stop -Verbose
                Write-Host \"✓ \$(\$_.Name) \$(\$_.Version) installed successfully\"
            } else {
                Write-Host \"✓ \$(\$_.Name) \$(\$_.Version) already installed\"
            }
        } catch {
            Write-Host \"⚠ Failed to install \$(\$_.Name): \$(\$_.Exception.Message)\"
        }
    }

    # Optional modules
    Write-Host 'Installing optional PowerShell modules...'
    \$optionalModules = @(
        @{ Name = 'Az.ResourceGraph'; Version = '0.13.0' },
        @{ Name = 'ImportExcel'; Version = '7.8.4' },
        @{ Name = 'PSWriteColor'; Version = '1.0.1' }
    )

    foreach (\$module in \$optionalModules) {
        Write-Host \"Installing \$(\$module.Name) version \$(\$module.Version)...\"
        try {
            if (-not (Get-Module -ListAvailable -Name \$module.Name | Where-Object Version -eq \$module.Version)) {
                Install-Module -Name \$module.Name -RequiredVersion \$module.Version -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Host \"✓ \$(\$module.Name) installed\"
            } else {
                Write-Host \"✓ \$(\$module.Name) already installed\"
            }
        } catch {
            Write-Host \"⚠ Failed to install \$(\$module.Name): \$(\$_.Exception.Message)\"
        }
    }

    Write-Host ''
    Write-Host 'Verifying critical modules...'
    \$criticalModules = @('Pester', 'PSScriptAnalyzer')
    \$allInstalled = \$true
    foreach (\$moduleName in \$criticalModules) {
        \$module = Get-Module -ListAvailable -Name \$moduleName | Select-Object -First 1
        if (\$module) {
            Write-Host \"✓ \$moduleName \$(\$module.Version) is available\"
        } else {
            Write-Host \"✗ \$moduleName is NOT installed\"
            \$allInstalled = \$false
        }
    }

    if (\$allInstalled) {
        Write-Host ''
        Write-Host '✅ PowerShell modules installation complete!'
    } else {
        Write-Host ''
        Write-Host '⚠️  Some critical modules failed to install. Run the setup script again or install manually.'
        exit 1
    }
"

if [ $? -eq 0 ]; then
    print_success "PowerShell modules installed and verified"
else
    print_warning "PowerShell module installation had issues - please check the output above"
fi

# Setup Git configuration for the container
print_status "Setting up Git configuration..."
if [ -d "/home/vscode/.ssh-localhost" ]; then
    print_status "Copying SSH keys from host..."
    mkdir -p /home/vscode/.ssh
    cp -r /home/vscode/.ssh-localhost/* /home/vscode/.ssh/ 2>/dev/null || true
    chmod 700 /home/vscode/.ssh
    chmod 600 /home/vscode/.ssh/* 2>/dev/null || true
    print_success "SSH keys configured"
fi

# Configure Git
git config --global --add safe.directory /workspaces/terraform-azure-policy

# Install and configure pre-commit hooks
print_status "Configuring pre-commit hooks..."
if [ -f ".pre-commit-config.yaml" ]; then
    # Verify pre-commit is installed
    if command -v pre-commit &> /dev/null; then
        print_success "pre-commit is installed: $(pre-commit --version)"

        # Install the git hooks
        pre-commit install --install-hooks || print_warning "Failed to install pre-commit hooks"

        # Install commit-msg hook for commitizen
        pre-commit install --hook-type commit-msg || print_warning "Failed to install commit-msg hook"

        print_success "Pre-commit hooks configured"
    else
        print_warning "pre-commit not found, skipping hook installation"
    fi
else
    print_warning "No .pre-commit-config.yaml found, skipping pre-commit setup"
fi

# Initialize Terraform (if terraform files exist)
print_status "Initializing Terraform..."
if [ -f "policies/main.tf" ]; then
    cd policies
    terraform init -backend=false || print_warning "Terraform init failed (this is expected without backend configuration)"
    cd ..
fi

# Setup PowerShell profile
print_status "Setting up PowerShell profile..."
PROFILE_DIR="/home/vscode/.config/powershell"
mkdir -p "$PROFILE_DIR"
if [ -f "PowerShell/Microsoft.PowerShell_profile.ps1" ]; then
    cp PowerShell/Microsoft.PowerShell_profile.ps1 "$PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
    print_success "PowerShell profile configured"
fi

# Create reports directory
mkdir -p reports

# Display environment information
print_status "Environment Information:"
echo "----------------------------------------"
echo "PowerShell: $(pwsh -Version 2>/dev/null || echo 'Not installed')"
echo "Terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'Not installed')"
echo "Azure CLI: $(az version --output json 2>/dev/null | jq -r '."azure-cli"' || echo 'Not installed')"
echo "Git: $(git --version)"
echo "Python: $(python3 --version)"
echo "Pre-commit: $(pre-commit --version 2>/dev/null || echo 'Not installed')"
echo "TFLint: $(tflint --version 2>/dev/null | head -n1 || echo 'Not installed')"
echo "terraform-docs: $(terraform-docs --version 2>/dev/null || echo 'Not installed')"
echo "Actionlint: $(actionlint --version 2>/dev/null || echo 'Not installed')"
echo "Markdownlint: $(markdownlint --version 2>/dev/null || echo 'Not installed')"
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
