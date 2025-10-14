#!/bin/bash
# Install NuGet CLI for local Linux/macOS environments
# This script provides NuGet CLI access for package management
set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

echo "🎯 NuGet CLI Installation Script"
echo "=================================="
echo ""

# Check if running on macOS or Linux
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

print_status "Detected OS: $MACHINE"
echo ""

# Check if .NET SDK is already installed
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version 2>/dev/null)
    print_success ".NET SDK already installed: $DOTNET_VERSION"

    # Test NuGet
    print_status "Testing NuGet functionality..."
    if dotnet nuget --version &> /dev/null; then
        print_success "NuGet is available via 'dotnet nuget' command"
        echo ""
        echo "✅ NuGet CLI is ready to use!"
        echo ""
        echo "Usage examples:"
        echo "  dotnet nuget --version"
        echo "  dotnet nuget push package.nupkg --source https://www.myget.org/F/your-feed/api/v3/index.json --api-key YOUR_KEY"
        echo "  dotnet nuget list source"
        exit 0
    fi
fi

# If .NET SDK not found, offer installation options
print_warning ".NET SDK not found. Installing..."
echo ""

if [ "$MACHINE" = "Mac" ]; then
    print_status "Installing .NET SDK via Homebrew (recommended for macOS)..."

    if command -v brew &> /dev/null; then
        brew install dotnet
        print_success ".NET SDK installed via Homebrew"
    else
        print_warning "Homebrew not found. Installing via Microsoft script..."
        # Download the installer script to a temporary file
        DOTNET_INSTALL_URL="https://dot.net/v1/dotnet-install.sh"
        DOTNET_INSTALL_SCRIPT="$(mktemp)"
        curl -sSL "$DOTNET_INSTALL_URL" -o "$DOTNET_INSTALL_SCRIPT"

        # Optional: Set the expected checksum here (update as needed)
        # You should obtain the expected checksum from https://dot.net/v1/dotnet-install.sh.sha512 or a trusted source
        # Example: EXPECTED_CHECKSUM="abc123..."
        EXPECTED_CHECKSUM=""

        if [ -n "$EXPECTED_CHECKSUM" ]; then
            # Compute the checksum of the downloaded script
            if command -v sha512sum &> /dev/null; then
                COMPUTED_CHECKSUM=$(sha512sum "$DOTNET_INSTALL_SCRIPT" | awk '{print $1}')
            elif command -v shasum &> /dev/null; then
                COMPUTED_CHECKSUM=$(shasum -a 512 "$DOTNET_INSTALL_SCRIPT" | awk '{print $1}')
            else
                print_error "No SHA512 checksum tool found. Please install sha512sum or shasum."
                rm -f "$DOTNET_INSTALL_SCRIPT"
                exit 1
            fi

            if [ "$COMPUTED_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
                print_error "Checksum verification failed! Aborting installation."
                rm -f "$DOTNET_INSTALL_SCRIPT"
                exit 1
            else
                print_success "Checksum verification passed."
            fi
        else
            print_warning "No checksum provided. Proceeding without verification. (Not recommended for production use.)"
        fi

        # Execute the installer script
        bash "$DOTNET_INSTALL_SCRIPT" --channel 9.0
        rm -f "$DOTNET_INSTALL_SCRIPT"
        # Add to PATH
        export DOTNET_ROOT=$HOME/.dotnet
        export PATH=$PATH:$DOTNET_ROOT

        print_status "Adding .NET to PATH in your shell profile..."
        if [ -f "$HOME/.zshrc" ]; then
            echo 'export DOTNET_ROOT=$HOME/.dotnet' >> "$HOME/.zshrc"
            echo 'export PATH=$PATH:$DOTNET_ROOT' >> "$HOME/.zshrc"
            print_success "Added to ~/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            echo 'export DOTNET_ROOT=$HOME/.dotnet' >> "$HOME/.bashrc"
            echo 'export PATH=$PATH:$DOTNET_ROOT' >> "$HOME/.bashrc"
            print_success "Added to ~/.bashrc"
        fi

        print_warning "Please restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
    fi

elif [ "$MACHINE" = "Linux" ]; then
    print_status "Installing .NET SDK on Linux..."

    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        print_status "Detected distribution: $DISTRO"

        case $DISTRO in
            ubuntu|debian)
                print_status "Installing via Microsoft package repository..."
                # Import Microsoft GPG public key
                wget https://packages.microsoft.com/keys/microsoft.asc -O microsoft.asc
                # Verify Microsoft GPG key fingerprint
                MS_FPR="BC528686B50D79E339D3721CEB3E94ADBE1229CF"  # Microsoft's official GPG key fingerprint for package verification (public, not a secret) - pragma: allowlist secret
                GPG_FPR=$(gpg --show-keys --with-colons microsoft.asc | awk -F: '/^fpr:/ {print $10; exit}')
                if [ "$GPG_FPR" != "$MS_FPR" ]; then
                    echo -e "${RED}[ERROR]${NC} Microsoft GPG key fingerprint does not match! Aborting."
                    rm -f microsoft.asc
                    exit 1
                fi
                gpg --dearmor < microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null  # pragma: allowlist secret
                rm microsoft.asc
                wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
                # (Optional) Verify checksum if Microsoft publishes it
                # Example: wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb.sha256 -O packages-microsoft-prod.deb.sha256
                # sha256sum -c packages-microsoft-prod.deb.sha256 || { echo -e "${RED}[ERROR]${NC} Checksum verification failed!"; exit 1; }
                sudo dpkg -i packages-microsoft-prod.deb
                rm packages-microsoft-prod.deb

                sudo apt-get update
                sudo apt-get install -y dotnet-sdk-9.0
                print_success ".NET SDK installed"
                ;;

            fedora|rhel|centos)
                print_status "Installing via dnf..."
                sudo dnf install -y dotnet-sdk-9.0
                print_success ".NET SDK installed"
                ;;

            *)
                print_warning "Unsupported distribution: $DISTRO"
                print_status "Installing via Microsoft script..."
                TMP_SCRIPT=$(mktemp)
                curl -sSL https://dot.net/v1/dotnet-install.sh -o "$TMP_SCRIPT"
                SCRIPT_SHA256=$(sha256sum "$TMP_SCRIPT" | awk '{print $1}')
                print_status "Downloaded script SHA256: $SCRIPT_SHA256"
                if [ -z "$DOTNET_INSTALL_SHASUM" ]; then
                    print_error "No expected checksum provided. Please set DOTNET_INSTALL_SHASUM to the expected SHA256 value."
                    print_status "You can find the expected checksum at https://dot.net/v1/dotnet-install.sh.sha256 or by downloading it manually."
                    print_status "Aborting installation for security reasons."
                    rm -f "$TMP_SCRIPT"
                    exit 1
                fi
                if [ "$SCRIPT_SHA256" != "$DOTNET_INSTALL_SHASUM" ]; then
                    print_error "Checksum verification failed! Expected: $DOTNET_INSTALL_SHASUM, Got: $SCRIPT_SHA256"
                    rm -f "$TMP_SCRIPT"
                    exit 1
                fi
                print_success "Checksum verification passed."
                bash "$TMP_SCRIPT" --channel 9.0
                rm -f "$TMP_SCRIPT"

                export DOTNET_ROOT=$HOME/.dotnet
                export PATH=$PATH:$DOTNET_ROOT

                echo 'export DOTNET_ROOT=$HOME/.dotnet' >> "$HOME/.bashrc"
                echo 'export PATH=$PATH:$DOTNET_ROOT' >> "$HOME/.bashrc"
                print_success ".NET SDK installed to ~/.dotnet"
                print_warning "Please restart your terminal or run: source ~/.bashrc"
                ;;
        esac
    else
        print_error "Cannot detect Linux distribution. Please install .NET SDK manually:"
        print_status "Visit: https://dotnet.microsoft.com/download"
        exit 1
    fi
else
    print_error "Unsupported operating system: $MACHINE"
    print_status "Please install .NET SDK manually from: https://dotnet.microsoft.com/download"
    exit 1
fi

# Verify installation
echo ""
print_status "Verifying installation..."
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    print_success ".NET SDK installed successfully: $DOTNET_VERSION"

    print_status "Testing NuGet..."
    if dotnet nuget --version &> /dev/null; then
        print_success "NuGet is available via 'dotnet nuget' command"
    else
        print_error "NuGet command failed. Please check your installation."
        exit 1
    fi
else
    print_error "Installation verification failed. Please check the output above."
    exit 1
fi

echo ""
echo "✅ NuGet CLI installation complete!"
echo ""
echo "📚 Usage examples:"
echo "  # Check version"
echo "  dotnet nuget --version"
echo ""
echo "  # Add a source"
echo "  dotnet nuget add source https://www.myget.org/F/your-feed/api/v3/index.json --name MyGet"
echo ""
echo "  # List sources"
echo "  dotnet nuget list source"
echo ""
echo "  # Push a package"
echo "  dotnet nuget push package.nupkg --source MyGet --api-key YOUR_KEY"
echo ""
echo "📖 For more information, visit: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget"
echo ""

exit 0
