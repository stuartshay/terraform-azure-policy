# Dev Container Architecture

This document describes the architecture and structure of the development container setup.

## 📁 File Structure

```text
terraform-azure-policy/
├── .devcontainer/
│   ├── devcontainer.json              # Main VS Code Dev Container config
│   ├── devcontainer.codespaces.json   # GitHub Codespaces specific config
│   ├── setup.sh                       # Automated setup script (executable)
│   ├── .env.example                   # Environment variable template
│   └── README.md                      # Complete setup documentation (7.5KB)
├── .github/
│   └── workflows/
│       └── devcontainer.yml           # CI/CD for devcontainer testing
├── docs/
│   ├── DevContainer-Quick-Reference.md # Quick command reference
│   └── README.md                      # Updated with devcontainer docs
├── DEVCONTAINER-SETUP.md              # This setup summary
└── README.md                          # Updated with devcontainer option
```

## 🏗️ Architecture Diagram

```text
┌─────────────────────────────────────────────────────────────────┐
│                         Host System                              │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ ~/.azure   │  │   ~/.ssh     │  │  Source Code            │ │
│  └──────┬─────┘  └──────┬───────┘  └──────────┬──────────────┘ │
│         │                │                      │                 │
│         │ (mounted)      │ (copied)            │ (mounted)       │
└─────────┼────────────────┼──────────────────────┼────────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Dev Container (Ubuntu)                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Base Image                             │  │
│  │            mcr.microsoft.com/devcontainers/base:ubuntu    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Dev Container Features                       │  │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────────────┐  │  │
│  │  │ PowerShell │ │ Terraform  │ │     Azure CLI        │  │  │
│  │  │  Core 7.x  │ │  v1.13.1   │ │      (latest)        │  │  │
│  │  └────────────┘ └────────────┘ └─────────────────────┘  │  │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────────────┐  │  │
│  │  │  Python    │ │    Git     │ │    GitHub CLI        │  │  │
│  │  │   3.11     │ │  (latest)  │ │      (latest)        │  │  │
│  │  └────────────┘ └────────────┘ └─────────────────────┘  │  │
│  │  ┌────────────┐                                          │  │
│  │  │  Node.js   │         (All auto-installed)            │  │
│  │  │    LTS     │                                          │  │
│  │  └────────────┘                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            setup.sh (postCreateCommand)                  │  │
│  │  • Install system packages (jq, shellcheck, yamllint)   │  │
│  │  • Install tools (actionlint, markdownlint, commitizen) │  │
│  │  • Install PowerShell modules (Az.*, Pester, etc.)      │  │
│  │  • Setup pre-commit hooks                               │  │
│  │  • Configure Git and PowerShell profile                 │  │
│  │  • Initialize Terraform                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         VS Code Server + Extensions                      │  │
│  │  • PowerShell Extension                                  │  │
│  │  • Terraform Extension                                   │  │
│  │  • Azure Extensions                                      │  │
│  │  • Git Extensions (GitLens, PR)                          │  │
│  │  • YAML/JSON/XML Extensions                              │  │
│  │  • Markdown Extensions                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Development Environment Ready                  │  │
│  │  • PowerShell as default terminal                        │  │
│  │  • All tools configured and ready                        │  │
│  │  • Pre-commit hooks installed                            │  │
│  │  • Azure credentials available                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Lifecycle Flow

### Initial Build

```text
1. VS Code reads .devcontainer/devcontainer.json
   ↓
2. Pulls base image: mcr.microsoft.com/devcontainers/base:ubuntu
   ↓
3. Applies Dev Container features:
   - Installs PowerShell, Terraform, Azure CLI, Python, Git, Node.js
   ↓
4. Mounts volumes:
   - ~/.azure → Container ~/.azure (credentials)
   - ~/.ssh → Container ~/.ssh-localhost (SSH keys)
   - Source code → /workspaces/terraform-azure-policy
   ↓
5. Runs postCreateCommand: bash .devcontainer/setup.sh
   - Installs additional packages
   - Installs PowerShell modules
   - Sets up pre-commit hooks
   - Configures environment
   ↓
6. Installs VS Code extensions
   ↓
7. Opens VS Code with PowerShell terminal
   ↓
8. Ready for development! ✅
```

### Subsequent Starts

```text
1. Container already exists
   ↓
2. Start container (cached layers)
   ↓
3. Mount volumes
   ↓
4. Start VS Code server
   ↓
