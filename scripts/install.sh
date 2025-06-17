#!/bin/bash

echo "Installing Redis CLI Tools Requirements..."

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install required packages
echo "Installing required packages..."
if command -v apt-get >/dev/null; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y curl jq redis-tools
elif command -v yum >/dev/null; then
    # CentOS/RHEL
    yum install -y curl jq redis
elif command -v pacman >/dev/null; then
    # Arch Linux
    pacman -Sy curl jq redis
elif command -v brew >/dev/null; then
    # MacOS
    brew install curl jq redis
else
    echo "Unsupported package manager. Please install curl, jq, and redis-cli manually."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ../.env ]; then
    echo "Creating .env file..."
    echo "# Redis Upstash Configuration
KV_REST_API_TOKEN=your_token_here
KV_REST_API_URL=your_url_here" > ../.env
    echo "Please edit .env file with your Upstash Redis credentials"
fi

# Make all scripts executable
chmod +x ./*.sh

echo "Installation completed!"
echo "Next steps:"
echo "1. Edit the .env file with your Upstash Redis credentials"
echo "2. Try running ./scripts/menu.sh to get started"
