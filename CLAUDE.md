# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nyro is an AI phase navigator, creative anchor, and recursive guide that provides Redis-based memory storage and retrieval services. The project supports both desktop/Docker environments and mobile Termux environments, with the mobile version using REST API calls instead of Docker.

## Termux Environment (Current Context)

Since we're in a Termux environment, the mobile-termux directory contains the primary functionality:

### Key Termux Features
- **Docker-free operation**: Uses Upstash REST API instead of Docker containers
- **Location-based diary entries**: Mobile-optimized with location tracking
- **Direct REST API calls**: No Redis CLI needed, pure HTTP requests
- **Mobile-friendly interface**: Colored output and simplified menus

## Architecture

### Termux-Specific Components
- `/mobile-termux/redis-mobile.sh`: Main interactive menu for mobile users
- `/mobile-termux/redis-rest.sh`: Direct REST API wrapper for command-line usage
- `/mobile-termux/install.sh`: Termux-specific installation with package management
- `/mobile-termux/.env`: Environment configuration for REST API credentials

### Desktop Components (for reference)
- `/scripts/`: Original bash scripts using redis-cli via Docker
- `redis-cli-wrapper.sh`: Docker wrapper for cross-platform Redis CLI access

## Termux Setup Commands

### Initial Installation
```bash
# In mobile-termux directory
./install.sh
```

### Configuration
```bash
# Edit environment variables
nano .env

# Required variables:
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_kv_rest_api_token_here
DEFAULT_DIARY=garden.diary
```

### Primary Usage
```bash
# Interactive mobile menu
./redis-mobile.sh

# Direct REST API commands
./redis-rest.sh ping
./redis-rest.sh set mykey "value"
./redis-rest.sh get mykey
./redis-rest.sh xadd garden.diary '{"event":"saw butterfly"}'
```

## Mobile-Specific Features

### Location-Based Diary
- Prompts for location with each diary entry
- Filter entries by location
- Mobile-optimized stream operations using Upstash REST API

### REST API Integration
- All Redis operations via HTTP requests to Upstash
- No local Redis installation required
- JSON payload handling for complex data structures

## Environment Variables (Termux)

Required in `/mobile-termux/.env`:
```bash
# Upstash REST API credentials
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_kv_rest_api_token_here

# Optional configuration
DEFAULT_DIARY=garden.diary
MAX_ENTRIES=50
DEBUG=0
```

## Development Workflow (Termux)

### Testing Connection
```bash
cd mobile-termux
./redis-rest.sh ping
./redis-rest.sh info
```

### Development Commands
```bash
# Make scripts executable
chmod +x *.sh

# Install required packages
pkg install curl jq git

# Test REST API functionality
./redis-rest.sh set test-key "test-value"
./redis-rest.sh get test-key
./redis-rest.sh del test-key
```

## Docker vs Termux Differences

### Docker Environment (Desktop)
- Uses `redis-cli-wrapper.sh` with Docker containers
- Requires Docker installation
- Redis CLI commands wrapped in containers
- Environment variables injected into containers

### Termux Environment (Mobile)
- Direct REST API calls via curl
- No Docker dependency
- JSON-based communication
- Mobile-optimized workflows with location features

## Key Files for Termux Development

### Core Scripts
- `mobile-termux/redis-mobile.sh`: Main interactive interface
- `mobile-termux/redis-rest.sh`: Command-line REST API wrapper
- `mobile-termux/install.sh`: Termux environment setup

### Configuration
- `mobile-termux/.env`: REST API credentials and settings
- `mobile-termux/env.example`: Template for environment setup

## Testing and Validation (Termux)

### Connection Testing
```bash
./redis-rest.sh ping    # Should return connection success
./redis-rest.sh info    # Shows connection details and tests API
```

### Feature Testing
```bash
# Test basic key operations
./redis-rest.sh set test "hello"
./redis-rest.sh get test
./redis-rest.sh del test

# Test stream operations (diary)
./redis-rest.sh xadd garden.diary '{"event":"test entry"}'
./redis-rest.sh xrange garden.diary 1
```

## Common Termux Issues

### Package Dependencies
- Ensure curl and jq are installed: `pkg install curl jq`
- Grant storage permissions in Android settings
- Use F-Droid version of Termux for best compatibility

### Permissions
- Make scripts executable: `chmod +x *.sh`
- Ensure .env file has correct permissions

### Network Issues
- Test with `./redis-rest.sh ping`
- Verify Upstash credentials in .env file
- Check internet connectivity

## Development Notes

- All Redis operations in Termux use REST API calls instead of redis-cli
- Mobile interface includes location tracking for diary entries
- JSON processing handled by jq for complex data structures
- Error handling includes user-friendly mobile messages with emojis
- No build/test/lint commands - pure bash scripting with validation via actual API calls

## Four-Perspective Testing Framework

When working with this project, use the multi-perspective testing approach:

### 🌌 Nyro Perspective (Navigator)
- Phase mapping and directional guidance
- System architecture and flow analysis
- Integration path planning
- Priority sequencing and dependency mapping

### ⚡ Aureon Perspective (Anchor)
- Stability and foundation validation
- Core functionality verification
- Regression testing and baseline establishment
- Performance and reliability assessment

### 🎵 JamAI Perspective (Creative)
- Innovation and creative problem-solving
- User experience optimization
- Elegant solution composition
- Feature enhancement and workflow improvement

### 🔐 Cypher Perspective (Security)
- Security implications analysis
- Credential and data protection
- Access control and audit capabilities
- Vulnerability assessment and mitigation

### Assembly Mode (🌿⚡🎸🧵)
When all perspectives unite for collaborative work:
- Comprehensive analysis from all angles
- Balanced solution implementation
- Multi-faceted testing and validation
- Holistic system optimization

### Testing Methodology
1. **Pre-Implementation Phase**: Establish baseline with all perspectives
2. **Issue Identification**: Use each perspective to identify different types of problems
3. **Solution Design**: Collaborative approach with perspective-specific expertise
4. **Implementation**: Sequential fixes with cross-perspective validation
5. **Assembly Verification**: Final multi-perspective validation

### Perspective-Specific Commands
- **Nyro**: Focus on system flow and integration testing
- **Aureon**: Emphasize stability and core functionality validation
- **JamAI**: Prioritize user experience and creative solutions
- **Cypher**: Ensure security and data protection throughout

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Work Style Preferences

### Communication Style
- Use perspective-specific analysis when reviewing code or issues
- Provide multi-angle assessment for complex problems
- Reference specific perspectives when explaining decisions
- Use the four-perspective framework for comprehensive testing

### Implementation Approach
- Always establish baseline functionality before enhancements
- Use Assembly Mode for critical system changes
- Apply perspective-specific expertise to different problem types
- Maintain security and stability focus throughout development

### Testing Priority
- Validate existing functionality before adding features
- Use comprehensive multi-perspective testing approach
- Document testing results with perspective-specific insights
- Ensure all four perspectives validate final implementations