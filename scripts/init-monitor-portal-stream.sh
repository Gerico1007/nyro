#!/bin/bash

################################################################################
# Musician Monitor Portal - Stream Initialization
#
# Sets up the Redis Stream expected by the Next.js Monitor Portal
# Stream: gmusic:score
# Consumer Group: gmusic:ensemble:sessionA
#
# Usage: ./init-monitor-portal-stream.sh
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
elif [ -f "$HOME/.env" ]; then
    set -a
    source "$HOME/.env"
    set +a
fi

# Validate credentials
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: Upstash credentials not found${NC}"
    exit 1
fi

# Configuration
STREAM_NAME="gmusic:score"
CONSUMER_GROUP="gmusic:ensemble:sessionA"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Musician Monitor Portal - Stream Setup${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"

# Test connection
echo -e "${YELLOW}🔍 Checking Upstash connection...${NC}"
PING=$(curl -s -X POST \
    -H "Authorization: Bearer ${KV_REST_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${KV_REST_API_URL}" \
    -d "$(printf '%s\n' "PING" | jq -R . | jq -s .)")

if echo "$PING" | grep -qi "PONG"; then
    echo -e "${GREEN}✅ Connected to Upstash Redis${NC}\n"
else
    echo -e "${RED}❌ Failed to connect to Upstash Redis${NC}"
    exit 1
fi

# Check if stream exists
echo -e "${YELLOW}📡 Checking stream status...${NC}"
STREAM_EXISTS=$(curl -s -X POST \
    -H "Authorization: Bearer ${KV_REST_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${KV_REST_API_URL}" \
    -d "$(printf '%s\n' "XLEN" "$STREAM_NAME" | jq -R . | jq -s .)")

if echo "$STREAM_EXISTS" | grep -qi '"error"'; then
    echo -e "${YELLOW}  → Creating new stream: ${STREAM_NAME}${NC}"
    # Initialize with a test message
    INIT=$(curl -s -X POST \
        -H "Authorization: Bearer ${KV_REST_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${KV_REST_API_URL}" \
        -d "$(printf '%s\n' "XADD" "$STREAM_NAME" "*" "system" "initialized" "timestamp" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | jq -R . | jq -s .)")

    if echo "$INIT" | grep -qi '"error"'; then
        echo -e "${RED}    ❌ Failed to create stream${NC}"
        exit 1
    fi
    echo -e "${GREEN}    ✅ Stream created${NC}"
else
    COUNT=$(echo "$STREAM_EXISTS" | jq -r '.result // "0"')
    echo -e "${GREEN}  ✅ Stream exists with ${COUNT} messages${NC}"
fi

# Create consumer group
echo -e "${YELLOW}📋 Setting up consumer group...${NC}"
GROUP=$(curl -s -X POST \
    -H "Authorization: Bearer ${KV_REST_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${KV_REST_API_URL}" \
    -d "$(printf '%s\n' "XGROUP" "CREATE" "$STREAM_NAME" "$CONSUMER_GROUP" "0" "MKSTREAM" | jq -R . | jq -s .)")

if echo "$GROUP" | grep -qi '"error"'; then
    if echo "$GROUP" | grep -qi "BUSYGROUP"; then
        echo -e "${GREEN}  ✅ Consumer group already exists${NC}"
    else
        echo -e "${RED}    ❌ Failed to create consumer group${NC}"
        echo "    Error: $(echo "$GROUP" | jq -r '.error // "unknown"')"
    fi
else
    echo -e "${GREEN}  ✅ Consumer group created${NC}"
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Setup Complete!${NC}\n"

echo -e "${BLUE}Stream Configuration:${NC}"
echo -e "  Stream Name:     ${STREAM_NAME}"
echo -e "  Consumer Group:  ${CONSUMER_GROUP}"
echo -e "  Instruments:     guitar_1, guitar_2, saxophone, vocalist\n"

echo -e "${BLUE}Message Format:${NC}"
echo -e "  instrument: guitar_1 | guitar_2 | saxophone | vocalist"
echo -e "  action:     show_chords | show_lyrics | etc."
echo -e "  data:       Chord progressions, lyrics, or instructions"
echo -e "  transpose:  Optional capo/transposition value"
echo -e "  bar:        Optional bar number"
echo -e "  timestamp:  Auto-generated ISO 8601\n"

echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Send instructions to musicians:"
echo -e "     ./scripts/send-monitor-instruction.sh guitar_1 'show_chords' 'C Am F G'"
echo -e "  2. Start the Monitor Portal web app"
echo -e "  3. Open on musician devices\n"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
