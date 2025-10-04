#!/bin/bash
# Test script to verify Azure CLI authentication is working

set -e

echo "=========================================="
echo "Azure CLI Authentication Test"
echo "=========================================="
echo ""

# Check if Azure CLI is installed
echo "✅ Checking Azure CLI installation..."
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    exit 1
fi
echo "✓ Azure CLI version: $(az version --query '\"azure-cli\"' -o tsv)"
echo ""

# Check if environment variables are set
echo "✅ Checking environment variables..."
VARS_OK=true

if [ -z "$ARM_CLIENT_ID" ]; then
    echo "❌ ARM_CLIENT_ID is not set"
    VARS_OK=false
else
    echo "✓ ARM_CLIENT_ID: $ARM_CLIENT_ID"
fi

if [ -z "$ARM_CLIENT_SECRET" ]; then
    echo "❌ ARM_CLIENT_SECRET is not set"
    VARS_OK=false
else
    echo "✓ ARM_CLIENT_SECRET: [HIDDEN]"
fi

if [ -z "$ARM_TENANT_ID" ]; then
    echo "❌ ARM_TENANT_ID is not set"
    VARS_OK=false
else
    echo "✓ ARM_TENANT_ID: $ARM_TENANT_ID"
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    echo "❌ ARM_SUBSCRIPTION_ID is not set"
    VARS_OK=false
else
    echo "✓ ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
fi

if [ "$VARS_OK" = "false" ]; then
    echo ""
    echo "❌ Some environment variables are missing"
    echo "   Please set them in GitHub Codespaces secrets: https://github.com/settings/codespaces"
    exit 1
fi
echo ""

# Check if authenticated
echo "✅ Checking Azure CLI authentication..."
if az account show &> /dev/null; then
    echo "✓ Successfully authenticated to Azure CLI"
    echo ""
    echo "Account Details:"
    echo "----------------------------------------"
    az account show --output table
    echo "----------------------------------------"
    echo ""

    # Verify correct subscription
    CURRENT_SUB=$(az account show --query 'id' -o tsv)
    if [ "$CURRENT_SUB" = "$ARM_SUBSCRIPTION_ID" ]; then
        echo "✅ Correct subscription is set"
    else
        echo "⚠️  WARNING: Current subscription ($CURRENT_SUB) does not match ARM_SUBSCRIPTION_ID ($ARM_SUBSCRIPTION_ID)"
    fi
    echo ""

    # Test Azure access
    echo "✅ Testing Azure access..."
    if az group list --output table --query "[0:5]" &> /dev/null; then
        echo "✓ Successfully accessed Azure resources"
        echo ""
        echo "Sample Resource Groups (first 5):"
        az group list --output table --query "[0:5]"
    else
        echo "❌ Failed to access Azure resources"
        exit 1
    fi

else
    echo "❌ Not authenticated to Azure CLI"
    echo ""
    echo "To authenticate manually, run:"
    echo "  bash .devcontainer/azure-cli-login.sh"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All tests passed! Azure CLI is ready."
echo "=========================================="
