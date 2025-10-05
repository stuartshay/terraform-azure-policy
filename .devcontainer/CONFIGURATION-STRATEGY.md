# DevContainer Configuration Strategy

## Architecture Overview

This project uses a **base + minimal overrides** pattern for DevContainer configuration to eliminate duplication and maintain consistency across different development environments.

## File Structure

```text
.devcontainer/
├── devcontainer.json              # Base configuration (all features, settings, extensions)
├── devcontainer.local.json        # Local development overrides only
└── devcontainer.codespaces.json   # GitHub Codespaces overrides only
```

## Configuration Priority

VS Code DevContainers uses the following priority when selecting configuration:

1. **Local Development**: Uses `devcontainer.local.json` if present, otherwise falls back to `devcontainer.json`
2. **GitHub Codespaces**: Uses `devcontainer.codespaces.json` if present, otherwise falls back to `devcontainer.json`
3. **CI/Other**: Uses `devcontainer.json` as the base configuration

**Important**: Override files completely replace the base file - they don't merge. This is why we use minimal overrides.

## Configuration Details

### `devcontainer.json` (Base Configuration)

Contains the **complete** development environment:

- ✅ All DevContainer features (terraform, azure-cli, powershell, python, git, etc.)
- ✅ All security scanning tools (checkov, terrascan, trivy, tfsec, etc.)
- ✅ All VS Code extensions
- ✅ All VS Code settings
- ✅ Base environment variables
- ✅ Post-create commands
- ✅ Container runtime arguments

**Used by**: CI/CD pipelines, GitHub Actions, default development

### `devcontainer.local.json` (Local Overrides)

Contains **ONLY local-specific settings**:

```json
{
   "name": "Azure Policy Development (Local)",
   "onCreateCommand": "echo 'Local devcontainer created at: $(date)'",
   "mounts": [
      "source=${localEnv:HOME}${localEnv:USERPROFILE}/.azure,target=/home/vscode/.azure,type=bind,consistency=cached",
      "source=${localEnv:HOME}${localEnv:USERPROFILE}/.ssh,target=/home/vscode/.ssh-localhost,type=bind,readonly"
   ]
}
```

**Key Features**:

- Mounts `~/.azure` for Azure CLI credentials
- Mounts `~/.ssh` for SSH keys (read-only)
- Inherits ALL features and settings from base configuration

**Used by**: Local VS Code development with Docker Desktop

### `devcontainer.codespaces.json` (Codespaces Overrides)

Contains **ONLY Codespaces-specific settings**:

```json
{
   "name": "Azure Policy Development (Codespaces)",
   "hostRequirements": {
      "cpus": 2,
      "memory": "8gb",
      "storage": "32gb"
   },
   "secrets": { ... },
   "portsAttributes": { ... },
   "customizations": {
      "codespaces": {
         "openFiles": ["README.md", ".devcontainer/README.md"]
      }
   }
}
```

**Key Features**:

- Resource requirements (CPU, memory, storage)
- GitHub Codespaces secrets configuration
- Port forwarding attributes
- Auto-open files on Codespaces creation
- Inherits ALL features and settings from base configuration

**Used by**: GitHub Codespaces cloud development environment

## Maintenance Guidelines

### Adding a New Feature

**DO**: Add to `devcontainer.json` only

```json
{
   "features": {
      "ghcr.io/new-org/new-feature:1": {
         "version": "latest"
      }
   }
}
```

**DON'T**: Duplicate in local or codespaces files ❌

### Adding Local-Specific Configuration

**DO**: Add to `devcontainer.local.json` only if it's truly local-specific

```json
{
   "mounts": [
      "source=${localEnv:HOME}/.config/custom,target=/home/vscode/.config/custom,type=bind"
   ]
}
```

### Adding Codespaces-Specific Configuration

**DO**: Add to `devcontainer.codespaces.json` only if it's Codespaces-specific

```json
{
   "secrets": {
      "NEW_SECRET": {
         "description": "Description of the secret"
      }
   }
}
```

## Benefits of This Approach

✅ **No Duplication**: Features and settings defined once in base configuration  
✅ **Easy Maintenance**: Update features/extensions in one place  
✅ **Consistency**: Same tooling across local, CI, and cloud environments  
✅ **Clarity**: Override files clearly show environment-specific differences  
✅ **Flexibility**: Easy to add environment-specific settings without affecting others  

## Example Scenarios

### Scenario 1: Adding a New Security Tool

**Before** (with duplication):

- Update `devcontainer.json` ✏️
- Update `devcontainer.local.json` ✏️
- Update `devcontainer.codespaces.json` ✏️
- 3 files to maintain

**After** (minimal overrides):

- Update `devcontainer.json` only ✏️
- 1 file to maintain
- Automatically available in local and codespaces

### Scenario 2: Adding Local Volume Mount

**Action**: Add to `devcontainer.local.json` only

- Does not affect CI or Codespaces
- Local-specific configuration isolated

### Scenario 3: Adding Codespaces Secret

**Action**: Add to `devcontainer.codespaces.json` only

- Does not affect local or CI
- Codespaces-specific configuration isolated

## Testing Configuration

### Test Local Configuration

```bash
# Uses devcontainer.local.json (with mounts)
code .
# Rebuild DevContainer
```

### Test Codespaces Configuration

```bash
# Create new Codespace - uses devcontainer.codespaces.json
# Verify secrets are configured
# Check resource allocation
```

### Test CI Configuration

```bash
# GitHub Actions workflow uses devcontainer.json
# No mounts, no secrets from Codespaces
```

## Troubleshooting

### Features not appearing in local development

- Check that feature is in `devcontainer.json`, not the override file
- Rebuild container: `CMD/CTRL + Shift + P` → "Dev Containers: Rebuild Container"

### Mounts not working in CI

- **Expected behavior**: CI uses `devcontainer.json` which has empty mounts array
- Mounts should only be in `devcontainer.local.json`

### Secrets not available in local development

- **Expected behavior**: Secrets are Codespaces-specific
- Use environment variables or `.env` files for local development

## Related Documentation

- [DevContainer Specification](https://containers.dev/implementors/json_reference/)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