5. Ready in 1-2 minutes! ✅
```

## 🔌 Integration Points

### VS Code Integration

- **Settings**: `.devcontainer/devcontainer.json` → `customizations.vscode.settings`
- **Extensions**: Auto-installed from `customizations.vscode.extensions`
- **Terminal**: Default to PowerShell
- **Debug**: Works with breakpoints in PowerShell and tests

### GitHub Integration

- **Codespaces**: Uses `.devcontainer/devcontainer.codespaces.json` (optional)
- **Actions**: `.github/workflows/devcontainer.yml` tests container build
- **Secrets**: Can be configured for Codespaces environment variables

### Azure Integration

- **Authentication**: `az login` uses mounted `~/.azure` credentials
- **Persistence**: Credentials survive container rebuilds
- **Service Principal**: Can use ARM_* environment variables

### Git Integration

- **SSH Keys**: Copied from host `~/.ssh` directory
- **Configuration**: Git safe directory configured automatically
- **Pre-commit**: Installed and hooks configured during setup

## 📊 Resource Requirements

### Minimum

- **CPU**: 2 cores
- **RAM**: 4 GB
- **Storage**: 20 GB

### Recommended

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Storage**: 32 GB

### Container Size

- **Base Image**: ~1 GB
- **With Features**: ~2 GB
- **Full Setup**: ~3-4 GB

## 🛠️ Tool Versions

All versions are pinned for consistency:

| Tool | Version | Source |
|------|---------|--------|
| PowerShell Core | Latest 7.x | Dev Container Feature |
| Terraform | 1.13.1 | Dev Container Feature |
| Azure CLI | Latest | Dev Container Feature |
| Python | 3.11 | Dev Container Feature |
| Git | Latest | Dev Container Feature |
| GitHub CLI | Latest | Dev Container Feature |
| Node.js | LTS | Dev Container Feature |
| TFLint | Latest | setup.sh |
| actionlint | Latest | setup.sh |
| markdownlint | Latest | npm (setup.sh) |
| Az.Accounts | 2.12.1 | PowerShell (setup.sh) |
| Az.Resources | 6.6.0 | PowerShell (setup.sh) |
| Az.PolicyInsights | 1.6.1 | PowerShell (setup.sh) |
| PSScriptAnalyzer | 1.21.0 | PowerShell (setup.sh) |
| Pester | 5.4.0 | PowerShell (setup.sh) |

## 🔒 Security Considerations

### Credentials

- Azure credentials mounted read-write (needed for token refresh)
- SSH keys mounted read-only, then copied with proper permissions
- `.env` files are gitignored
- Secrets can be configured in GitHub Codespaces

### Network

- Container has full network access (needed for Azure API calls)
- Outbound connections to:
  - Azure Management API
  - GitHub API
  - PowerShell Gallery
  - npm registry
  - Docker Hub

### File System

- Source code mounted as volume (read-write)
- Home directory persists in volume (for caching)
- No host filesystem access outside mounted volumes

## 🎯 Design Decisions

### Why Ubuntu Base?

- Widely used and tested
- Good PowerShell Core support
- Fast package installation
- Compatible with all features

### Why Dev Container Features?

- Declarative configuration
- Version pinning
- Fast installation
- Community maintained

### Why setup.sh?

- Additional packages not available as features
- PowerShell module installation
- Project-specific configuration
- Flexible customization

### Why Mount Azure Credentials?

- Avoid repeated authentication
- Token refresh works seamlessly
- Matches local development workflow
- No credentials in container image

## 📈 Performance Optimizations

### Build Time

- Use features instead of manual installation (parallelized)
- Pin versions to avoid unnecessary updates
- Skip optional modules if not needed
- Use Docker layer caching

### Runtime

- Mount volumes for persistence (not copy)
- Use PowerShell module cache
- Pre-install all required modules
- Configure Git safe directory

### Startup

- Container image cached after first build
- Volumes persist across restarts
- VS Code extensions cached
- No authentication required if cached

## 🔄 Update Strategy

### Updating Tools

```bash
# Update Dev Container features
# Edit .devcontainer/devcontainer.json versions
# Then rebuild container

# Update PowerShell modules
Update-Module -Force

# Update npm packages
npm update -g

# Update pre-commit hooks
pre-commit autoupdate
```

### Updating Configuration

```bash
# Edit .devcontainer/devcontainer.json
# Edit .devcontainer/setup.sh
# Rebuild container to apply changes
```

## 🧪 Testing

The devcontainer is automatically tested in CI/CD:

1. **Build Test**: Ensures container builds successfully
2. **Tool Verification**: Checks all tools are installed
3. **Module Verification**: Checks PowerShell modules
4. **Script Validation**: Lints setup.sh with shellcheck
5. **JSON Validation**: Validates configuration files

See `.github/workflows/devcontainer.yml` for details.

---

**Architecture Version**: 1.0  
**Last Updated**: October 2025  
**Maintainer**: Azure Policy Team
