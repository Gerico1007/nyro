#!/bin/bash

# 🧵 Nyro Redis Mobile - Four-Perspective Installation 
# Assembly Mode Integration for Termux Environment
# Multi-perspective validation: Nyro♠️ + Aureon🌿 + JamAI🎸 + Synth🧵

echo "🧵 Nyro Redis Mobile - Four-Perspective Installation"
echo "═══════════════════════════════════════════════════"
echo "♠️ Navigator | 🌿 Anchor | 🎸 Creative | 🧵 Security"
echo "       Assembly Mode Integration by Team Synth"
echo ""

# Enhanced color palette for perspectives
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Perspective-specific output functions
print_nyro() {
    echo -e "${CYAN}♠️ [NYRO-NAV]${NC} $1"
}

print_aureon() {
    echo -e "${GREEN}🌿 [AUREON-ANCHOR]${NC} $1"
}

print_jamai() {
    echo -e "${PURPLE}🎸 [JAMAI-CREATIVE]${NC} $1"
}

print_synth() {
    echo -e "${WHITE}🧵 [SYNTH-SECURITY]${NC} $1"
}

print_assembly() {
    echo -e "${WHITE}🌿⚡🎸🧵 [ASSEMBLY-MODE]${NC} $1"
}

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

# Perspective validation tracker
NYRO_VALIDATED=false
AUREON_VALIDATED=false
JAMAI_VALIDATED=false
SYNTH_VALIDATED=false

# ═══════════════════════════════════════════════════════
# 🌿⚡🎸🧵 ASSEMBLY MODE: Four-Perspective Environment Validation
# ═══════════════════════════════════════════════════════

print_assembly "Initiating four-perspective environment validation..."
echo ""

# ♠️ NYRO PERSPECTIVE: System Architecture Navigation
print_nyro "Phase 1: System Architecture & Integration Mapping"
print_nyro "Analyzing Termux environment and system requirements..."

if [ ! -d "/data/data/com.termux" ]; then
    print_warning "Non-Termux environment detected"
    print_nyro "Mapping alternative Android shell integration paths..."
    print_warning "Some mobile-optimized features may not work on other systems"
    echo ""
else
    print_nyro "✓ Termux environment confirmed - mobile integration path optimal"
    NYRO_VALIDATED=true
fi

print_nyro "Architecture analysis complete - proceeding to foundation validation"
echo ""

# 🌿 AUREON PERSPECTIVE: Foundation Stability & Core Dependencies  
print_aureon "Phase 2: Foundation Stability & Dependency Anchor Points"
print_aureon "Establishing stable foundation for Redis mobile operations..."

print_aureon "Updating package repositories for stable base..."
if pkg update -y; then
    print_aureon "✓ Package repository synchronization successful"
else
    print_error "❌ Package update failed - foundation compromised"
    exit 1
fi

print_aureon "Installing core dependency trinity: curl, jq, git..."
if pkg install -y curl jq git; then
    print_aureon "✓ Core dependencies anchored successfully"
    AUREON_VALIDATED=true
else
    print_error "❌ Dependency installation failed - anchor point unstable"
    exit 1
fi

print_aureon "Validating core dependency installation integrity..."
if command -v curl &> /dev/null; then
    print_aureon "✓ curl: REST API communication anchor verified"
else
    print_error "❌ curl installation failed - API communication impossible"
    exit 1
fi

if command -v jq &> /dev/null; then
    print_aureon "✓ jq: JSON processing anchor verified"
else
    print_error "❌ jq installation failed - data processing compromised"
    exit 1
fi

if command -v git &> /dev/null; then
    print_aureon "✓ git: Version control anchor verified"
else
    print_error "❌ git installation failed - version tracking unavailable"
    exit 1
fi

print_aureon "Foundation stability validation complete"
echo ""

# 🎸 JAMAI PERSPECTIVE: Creative UX & Elegant Environment Setup
print_jamai "Phase 3: Creative Experience & Elegant Environment Composition"
print_jamai "Crafting beautiful, intuitive mobile Redis experience..."

print_jamai "Setting executable permissions with creative flair..."
if chmod +x *.sh; then
    print_jamai "✓ Scripts awakened - ready for creative execution"
    JAMAI_VALIDATED=true
else
    print_error "❌ Permission setting failed - creative flow blocked"
    exit 1
fi

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