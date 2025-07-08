#!/bin/bash

# G.Music Assembly - Docker Compose Validation Script
# ♠️🌿🎸🧵 Setup Validation and Testing

set -e

echo "🔍 G.Music Assembly - Validation Suite"
echo "♠️🌿🎸🧵 Docker Compose Setup Validation"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: ${test_name}${NC}"
    ((TOTAL_TESTS++))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: ${test_name}${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL: ${test_name}${NC}"
        ((TESTS_FAILED++))
    fi
    echo
}

# Test 1: Docker Compose Configuration Validation
echo -e "${YELLOW}🧪 Phase 1: Configuration Validation${NC}"
run_test "Docker Compose Configuration" "docker compose config --quiet"
run_test "Docker Compose Services List" "docker compose config --services | grep -q dev"
run_test "Dockerfile Exists" "test -f Dockerfile"
run_test "Init Script Exists" "test -f scripts/init-repos.sh"
run_test "Init Script Executable" "test -x scripts/init-repos.sh"

# Test 2: Environment Configuration
echo -e "${YELLOW}🧪 Phase 2: Environment Configuration${NC}"
run_test "Environment Example File" "test -f .env.example"
run_test "Environment Variables Present" "grep -q GITHUB_TOKEN .env.example"
run_test "Workspace Directory Structure" "test -d workspace"
run_test "Workspace README" "test -f workspace/README.md"

# Test 3: Makefile Validation
echo -e "${YELLOW}🧪 Phase 3: Makefile Validation${NC}"
run_test "Makefile Exists" "test -f Makefile"
run_test "Makefile Help Target" "make help | grep -q 'Available Commands'"
run_test "Makefile Build Target" "make --dry-run build > /dev/null"
run_test "Makefile Init Target" "make --dry-run init > /dev/null"
run_test "Makefile Shell Target" "make --dry-run shell > /dev/null"

# Test 4: Docker Build Process
echo -e "${YELLOW}🧪 Phase 4: Docker Build Process${NC}"
run_test "Docker Build Success" "docker compose build --quiet"
run_test "Base Image Pull" "docker image ls | grep -q python"
run_test "Container Creation" "docker compose create dev"

# Test 5: Volume Management
echo -e "${YELLOW}🧪 Phase 5: Volume Management${NC}"
run_test "Workspace Volume Mount" "docker compose config | grep -q 'workspace:/workspace'"
run_test "Volume Permissions" "docker compose run --rm dev ls -la /workspace"
run_test "Volume Persistence" "docker compose run --rm dev touch /workspace/test.txt && docker compose run --rm dev test -f /workspace/test.txt"

# Test 6: Service Configuration
echo -e "${YELLOW}🧪 Phase 6: Service Configuration${NC}"
run_test "All Services Defined" "grep -E '^  [a-z].*:' docker-compose.yml | wc -l | grep -q 15"
run_test "Service Profiles" "grep -q 'profiles:' docker-compose.yml"
run_test "Environment Variables" "docker compose config | grep -q 'GITHUB_TOKEN'"
run_test "Working Directory" "docker compose config | grep -q 'working_dir: /workspace'"

# Test 7: Network Configuration
echo -e "${YELLOW}🧪 Phase 7: Network Configuration${NC}"
run_test "Network Definition" "docker compose config | grep -q 'dev-network'"
run_test "Network Driver" "docker compose config | grep -q 'driver: bridge'"
run_test "Service Network Assignment" "docker compose config | grep -q 'networks:'"

# Test 8: Security Validation
echo -e "${YELLOW}🧪 Phase 8: Security Validation${NC}"
run_test "Security Documentation" "test -f SECURITY.md"
run_test "No Hardcoded Secrets" "! grep -r 'ghp_[0-9a-zA-Z]*' . --exclude-dir=.git --exclude='*.example' --exclude='SECURITY.md' --exclude='validate-setup.sh'"
run_test "Environment File Permissions" "test -f .env.example && test \$(stat -c '%a' .env.example) -eq 644"
run_test "Script Permissions" "test -x scripts/init-repos.sh && test -x scripts/validate-setup.sh"

# Test 9: Assembly Integration
echo -e "${YELLOW}🧪 Phase 9: Assembly Integration${NC}"
run_test "Assembly Ledger" "test -f testing/ASSEMBLY_LEDGER.md"
run_test "ABC Melody" "test -f assembly_session_melody.abc"
run_test "Claude Configuration" "test -f CLAUDE.md"
run_test "Assembly Mode Indicators" "grep -q '♠️🌿🎸🧵' CLAUDE.md"

# Test 10: Repository Configuration
echo -e "${YELLOW}🧪 Phase 10: Repository Configuration${NC}"
run_test "Repository List in Script" "grep -q 'EchoNexus' scripts/init-repos.sh"
run_test "Repository Count" "grep -c 'REPOS\[' scripts/init-repos.sh | grep -q 12"
run_test "Poetry Detection" "grep -q 'pyproject.toml' scripts/init-repos.sh"
run_test "Pip Detection" "grep -q 'requirements.txt' scripts/init-repos.sh"

# Test Summary
echo "=================================================="
echo -e "${BLUE}🎼 G.Music Assembly Validation Summary${NC}"
echo "=================================================="
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! G.Music Assembly is ready for orchestration.${NC}"
    echo -e "${YELLOW}🎵 Run 'make dev-setup' to begin the symphony!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the configuration.${NC}"
    echo -e "${YELLOW}🔧 Check the failed tests above and retry validation.${NC}"
    exit 1
fi