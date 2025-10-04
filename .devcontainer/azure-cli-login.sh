#!/bin/bash
# Azure CLI Auto-Login Script for GitHub Codespaces
# This script automatically logs into Azure CLI using Service Principal credentials
# from GitHub Codespaces secrets (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)

set +e  # Don't exit on errors - this is optional authentication

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[Azure CLI]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Azure CLI]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Azure CLI]${NC} $1"
}

print_error() {
    echo -e "${RED}[Azure CLI]${NC} $1"
}

print_status "Checking Azure CLI authentication..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Skipping authentication."
    exit 0
fi

# Check if all required environment variables are set
if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_TENANT_ID" ] || [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    print_warning "Azure credentials not found in environment variables."
    print_warning "Required variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID"
    print_status "To set up Codespaces secrets, visit: https://github.com/settings/codespaces"
    print_status "You can manually authenticate later with: az login"
    exit 0
fi

# Check if already logged in
CURRENT_ACCOUNT=$(az account show --query "id" -o tsv 2>/dev/null)
if [ -n "$CURRENT_ACCOUNT" ]; then
    if [ "$CURRENT_ACCOUNT" = "$ARM_SUBSCRIPTION_ID" ]; then
        print_success "Already logged into Azure CLI"
        print_status "Subscription: $(az account show --query 'name' -o tsv)"
        print_status "Tenant: $(az account show --query 'tenantId' -o tsv)"
        exit 0
    else
        print_warning "Logged into different subscription. Re-authenticating..."
    fi
fi

# Perform Azure CLI login using service principal
print_status "Authenticating to Azure CLI with Service Principal..."
print_status "Client ID: $ARM_CLIENT_ID"
print_status "Tenant ID: $ARM_TENANT_ID"
print_status "Subscription ID: $ARM_SUBSCRIPTION_ID"

if az login \
    --service-principal \
    --username "$ARM_CLIENT_ID" \
    --password "$ARM_CLIENT_SECRET" \
    --tenant "$ARM_TENANT_ID" \
    --output none 2>&1; then

    # Set the subscription
    if az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none 2>&1; then
        print_success "✅ Successfully authenticated to Azure CLI!"
        print_success "Subscription: $(az account show --query 'name' -o tsv)"
        print_success "Tenant: $(az account show --query 'tenantId' -o tsv)"

        # Show account details
        echo ""
        az account show --output table
        echo ""

        print_status "Azure CLI is ready to use! 🎉"
    else
        print_error "Failed to set Azure subscription"
        exit 1
    fi
else
    print_error "Failed to authenticate to Azure CLI"
    print_error "Please check your credentials and try again"
    exit 1
fi

exit 0
