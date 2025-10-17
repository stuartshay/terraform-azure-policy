# Azure Governance Policies

This directory contains a comprehensive suite of Azure governance policies designed to enforce organizational standards, ensure compliance, and maintain consistency across Azure resources.

## Overview

The governance policy suite includes six policies covering three main areas:

1. **Tag Management** - Enforce required tags and tag inheritance
2. **Naming Conventions** - Enforce consistent naming standards
3. **Location Control** - Restrict resource deployment to approved regions

## Policies

### Tag Management Policies

#### 1. require-tag-environment

Requires all resources to have an `Environment` tag with allowed values (dev, test, staging, prod).

- **Effect**: Audit (default), Deny, or Disabled
- **Use Case**: Categorize resources by deployment environment
- **Documentation**: [require-tag-environment/README.md](./require-tag-environment/README.md)

#### 2. require-tag-costcenter

Requires all resources to have a `CostCenter` tag matching a specific pattern (e.g., CC-1234).

- **Effect**: Audit (default), Deny, or Disabled
- **Use Case**: Track costs and allocate expenses to departments
- **Documentation**: [require-tag-costcenter/README.md](./require-tag-costcenter/README.md)

#### 3. inherit-tag-from-resource-group

Automatically inherits specified tags from resource groups to child resources.

- **Effect**: Modify (automatic)
- **Use Case**: Simplify tag management and ensure consistency
- **Documentation**: [inherit-tag-from-resource-group/README.md](./inherit-tag-from-resource-group/README.md)

### Naming Convention Policies

#### 4. enforce-naming-convention-storage

Enforces naming conventions for Azure Storage Accounts following the pattern: `st{env}{app}{instance}`.

- **Effect**: Audit (default), Deny, or Disabled
- **Use Case**: Maintain consistent storage account naming
- **Documentation**: [enforce-naming-convention-storage/README.md](./enforce-naming-convention-storage/README.md)

#### 5. enforce-naming-convention-func-app

Enforces naming conventions for Azure Function Apps following the pattern: `func-{env}-{app}-{instance}`.

- **Effect**: Audit (default), Deny, or Disabled
- **Use Case**: Maintain consistent Function App naming
- **Documentation**: [enforce-naming-convention-func-app/README.md](./enforce-naming-convention-func-app/README.md)

### Location Control Policies

#### 6. enforce-allowed-locations

Restricts resource deployment to approved Azure regions.

- **Effect**: Deny (default), Audit, or Disabled
- **Use Case**: Ensure data residency compliance and cost optimization
- **Documentation**: [enforce-allowed-locations/README.md](./enforce-allowed-locations/README.md)

## Quick Start

### Prerequisites

- Azure subscription
- Terraform >= 1.9.0
- Azure CLI or service principal for authentication
- Appropriate permissions to create policies and assignments

### Deploying a Policy

Each policy follows the same deployment pattern:

```bash
# Navigate to the policy directory
cd policies/governance/<policy-name>

# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the policy
terraform apply
```

### Example: Deploying Environment Tag Policy

```bash
cd policies/governance/require-tag-environment
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
cat > terraform.tfvars << EOF
create_assignment = true
assignment_scope_id = "/subscriptions/YOUR-SUB-ID/resourceGroups/YOUR-RG"
policy_effect = "Audit"
tag_name = "Environment"
allowed_values = ["dev", "test", "staging", "prod"]
environment = "sandbox"
owner = "Policy-Team"
EOF

terraform init
terraform plan
terraform apply
```

## Policy Deployment Strategy

### Phase 1: Assessment (Week 1-2)

1. Deploy all policies in **Audit** mode
2. Review compliance reports
3. Identify non-compliant resources
4. Document remediation requirements

### Phase 2: Communication (Week 3)

1. Share compliance reports with teams
2. Communicate new requirements
3. Provide documentation and examples
4. Set deadline for compliance

### Phase 3: Remediation (Week 4-6)

1. Teams remediate non-compliant resources
2. Create remediation tasks for tag inheritance
3. Verify compliance improvements
4. Address any issues or exceptions

### Phase 4: Enforcement (Week 7+)

1. Switch policies to **Deny** mode
2. Monitor for policy violations
3. Handle exception requests
4. Continuous improvement

## Policy Effects

Each policy supports multiple effects:

| Effect | Description | Use Case |
|--------|-------------|----------|
| **Audit** | Report non-compliance, allow creation | Initial assessment, monitoring |
| **Deny** | Block non-compliant resource creation | Enforcement after remediation |
| **Disabled** | Policy not enforced | Temporary suspension, testing |
| **Modify** | Automatically fix non-compliance | Tag inheritance (specific policies) |

## Common Configuration Patterns

### Development Environment

```hcl
# Relaxed policies for development
policy_effect = "Audit"
allowed_locations = ["eastus", "eastus2", "centralus", "westus2"]
```

### Staging Environment

```hcl
# Stricter policies for staging
policy_effect = "Deny"
allowed_locations = ["eastus2", "westus2"]
```

### Production Environment

