#!/bin/bash

# Nyro Quick Setup Script
# ♠️🌿🎸🧵 G.Music Assembly - One-command installation

echo "🎼 Nyro Quick Setup - ♠️🌿🎸🧵 G.Music Assembly"
echo "=============================================="
echo

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3.7+ and try again."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check pip
if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    echo "❌ pip is required but not installed."
    echo "Please install pip and try again."
    exit 1
fi

# Use pip3 if available, otherwise pip
PIP_CMD="pip"
if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
fi

echo "✅ pip found: $PIP_CMD"
echo

# Get the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🚀 Installing Nyro package..."
cd "$SCRIPT_DIR"

# Install package
$PIP_CMD install -e . || {
    echo "❌ Installation failed. Trying with --user flag..."
    $PIP_CMD install -e . --user || {
        echo "❌ Installation failed. Please check your Python/pip setup."
        exit 1
    }
}

echo "✅ Nyro package installed successfully!"
echo

# Initialize environment if .env doesn't exist
if [ ! -f ".env" ]; then
    echo "🔧 Initializing environment..."
    nyro init
    echo "✅ Environment initialized!"
    echo
    echo "📝 IMPORTANT: Please edit .env file with your Redis credentials:"
    echo "   - KV_REST_API_URL: Your Upstash Redis URL"
    echo "   - KV_REST_API_TOKEN: Your Upstash Redis token"
    echo
else
    echo "✅ .env file already exists"
fi

# Test installation
echo "🧪 Testing installation..."
if nyro --help > /dev/null 2>&1; then
    echo "✅ Nyro command works!"
else
    echo "❌ Nyro command not working. Check your PATH."
    exit 1
fi

echo
echo "🎯 Setup Complete! Next steps:"
echo "1. Edit .env file: nano .env"
echo "2. Test connection: nyro test"
echo "3. Start using: nyro interactive"
echo
echo "🎼 Welcome to the ♠️🌿🎸🧵 G.Music Assembly experience!"
echo "🎵 Your 13+ bash scripts are now unified in harmonic Python!"
echo
echo "Commands available:"
echo "  nyro interactive  # Interactive CLI (replaces all bash menus)"
echo "  nyro test        # Test Redis connection"
echo "  nyro set key val # Set a key (replaces set-key.sh)"
echo "  nyro get key     # Get a key (replaces get-key.sh)"
echo "  nyro scan        # Scan keys (replaces scan-garden.sh)"
echo "  nyro profiles    # Manage profiles"
echo "  nyro --help      # Full command reference"
echo
echo "🎼 Musical features: nyro --musical interactive"