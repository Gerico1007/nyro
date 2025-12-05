#!/bin/bash

################################################################################
# Musician Monitor Portal - Redis Streams Initialization Script
#
# Creates and configures Redis Streams for musician instruction delivery
# in the musician monitor portal system.
#
# Usage: ./init-musician-streams.sh
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '#' | xargs)
elif [ -f "$HOME/.env" ]; then
    export $(cat "$HOME/.env" | grep -v '#' | xargs)
else
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo "Please create a .env file with Upstash credentials"
    exit 1
fi

# Verify required environment variables
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: KV_REST_API_URL or KV_REST_API_TOKEN not set${NC}"
    exit 1
fi

# API endpoint
API_URL="${KV_REST_API_URL}"
API_TOKEN="${KV_REST_API_TOKEN}"

# Musician configurations
declare -A MUSICIANS=(
    [guitar1]="Guitar 1 - Rhythm"
    [guitar2]="Guitar 2 - Lead"
    [saxophone]="Saxophone - Melody"
    [vocalist]="Vocalist - Lead Voice"
)

################################################################################
# Helper Functions
################################################################################

# Send Redis command via Upstash REST API
redis_command() {
    # Convert arguments to JSON array
    # Usage: redis_command XADD stream_key '*' field1 value1 field2 value2...
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${API_URL}" \
        -d "$(printf '%s\n' "$@" | jq -R . | jq -s .)")

    echo "$response"
}

# Check if stream exists
stream_exists() {
    local stream="$1"
    local response=$(redis_command "XLEN" "$stream")

    if echo "$response" | grep -qi '"error"'; then
        return 1
    fi
    return 0
}

# Check if consumer group exists
group_exists() {
    local stream="$1"
    local group="$2"
    local response=$(redis_command "XINFO" "GROUPS" "$stream")

    if echo "$response" | grep -qi '"error"'; then
        return 1
    fi
    if echo "$response" | grep -q "$group"; then
        return 0
    fi
    return 1
}

################################################################################
# Initialize Streams
################################################################################

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Musician Monitor Portal - Redis Streams Initialization${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"

# Check connection
echo -e "${YELLOW}🔍 Checking Upstash connection...${NC}"
connection_test=$(redis_command "PING")
if echo "$connection_test" | grep -q "PONG"; then
    echo -e "${GREEN}✅ Connected to Upstash Redis${NC}\n"
else
    echo -e "${RED}❌ Failed to connect to Upstash Redis${NC}"
    echo "Response: $connection_test"
    exit 1
fi

# Initialize each musician stream
echo -e "${YELLOW}📡 Initializing musician streams...${NC}\n"

for musician in "${!MUSICIANS[@]}"; do
    stream_key="musician:${musician}"
    group_name="monitor_group"
    description="${MUSICIANS[$musician]}"

    echo -e "${BLUE}→ Setting up ${description}${NC}"

    # Check if stream exists
    if stream_exists "$stream_key"; then
        echo -e "${YELLOW}  ⓘ Stream already exists: $stream_key${NC}"
    else
        # Create stream with initial message
        echo -e "${YELLOW}  → Creating stream: $stream_key${NC}"
        TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        init_response=$(redis_command "XADD" "$stream_key" "*" "instruction" "Ready to begin" "timestamp" "$TIMESTAMP" "priority" "normal" "section" "intro")

        if echo "$init_response" | grep -qi '"error"'; then
            echo -e "${RED}    ❌ Failed to create stream${NC}"
            echo "    Error: $init_response"
        else
            echo -e "${GREEN}    ✅ Stream created successfully${NC}"
        fi
    fi

    # Check if consumer group exists
    if group_exists "$stream_key" "$group_name"; then
        echo -e "${YELLOW}  ⓘ Consumer group already exists: $group_name${NC}"
    else
        # Create consumer group
        echo -e "${YELLOW}  → Creating consumer group: $group_name${NC}"
        group_response=$(redis_command "XGROUP" "CREATE" "$stream_key" "$group_name" "0" "MKSTREAM")

        if echo "$group_response" | grep -qi '"error"'; then
            echo -e "${RED}    ❌ Failed to create consumer group${NC}"
            echo "    Error: $group_response"
        else
            echo -e "${GREEN}    ✅ Consumer group created successfully${NC}"
        fi
    fi

    echo ""
done

################################################################################
# Verify Setup
################################################################################

echo -e "${YELLOW}✔️ Verifying stream setup...${NC}\n"

for musician in "${!MUSICIANS[@]}"; do
    stream_key="musician:${musician}"

    # Get stream length
    length_response=$(redis_command "XLEN" "$stream_key")

    if echo "$length_response" | grep -qi '"error"'; then
        echo -e "${RED}❌ $stream_key - Error getting stream info${NC}"
    else
        length=$(echo "$length_response" | jq -r '.result // .error' 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ $stream_key${NC} (${length} messages)"
    fi
done

################################################################################
# Summary
################################################################################

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Setup Complete!${NC}\n"

echo -e "${BLUE}Stream Configuration:${NC}"
echo -e "  • Guitar 1 (Rhythm):     musician:guitar1"
echo -e "  • Guitar 2 (Lead):       musician:guitar2"
echo -e "  • Saxophone (Melody):    musician:saxophone"
echo -e "  • Vocalist (Lead Voice): musician:vocalist\n"

echo -e "${BLUE}Consumer Group:${NC}"
echo -e "  • All streams use group: monitor_group\n"

echo -e "${BLUE}Message Format:${NC}"
echo -e "  • instruction: The actual instruction/command"
echo -e "  • timestamp:   ISO 8601 format timestamp"
echo -e "  • priority:    'normal' or 'urgent'"
echo -e "  • section:     'verse', 'chorus', 'bridge', 'outro' (optional)\n"

echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Send instructions via REST API or Redis CLI"
echo -e "  2. Monitor portal will auto-poll streams"
echo -e "  3. Musicians receive real-time updates\n"

echo -e "${YELLOW}Example command to send instruction:${NC}"
echo -e "  ./scripts/send-instruction.sh guitar1 'Play Dm - Dm - G - A' verse urgent\n"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
