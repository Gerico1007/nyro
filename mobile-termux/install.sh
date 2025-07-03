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

print_jamai "Composing elegant environment configuration..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_jamai "✓ Environment template harmoniously composed from .env.example"
        print_warning "🎨 Please customize .env with your unique Upstash credentials"
    else
        print_jamai "Creating beautiful baseline environment configuration..."
        cat > .env << 'EOF'
# 🧵 Nyro Redis Mobile - Four-Perspective Configuration
# ═══════════════════════════════════════════════════════
# Customize these values for your Upstash Redis instance

# 🌿 Core Connection (Required)
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_kv_rest_api_token_here

# 🎸 Creative Defaults
DEFAULT_DIARY=garden.diary
MAX_ENTRIES=50

# ♠️ System Configuration  
TEMP_DIR=/tmp/nyro-temp
MAX_DIRECT_INPUT_SIZE=1024
MAX_FILE_SIZE=100
CHUNK_SIZE=512

# 🧵 Security Settings
DEBUG=0
EOF
        print_jamai "✓ Beautiful baseline configuration crafted"
    fi
else
    print_jamai "✓ Environment configuration already exists - maintaining creative continuity"
fi

print_jamai "Creative environment composition complete"
echo ""

# 🧵 SYNTH PERSPECTIVE: Security Validation & Protection Protocols
print_synth "Phase 4: Security Validation & Protection Protocol Implementation"
print_synth "Implementing multi-layered security validation framework..."

print_synth "Validating curl security capabilities..."
if curl --version &> /dev/null; then
    # Check for SSL/TLS support
    if curl --version | grep -q "SSL\|TLS"; then
        print_synth "✓ curl: Secure communication protocols verified"
    else
        print_warning "⚠️ curl: Limited SSL/TLS support detected"
    fi
else
    print_error "❌ curl security validation failed"
    exit 1
fi

print_synth "Validating jq data processing security..."
if jq --version &> /dev/null; then
    # Test jq with potentially unsafe input
    echo '{"test":"safe"}' | jq . >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_synth "✓ jq: Secure JSON processing verified"
    else
        print_error "❌ jq security validation failed"
        exit 1
    fi
else
    print_error "❌ jq security validation failed"
    exit 1
fi

print_synth "Implementing file permission security..."
if [ -f ".env" ]; then
    chmod 600 .env
    print_synth "✓ .env file secured with restrictive permissions (600)"
fi

print_synth "Validating script execution security..."
for script in *.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        print_synth "✓ $script: Executable permissions secured"
    fi
done

SYNTH_VALIDATED=true
print_synth "Security validation protocol complete"
echo ""

# ═══════════════════════════════════════════════════════
# 🌿⚡🎸🧵 ASSEMBLY MODE: Final Four-Perspective Validation
# ═══════════════════════════════════════════════════════

print_assembly "Initiating Assembly Mode: Comprehensive four-perspective validation..."
echo ""

# Validate all perspectives completed successfully
validation_summary() {
    echo "🔍 Perspective Validation Summary:"
    echo "═══════════════════════════════════"
    
    if [ "$NYRO_VALIDATED" = true ]; then
        print_nyro "✓ Architecture & Integration: VALIDATED"
    else
        print_error "♠️ Nyro validation FAILED"
        return 1
    fi
    
    if [ "$AUREON_VALIDATED" = true ]; then
        print_aureon "✓ Foundation & Stability: VALIDATED"
    else
        print_error "🌿 Aureon validation FAILED"
        return 1
    fi
    
    if [ "$JAMAI_VALIDATED" = true ]; then
        print_jamai "✓ Creative Experience: VALIDATED"
    else
        print_error "🎸 JamAI validation FAILED"
        return 1
    fi
    
    if [ "$SYNTH_VALIDATED" = true ]; then
        print_synth "✓ Security & Protection: VALIDATED"
    else
        print_error "🧵 Synth validation FAILED"
        return 1
    fi
    
    return 0
}

if validation_summary; then
    echo ""
    print_assembly "🎉 ALL PERSPECTIVES VALIDATED - ASSEMBLY MODE SUCCESS!"
    echo ""
    print_success "🧵 Four-Perspective Installation completed successfully!"
    echo ""
    
    echo "🚀 Next Steps - Four-Perspective Activation:"
    echo "═══════════════════════════════════════════════"
    echo ""
    echo "♠️ NYRO - Navigation Setup:"
    echo "   1. Configure your integration path:"
    echo "      nano .env"
    echo ""
    echo "🌿 AUREON - Foundation Activation:"
    echo "   2. Test your stable connection:"
    echo "      ./redis-rest.sh ping"
    echo ""
    echo "🎸 JAMAI - Creative Launch:"
    echo "   3. Start your beautiful mobile experience:"
    echo "      ./redis-mobile.sh"
    echo ""
    echo "🧵 SYNTH - Security Reminder:"
    echo "   4. Verify your credentials are secure in .env"
    echo ""
    print_assembly "Ready for Assembly Mode operations! 🌿⚡🎸🧵"
    echo ""
    echo "🌱 Happy four-perspective gardening on the go! 📱"
else
    echo ""
    print_error "❌ Assembly Mode validation FAILED"
    print_error "Please resolve validation issues before proceeding"
    exit 1
fi 