#!/bin/bash

# Nyro Redis Mobile - Termux Installation Script
# This script sets up the mobile environment for Android Termux

echo "🌱 Nyro Redis Mobile - Termux Installation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if we're in Termux
if [ ! -d "/data/data/com.termux" ]; then
    print_warning "This script is designed for Termux on Android"
    print_warning "Some features may not work on other systems"
    echo ""
fi

print_status "Updating package repositories..."
pkg update -y

print_status "Installing required packages..."
pkg install -y curl jq git

# Check if packages were installed successfully
if command -v curl &> /dev/null; then
    print_success "curl installed successfully"
else
    print_error "Failed to install curl"
    exit 1
fi

if command -v jq &> /dev/null; then
    print_success "jq installed successfully"
else
    print_error "Failed to install jq"
    exit 1
fi

print_status "Making scripts executable..."
chmod +x *.sh

print_status "Creating .env file from template..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "Created .env file from template"
        print_warning "Please edit .env file with your Upstash credentials"
    else
        print_warning "No .env.example found, creating basic .env file"
        cat > .env << EOF
# Upstash Redis Configuration
# Replace with your actual credentials

KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_kv_rest_api_token_here

# Optional: Default diary name
DEFAULT_DIARY=garden.diary
EOF
        print_success "Created basic .env file"
    fi
else
    print_success ".env file already exists"
fi

print_status "Testing curl installation..."
if curl --version &> /dev/null; then
    print_success "curl is working properly"
else
    print_error "curl is not working properly"
    exit 1
fi

print_status "Testing jq installation..."
if jq --version &> /dev/null; then
    print_success "jq is working properly"
else
    print_error "jq is not working properly"
    exit 1
fi

echo ""
print_success "Installation completed successfully!"
echo ""
echo "📱 Next steps:"
echo "1. Edit .env file with your Upstash credentials:"
echo "   nano .env"
echo ""
echo "2. Start using Nyro Redis Mobile:"
echo "   ./redis-mobile.sh"
echo ""
echo "3. For help, run:"
echo "   ./redis-mobile.sh --help"
echo ""
print_warning "Don't forget to configure your .env file with your Upstash credentials!"
echo ""
echo "🌱 Happy gardening on the go! 📱" 