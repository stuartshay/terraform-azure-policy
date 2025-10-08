#!/bin/bash
# Test script to verify Terraform Cloud/CLI authentication is working

set -e

echo "=========================================="
echo "Terraform Cloud Authentication Test"
echo "=========================================="
echo ""

# Check if Terraform is installed
echo "✅ Checking Terraform installation..."
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

TF_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1 | awk '{print $2}')
echo "✓ Terraform version: $TF_VERSION"
echo ""

# Check if environment variables are set
echo "✅ Checking Terraform Cloud environment variables..."
VARS_OK=true

if [ -z "$TF_API_TOKEN" ]; then
    echo "⚠️  TF_API_TOKEN is not set (optional for Terraform Cloud)"
    VARS_OK=false
else
    echo "✓ TF_API_TOKEN: [HIDDEN]"
fi

if [ -z "$TF_CLOUD_ORGANIZATION" ]; then
    echo "⚠️  TF_CLOUD_ORGANIZATION is not set (optional)"
else
    echo "✓ TF_CLOUD_ORGANIZATION: $TF_CLOUD_ORGANIZATION"
fi

echo ""

# Check if credentials file exists
TF_CREDENTIALS_FILE="$HOME/.terraform.d/credentials.tfrc.json"

echo "✅ Checking Terraform CLI credentials..."
if [ -f "$TF_CREDENTIALS_FILE" ]; then
    echo "✓ Terraform credentials file exists: $TF_CREDENTIALS_FILE"

    # Check file permissions
    PERMS=$(stat -c "%a" "$TF_CREDENTIALS_FILE" 2>/dev/null || stat -f "%Lp" "$TF_CREDENTIALS_FILE" 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo "✓ Credentials file has correct permissions (600)"
    else
        echo "⚠️  WARNING: Credentials file permissions are $PERMS (should be 600)"
    fi

    # Check if token is configured
    if [ -n "$TF_API_TOKEN" ]; then
        if grep -q "app.terraform.io" "$TF_CREDENTIALS_FILE" 2>/dev/null; then
            echo "✓ Terraform Cloud hostname configured in credentials"
        fi
    fi

else
    if [ "$VARS_OK" = "false" ]; then
        echo "❌ Terraform credentials file not found"
        echo ""
        echo "To configure Terraform Cloud authentication:"
        echo "  1. Create a token at: https://app.terraform.io/app/settings/tokens"
        echo "  2. Add TF_API_TOKEN to GitHub Codespaces secrets: https://github.com/settings/codespaces"
        echo "  3. (Optional) Add TF_CLOUD_ORGANIZATION for your organization"
        echo "  4. Rebuild the Codespace"
        exit 1
    else
        echo "⚠️  Credentials file not found, but TF_API_TOKEN is set"
        echo "   Run: bash .devcontainer/terraform-cli-login.sh"
    fi
fi

echo ""

# Check Terraform configuration directory
echo "✅ Checking Terraform configuration..."
if [ -d "$HOME/.terraform.d" ]; then
    echo "✓ Terraform configuration directory exists"

    # List configuration files
    CONFIG_FILES=$(ls -la "$HOME/.terraform.d" 2>/dev/null | grep -v "^total" | grep -v "^d" | wc -l)
    if [ "$CONFIG_FILES" -gt 0 ]; then
        echo "✓ Found $CONFIG_FILES configuration file(s)"
    fi
else
    echo "⚠️  Terraform configuration directory not found"
fi

echo ""

# Test Terraform Cloud connectivity (if token is configured)
if [ -f "$TF_CREDENTIALS_FILE" ] && [ -n "$TF_API_TOKEN" ]; then
    echo "✅ Testing Terraform Cloud connectivity..."

    # Try to get account details from Terraform Cloud API
    TF_HOSTNAME="${TF_HOSTNAME:-app.terraform.io}"
    API_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://$TF_HOSTNAME/api/v2/account/details" 2>/dev/null)

    HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$API_RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Successfully authenticated to Terraform Cloud API"

        # Extract username if possible
        USERNAME=$(echo "$RESPONSE_BODY" | jq -r '.data.attributes.username' 2>/dev/null || echo "unknown")
        if [ "$USERNAME" != "unknown" ] && [ "$USERNAME" != "null" ]; then
            echo "✓ Authenticated as user: $USERNAME"
        fi

        # If organization is set, try to get org details
        if [ -n "$TF_CLOUD_ORGANIZATION" ]; then
            echo ""
            echo "✓ Testing organization access: $TF_CLOUD_ORGANIZATION"
            ORG_RESPONSE=$(curl -s -w "\n%{http_code}" \
                -H "Authorization: Bearer $TF_API_TOKEN" \
                -H "Content-Type: application/vnd.api+json" \
                "https://$TF_HOSTNAME/api/v2/organizations/$TF_CLOUD_ORGANIZATION" 2>/dev/null)

            ORG_HTTP_CODE=$(echo "$ORG_RESPONSE" | tail -n1)

            if [ "$ORG_HTTP_CODE" = "200" ]; then
                echo "✓ Successfully accessed organization: $TF_CLOUD_ORGANIZATION"

                # Try to list workspaces (limit to 3)
                WS_RESPONSE=$(curl -s \
                    -H "Authorization: Bearer $TF_API_TOKEN" \
                    -H "Content-Type: application/vnd.api+json" \
                    "https://$TF_HOSTNAME/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces?page[size]=3" 2>/dev/null)

                WS_COUNT=$(echo "$WS_RESPONSE" | jq -r '.data | length' 2>/dev/null || echo "0")
                if [ "$WS_COUNT" -gt 0 ]; then
                    echo "✓ Found $WS_COUNT workspace(s) in organization"
                    echo ""
                    echo "Sample workspaces:"
                    echo "$WS_RESPONSE" | jq -r '.data[].attributes.name' 2>/dev/null | head -n3 | sed 's/^/  - /'
                fi
            else
                echo "⚠️  Could not access organization (HTTP $ORG_HTTP_CODE)"
                echo "   Check that the token has access to: $TF_CLOUD_ORGANIZATION"
            fi
        fi
    elif [ "$HTTP_CODE" = "401" ]; then
        echo "❌ Authentication failed (HTTP 401)"
        echo "   Token may be invalid or expired"
    else
        echo "⚠️  Could not connect to Terraform Cloud API (HTTP $HTTP_CODE)"
    fi
else
    echo "⚠️  Skipping Terraform Cloud API test (credentials not configured)"
fi

echo ""

# Summary
echo "=========================================="
if [ -f "$TF_CREDENTIALS_FILE" ]; then
    echo "✅ Terraform CLI is configured!"
    echo ""
    echo "You can now use Terraform Cloud features:"
    echo "  - Remote state storage"
    echo "  - Remote execution"
    echo "  - Policy as Code (Sentinel)"
    echo "  - Cost estimation"
    echo ""
    if [ -n "$TF_CLOUD_ORGANIZATION" ]; then
        echo "Example usage:"
        cat <<EOF
  terraform {
    cloud {
      organization = "$TF_CLOUD_ORGANIZATION"
      workspaces {
        name = "my-workspace"
      }
    }
  }
EOF
    fi
else
    echo "⚠️  Terraform CLI not fully configured"
    echo ""
    echo "To configure:"
    echo "  1. Set TF_API_TOKEN in GitHub Codespaces secrets"
    echo "  2. Run: bash .devcontainer/terraform-cli-login.sh"
fi
echo "=========================================="
