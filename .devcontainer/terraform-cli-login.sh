#!/bin/bash
# Terraform CLI Auto-Login Script for GitHub Codespaces
# This script automatically configures Terraform CLI credentials using TF_API_TOKEN
# from GitHub Codespaces secrets

set +e  # Don't exit on errors - this is optional authentication

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[Terraform CLI]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Terraform CLI]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Terraform CLI]${NC} $1"
}

print_error() {
    echo -e "${RED}[Terraform CLI]${NC} $1"
}

print_status "Checking Terraform CLI configuration..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Skipping configuration."
    exit 0
fi

# Check if TF_API_TOKEN is set
if [ -z "$TF_API_TOKEN" ]; then
    print_warning "TF_API_TOKEN not found in environment variables."
    print_warning "Terraform Cloud authentication will not be configured."
    print_status "To set up Terraform Cloud credentials:"
    print_status "  1. Create a token at: https://app.terraform.io/app/settings/tokens"
    print_status "  2. Add TF_API_TOKEN to GitHub Codespaces secrets: https://github.com/settings/codespaces"
    print_status "  3. (Optional) Add TF_CLOUD_ORGANIZATION for your organization name"
    exit 0
fi

# Display configuration info
print_status "Configuring Terraform CLI credentials..."
if [ -n "$TF_CLOUD_ORGANIZATION" ]; then
    print_status "Organization: $TF_CLOUD_ORGANIZATION"
fi
print_status "Token: [HIDDEN]"

# Create Terraform CLI configuration directory
TF_CLI_CONFIG_DIR="$HOME/.terraform.d"
TF_CREDENTIALS_FILE="$TF_CLI_CONFIG_DIR/credentials.tfrc.json"

mkdir -p "$TF_CLI_CONFIG_DIR"

# Check if credentials file already exists
if [ -f "$TF_CREDENTIALS_FILE" ]; then
    print_warning "Terraform credentials file already exists."

    # Check if token is already configured correctly
    if grep -q "$TF_API_TOKEN" "$TF_CREDENTIALS_FILE" 2>/dev/null; then
        print_success "✅ Terraform CLI is already configured with current token"

        # Show terraform version and login status
        print_status "Terraform version: $(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1)"

        exit 0
    else
        print_warning "Updating existing credentials file with new token..."
    fi
fi

# Determine Terraform Cloud hostname (default to app.terraform.io)
TF_HOSTNAME="${TF_HOSTNAME:-app.terraform.io}"

# Create credentials file
cat > "$TF_CREDENTIALS_FILE" <<EOF
{
  "credentials": {
    "$TF_HOSTNAME": {
      "token": "$TF_API_TOKEN"
    }
  }
}
EOF

# Set proper permissions (important for security)
chmod 600 "$TF_CREDENTIALS_FILE"

# Verify the file was created
if [ -f "$TF_CREDENTIALS_FILE" ]; then
    print_success "✅ Terraform CLI credentials configured successfully!"
    print_success "Credentials file: $TF_CREDENTIALS_FILE"
    print_success "Hostname: $TF_HOSTNAME"

    # Show terraform version
    TF_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1 | awk '{print $2}')
    print_status "Terraform version: $TF_VERSION"

    # If organization is set, display it
    if [ -n "$TF_CLOUD_ORGANIZATION" ]; then
        print_status "Organization: $TF_CLOUD_ORGANIZATION"
        print_status "You can now use: terraform init -backend-config=\"organization=$TF_CLOUD_ORGANIZATION\""
    fi

    echo ""
    print_status "Terraform CLI is ready to use Terraform Cloud! 🎉"

else
    print_error "Failed to create Terraform credentials file"
    exit 1
fi

exit 0
