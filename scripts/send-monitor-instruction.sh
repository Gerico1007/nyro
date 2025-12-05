#!/bin/bash

################################################################################
# Musician Monitor Portal - Send Instruction Script
#
# Sends instructions to Redis streams
# Instruments receive messages filtered by their instrument field
#
# Usage: ./send-monitor-instruction.sh <instrument> <action> <data> [options]
#        ./send-monitor-instruction.sh guitar_1 show_chords "C Am F G"
#        ./send-monitor-instruction.sh guitarist show_lyrics "hello world!" --stream song-2
#        ./send-monitor-instruction.sh vocalist show_lyrics "Verse 1" --stream song-1 --transpose 2
#
# Options:
#        --stream <stream-id>   Target stream (default-score, song-1, song-2, song-3)
#        --transpose <value>    Transposition semitones
#        --bar <number>         Bar/measure number
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
    echo -e "${YELLOW}Usage: $0 <instrument> <action> <data> [options]${NC}"
    echo ""
    echo -e "${BLUE}Arguments:${NC}"
    echo "  instrument:  guitar_1, guitar_2, saxophone_1, vocalist_1"
    echo "               (or aliases: guitar1, guitar2, saxophone, vocalist)"
    echo "  action:      show_chords, show_lyrics, highlight_section, etc."
    echo "  data:        The actual data (chords, lyrics, section name)"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  --song <num>       Target song stream (default, 1, 2, 3)"
    echo "  --transpose <val>  Transposition semitones"
    echo "  --bar <num>        Bar/measure number"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 vocalist show_lyrics 'hello world!'"
    echo "  $0 vocalist show_lyrics 'hello world!' --song 2"
    echo "  $0 guitar1 show_chords 'C Am F G' --song 1 --transpose 2"
    echo "  $0 saxophone highlight_section 'Solo' --song 3 --bar 16"
    exit 1
fi

INSTRUMENT="$1"
ACTION="$2"
DATA="$3"
SONG="default"
TRANSPOSE=""
BAR=""

# Parse optional flags
shift 3
while [[ $# -gt 0 ]]; do
    case "$1" in
        --song)
            SONG="$2"
            shift 2
            ;;
        --transpose)
            TRANSPOSE="$2"
            shift 2
            ;;
        --bar)
            BAR="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

################################################################################
# Normalize Instrument Names
################################################################################

case "$INSTRUMENT" in
    guitar_1|guitar_2|saxophone_1|vocalist_1)
        NORMALIZED_INSTRUMENT="$INSTRUMENT"
        ;;
    guitar1)
        NORMALIZED_INSTRUMENT="guitar_1"
        ;;
    guitar2)
        NORMALIZED_INSTRUMENT="guitar_2"
        ;;
    saxophone)
        NORMALIZED_INSTRUMENT="saxophone_1"
        ;;
    guitarist)
        NORMALIZED_INSTRUMENT="guitar_1"
        ;;
    vocalist|vocalist_0)
        NORMALIZED_INSTRUMENT="vocalist_1"
        ;;
    *)
        echo -e "${RED}❌ Invalid instrument: $INSTRUMENT${NC}"
        echo "Valid options: guitar_1, guitar_2, saxophone_1, vocalist_1"
        echo "             (or aliases: guitar1, guitar2, saxophone, vocalist)"
        exit 1
        ;;
esac

################################################################################
# Map Song to Stream Name
################################################################################

case "$SONG" in
    default|0)
        STREAM_NAME="gmusic:score"
        SONG_DISPLAY="Default Score"
        ;;
    1)
        STREAM_NAME="gmusic:song1"
        SONG_DISPLAY="Song 1"
        ;;
    2)
        STREAM_NAME="gmusic:song2"
        SONG_DISPLAY="Song 2"
        ;;
    3)
        STREAM_NAME="gmusic:song3"
        SONG_DISPLAY="Song 3"
        ;;
    *)
        echo -e "${RED}❌ Invalid song: $SONG${NC}"
        echo "Valid options: default, 1, 2, 3"
        exit 1
        ;;
esac

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Sending to Monitor Portal${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📤 Message Details:${NC}"
echo -e "  Song:        ${GREEN}${SONG_DISPLAY}${NC}"
echo -e "  Stream:      ${GREEN}${STREAM_NAME}${NC}"
echo -e "  Instrument:  ${GREEN}${NORMALIZED_INSTRUMENT}${NC}"
echo -e "  Action:      ${GREEN}${ACTION}${NC}"
echo -e "  Data:        ${GREEN}${DATA}${NC}"
[ -n "$TRANSPOSE" ] && echo -e "  Transpose:   ${GREEN}${TRANSPOSE}${NC}"
[ -n "$BAR" ] && echo -e "  Bar:         ${GREEN}${BAR}${NC}"
echo -e "  Timestamp:   ${GREEN}${TIMESTAMP}${NC}"

echo -e "\n${YELLOW}📡 Sending to Redis...${NC}"

# Build command with fields using normalized instrument
if [ -n "$TRANSPOSE" ] && [ -n "$BAR" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$NORMALIZED_INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "transpose" "$TRANSPOSE" \
        "bar" "$BAR" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
elif [ -n "$TRANSPOSE" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$NORMALIZED_INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "transpose" "$TRANSPOSE" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
elif [ -n "$BAR" ]; then
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$NORMALIZED_INSTRUMENT" \
        "action" "$ACTION" \
        "data" "$DATA" \
        "bar" "$BAR" \
        "timestamp" "$TIMESTAMP" | jq -R . | jq -s .)
else
    CMD_ARRAY=$(printf '%s\n' "XADD" "$STREAM_NAME" "*" \
        "instrument" "$NORMALIZED_INSTRUMENT" \
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
    echo -e "  Song:        ${GREEN}${SONG_DISPLAY}${NC}"
    echo -e "  Stream:      ${GREEN}${STREAM_NAME}${NC}"
    echo -e "  Status:      ${GREEN}Delivered to all musicians${NC}\n"

    echo -e "${BLUE}The ${NORMALIZED_INSTRUMENT} musician on ${SONG_DISPLAY} will receive this message${NC}"
    echo -e "and other musicians will ignore it (filtered by instrument field).\n"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
fi