```hcl
# Strict enforcement for production
policy_effect = "Deny"
allowed_locations = ["eastus2", "westus2"]
# Additional monitoring and alerts
```

## Tag Strategy

### Recommended Tag Hierarchy

1. **Resource Group Level Tags** (inherited by resources)
   - Environment (dev, test, staging, prod)
   - CostCenter (CC-XXXX)
   - Owner (team email)
   - Project (project name)

2. **Resource Level Tags** (specific to resource)
   - Application (app name)
   - Component (web, api, db, etc.)
   - ManagedBy (terraform, manual, etc.)

### Tag Inheritance Workflow

```text
Resource Group Tags:
├── Environment: prod
├── CostCenter: CC-1234
└── Owner: team-a@company.com

      ↓ (automatic via inherit-tag-from-resource-group)

Resource Tags:
├── Environment: prod        ← Inherited
├── CostCenter: CC-1234      ← Inherited
├── Owner: team-a@company.com ← Inherited
├── Application: web-app     ← Resource-specific
└── Component: frontend      ← Resource-specific
```

## Naming Convention Standards

### Storage Accounts

- **Pattern**: `st{env}{app}{instance}`
- **Example**: `stdevweb001`, `stproddata002`
- **Length**: 3-24 characters
- **Characters**: Lowercase letters and numbers only

### Function Apps

- **Pattern**: `func-{env}-{app}-{instance}`
- **Example**: `func-dev-api-001`, `func-prod-payment-002`
- **Length**: 2-60 characters
- **Characters**: Alphanumeric and hyphens

## Location Strategy

### Considerations

1. **Data Residency**: Regulatory requirements for data location
2. **Latency**: Proximity to users
3. **Cost**: Regional pricing differences
4. **Disaster Recovery**: Paired regions for HA
5. **Availability Zones**: Region support for AZs

### Common Configurations

**US Only:**

```hcl
allowed_locations = ["eastus2", "westus2", "centralus"]
```

**Europe Only (GDPR):**

```hcl
allowed_locations = ["northeurope", "westeurope", "uksouth"]
```

**Multi-Region HA:**

```hcl
allowed_locations = [
  "eastus2",     # Primary
  "westus2",     # DR
  "northeurope"  # EU operations
]
```

## Monitoring and Compliance

### Azure Policy Compliance Dashboard

Monitor policy compliance through:

- Azure Portal → Policy → Compliance
- View compliance by policy, resource, or resource group
- Export compliance reports
- Create remediation tasks

### Azure Resource Graph Queries

```kusto
// Find resources without Environment tag
resources
| where tags !has "Environment"
| project name, type, resourceGroup, location

// Find resources in non-compliant regions
resources
| where location !in ("eastus", "westus2")
| project name, type, location

// Find non-compliant storage account names
resources
| where type == "Microsoft.Storage/storageAccounts"
| where name !startswith "st"
| project name, location, resourceGroup
```

## Troubleshooting

### Common Issues

#### Policy Assignment Fails

- **Cause**: Insufficient permissions
- **Solution**: Ensure you have Owner or Policy Contributor role

#### Resources Still Non-Compliant After Remediation

- **Cause**: Remediation task not created or failed
- **Solution**: Create remediation task in Azure Portal

#### Modify Effect Not Working

- **Cause**: Missing managed identity permissions
- **Solution**: Ensure system-assigned identity has Contributor role

#### Policy Evaluation Delay

- **Cause**: Policies evaluated on write operations and periodic scans
- **Solution**: Wait up to 30 minutes for compliance state to update

## Best Practices

1. **Start with Audit**: Always begin with Audit mode
2. **Document Exceptions**: Maintain a list of approved exceptions
3. **Version Control**: Store policy configurations in git
4. **Test in Non-Prod**: Test policy changes in dev/test first
5. **Monitor Compliance**: Regularly review compliance reports
6. **Automate Remediation**: Use remediation tasks for scalability
7. **Communicate Changes**: Inform teams before enforcement
8. **Regular Reviews**: Periodically review and update policies

## Contributing

When adding new governance policies:

1. Follow the existing folder structure
2. Include all required files:
   - `rule.json` - Policy definition
   - `main.tf` - Terraform configuration
   - `variables.tf` - Variable definitions
   - `outputs.tf` - Output definitions
   - `version.tf` - Provider versions
   - `terraform.tfvars.example` - Example variables
   - `README.md` - Comprehensive documentation

3. Ensure consistent naming and patterns
4. Include comprehensive documentation
5. Add examples and use cases
6. Test in sandbox environment first

## Support and Resources

### Documentation

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Policy Effects](https://docs.microsoft.com/azure/governance/policy/concepts/effects)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Regions](https://azure.microsoft.com/global-infrastructure/geographies/)

### Tools

- [Azure Policy Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=AzurePolicy.azurepolicyextension)
- [Azure Resource Graph Explorer](https://portal.azure.com/#blade/HubsExtension/ArgQueryBlade)
- [Azure Policy GitHub Repository](https://github.com/Azure/azure-policy)

## License

See [LICENSE](../../LICENSE) file in the repository root.
