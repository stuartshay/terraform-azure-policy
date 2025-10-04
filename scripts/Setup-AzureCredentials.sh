#!/bin/bash

# Azure Service Principal Setup for GitHub Actions
# This script creates a service principal with the required permissions for deploying Azure Policies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Azure Service Principal for GitHub Actions${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first:${NC}"
    echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Get subscription ID
echo -e "${YELLOW}📋 Getting Azure subscription information...${NC}"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Subscription Name: $SUBSCRIPTION_NAME"
echo ""

# Prompt for confirmation
read -p "Continue with this subscription? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️ Cancelled by user${NC}"
    exit 1
fi

# Generate unique service principal name
SP_NAME="sp-github-terraform-azure-policy-$(date +%s)"

echo -e "${YELLOW}🔐 Creating service principal: $SP_NAME${NC}"

# Create service principal with required permissions
CREDENTIALS=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Policy Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth)

echo -e "${GREEN}✅ Service principal created successfully!${NC}"
echo ""

# Add additional role assignments
echo -e "${YELLOW}🔒 Adding Resource Policy Contributor role...${NC}"
SP_OBJECT_ID=$(echo "$CREDENTIALS" | jq -r '.clientId' | xargs az ad sp show --id --query id --output tsv)

az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type "ServicePrincipal" \
    --role "Resource Policy Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID"

echo -e "${GREEN}✅ Additional role assignment completed!${NC}"
echo ""

# Display setup instructions
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo "1. Copy the following JSON and add it as a GitHub Secret named 'AZURE_CREDENTIALS':"
echo ""
echo -e "${GREEN}${CREDENTIALS}${NC}"
echo ""
echo "2. In your GitHub repository, go to Settings > Secrets and variables > Actions"
echo ""
echo "3. Click 'New repository secret' and create:"
echo "   - Name: AZURE_CREDENTIALS"
echo "   - Value: (paste the JSON above)"
echo ""
echo "4. Your subscription ID for workflows: $SUBSCRIPTION_ID"
echo ""
echo -e "${YELLOW}🚀 Ready to deploy!${NC}"
echo ""
echo "Test the deployment with:"
echo ""
echo "gh workflow run deploy.yml \\"
echo "  -f version=\"1.0.0\" \\"  # pragma: allowlist secret
echo "  -f resource_group=\"rg-azure-policy-test\" \\"  # pragma: allowlist secret
echo "  -f subscription_id=\"$SUBSCRIPTION_ID\" \\"  # pragma: allowlist secret
echo "  -f environment=\"development\" \\"  # pragma: allowlist secret
echo "  -f policy_effect=\"Audit\" \\"
echo "  -f dry_run=\"true\""
echo ""
echo -e "${GREEN}🔒 Service Principal Details:${NC}"
echo "Name: $SP_NAME"
echo "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "Roles: Policy Contributor, Resource Policy Contributor"
