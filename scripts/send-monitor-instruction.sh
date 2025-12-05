#!/bin/bash

################################################################################
# Musician Monitor Portal - Send Instruction Script
#
# Sends instructions to the gmusic:score stream
# Instruments receive messages filtered by their instrument field
#
# Usage: ./send-monitor-instruction.sh <instrument> <action> <data> [transpose] [bar]
#        ./send-monitor-instruction.sh guitar_1 show_chords "C Am F G"
#        ./send-monitor-instruction.sh guitar_2 show_chords "Am Em" 2
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

# Validate environment
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: Upstash credentials not found${NC}"
    exit 1
fi

################################################################################
# Parse Arguments
################################################################################

if [ $# -lt 3 ]; then
    echo -e "${YELLOW}Usage: $0 <instrument> <action> <data> [transpose] [bar]${NC}"
    echo ""
    echo -e "${BLUE}Arguments:${NC}"
    echo "  instrument:  guitar_1, guitar_2, saxophone, or vocalist"
    echo "  action:      show_chords, show_lyrics, highlight_section, etc."
    echo "  data:        The actual data (chords, lyrics, section name)"
    echo "  transpose:   Optional transposition value for guitarists"
    echo "  bar:         Optional bar/measure number"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 guitar_1 show_chords 'C Am F G'"
    echo "  $0 guitar_2 show_chords 'G Bm Em A' 2"
    echo "  $0 vocalist show_lyrics 'Verse 1: La la la...'"
    echo "  $0 saxophone highlight_section 'Chorus Solo'"
    exit 1
fi

INSTRUMENT="$1"
ACTION="$2"
DATA="$3"
TRANSPOSE="${4:-}"
BAR="${5:-}"

# Validate instrument
case "$INSTRUMENT" in
    guitar_1|guitar_2|saxophone|vocalist)
        ;;
    *)
        echo -e "${RED}❌ Invalid instrument: $INSTRUMENT${NC}"
        echo "Valid options: guitar_1, guitar_2, saxophone, vocalist"
        exit 1
        ;;
esac

STREAM_NAME="gmusic:score"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Sending to Monitor Portal${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📤 Message Details:${NC}"
echo -e "  Stream:      ${GREEN}${STREAM_NAME}${NC}"
echo -e "  Instrument:  ${GREEN}${INSTRUMENT}${NC}"
echo -e "  Action:      ${GREEN}${ACTION}${NC}"
echo -e "  Data:        ${GREEN}${DATA}${NC}"
[ -n "$TRANSPOSE" ] && echo -e "  Transpose:   ${GREEN}${TRANSPOSE}${NC}"
[ -n "$BAR" ] && echo -e "  Bar:         ${GREEN}${BAR}${NC}"
echo -e "  Timestamp:   ${GREEN}${TIMESTAMP}${NC}"

echo -e "\n${YELLOW}📡 Sending to Redis...${NC}"

# Build command with fields
if [ -n "$TRANSPOSE" ] && [ -n "$BAR" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "transpose" "$TRANSPOSE" \
        "bar" "$BAR" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
elif [ -n "$TRANSPOSE" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "transpose" "$TRANSPOSE" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
elif [ -n "$BAR" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "bar" "$BAR" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
else
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
fi

RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer ${KV_REST_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${KV_REST_API_URL}" \
    -d "$CMD_ARRAY")

# Check response
if echo "$RESPONSE" | grep -qi '"error"'; then
    echo -e "${RED}❌ Error sending instruction${NC}"
    echo "Response: $RESPONSE"
    exit 1
else
    MESSAGE_ID=$(echo "$RESPONSE" | jq -r '.result // empty' 2>/dev/null)
    if [ -z "$MESSAGE_ID" ]; then
        MESSAGE_ID=$(echo "$RESPONSE" | grep -o '[0-9]*-[0-9]*' | head -1)
    fi

    echo -e "${GREEN}✅ Instruction sent successfully!${NC}\n"
    echo -e "${BLUE}Message Details:${NC}"
    echo -e "  Message ID:  ${GREEN}${MESSAGE_ID}${NC}"
    echo -e "  Stream:      ${GREEN}${STREAM_NAME}${NC}"
    echo -e "  Status:      ${GREEN}Delivered to all musicians${NC}\n"

    echo -e "${BLUE}The ${INSTRUMENT} musician will receive this message${NC}"
    echo -e "and other musicians will ignore it (filtered by instrument field).\n"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
fi
