#!/bin/bash

################################################################################
# Musician Monitor Portal - Send Instruction Script
#
# Sends instructions/commands to specific musicians via Redis Streams
#
# Usage: ./send-instruction.sh <musician> <instruction> [section] [priority]
#        ./send-instruction.sh guitar1 "Play Dm chord" verse urgent
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
    export $(cat .env | grep -v '#' | xargs)
elif [ -f "$HOME/.env" ]; then
    export $(cat "$HOME/.env" | grep -v '#' | xargs)
fi

# Validate environment
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: Upstash credentials not found${NC}"
    exit 1
fi

################################################################################
# Parse Arguments
################################################################################

if [ $# -lt 2 ]; then
    echo -e "${YELLOW}Usage: $0 <musician> <instruction> [section] [priority]${NC}"
    echo ""
    echo -e "${BLUE}Arguments:${NC}"
    echo "  musician:     guitar1, guitar2, saxophone, or vocalist"
    echo "  instruction:  The instruction text (required)"
    echo "  section:      verse, chorus, bridge, outro, or intro (default: none)"
    echo "  priority:     normal or urgent (default: normal)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 guitar1 'Play Dm - Dm - G - A'"
    echo "  $0 guitar1 'Play Dm - Dm - G - A' verse urgent"
    echo "  $0 saxophone 'Solo section' chorus normal"
    exit 1
fi

MUSICIAN="$1"
INSTRUCTION="$2"
SECTION="${3:-}"
PRIORITY="${4:-normal}"

# Validate musician
case "$MUSICIAN" in
    guitar1|guitar2|saxophone|vocalist)
        STREAM_KEY="musician:${MUSICIAN}"
        ;;
    *)
        echo -e "${RED}❌ Invalid musician: $MUSICIAN${NC}"
        echo "Valid options: guitar1, guitar2, saxophone, vocalist"
        exit 1
        ;;
esac

# Validate priority
case "$PRIORITY" in
    normal|urgent)
        ;;
    *)
        echo -e "${RED}❌ Invalid priority: $PRIORITY${NC}"
        echo "Valid options: normal, urgent"
        exit 1
        ;;
esac

# Validate section if provided
if [ -n "$SECTION" ]; then
    case "$SECTION" in
        verse|chorus|bridge|outro|intro)
            ;;
        *)
            echo -e "${RED}❌ Invalid section: $SECTION${NC}"
            echo "Valid options: verse, chorus, bridge, outro, intro"
            exit 1
            ;;
    esac
fi

################################################################################
# Send Instruction
################################################################################

API_URL="${KV_REST_API_URL}"
API_TOKEN="${KV_REST_API_TOKEN}"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Sending Instruction to Musician${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📤 Preparing instruction...${NC}"
echo -e "  Stream:      ${GREEN}${STREAM_KEY}${NC}"
echo -e "  Instruction: ${GREEN}${INSTRUCTION}${NC}"
echo -e "  Timestamp:   ${GREEN}${TIMESTAMP}${NC}"
echo -e "  Priority:    ${GREEN}${PRIORITY}${NC}"
[ -n "$SECTION" ] && echo -e "  Section:     ${GREEN}${SECTION}${NC}"

# Build Redis command
if [ -n "$SECTION" ]; then
    REDIS_CMD="XADD ${STREAM_KEY} * instruction '${INSTRUCTION}' timestamp '${TIMESTAMP}' priority '${PRIORITY}' section '${SECTION}'"
else
    REDIS_CMD="XADD ${STREAM_KEY} * instruction '${INSTRUCTION}' timestamp '${TIMESTAMP}' priority '${PRIORITY}'"
fi

echo -e "\n${YELLOW}📡 Sending to Redis...${NC}"

# Send command
RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${API_URL}" \
    -d "{\"command\": \"${REDIS_CMD}\"}")

# Check response
if echo "$RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}❌ Error sending instruction${NC}"
    echo "Response: $RESPONSE"
    exit 1
else
    MESSAGE_ID=$(echo "$RESPONSE" | grep -o '"[0-9]*-[0-9]*"' | tr -d '"' | head -1)
    echo -e "${GREEN}✅ Instruction sent successfully!${NC}\n"
    echo -e "${BLUE}Message Details:${NC}"
    echo -e "  Message ID: ${GREEN}${MESSAGE_ID}${NC}"
    echo -e "  Stream:     ${GREEN}${STREAM_KEY}${NC}"
    echo -e "  Status:     ${GREEN}Delivered${NC}\n"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
fi
