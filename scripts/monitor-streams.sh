#!/bin/bash

################################################################################
# Musician Monitor Portal - Stream Monitor Script
#
# Real-time monitoring of musician instruction streams
# Shows pending messages for each musician
#
# Usage: ./monitor-streams.sh [interval]
#        ./monitor-streams.sh 5  (refresh every 5 seconds)
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Load environment
if [ -f ".env" ]; then
    export $(cat .env | grep -v '#' | xargs)
elif [ -f "$HOME/.env" ]; then
    export $(cat "$HOME/.env" | grep -v '#' | xargs)
fi

# Configuration
REFRESH_INTERVAL="${1:-3}"
API_URL="${KV_REST_API_URL}"
API_TOKEN="${KV_REST_API_TOKEN}"

# Validate environment
if [ -z "$API_URL" ] || [ -z "$API_TOKEN" ]; then
    echo -e "${RED}❌ Error: Upstash credentials not found${NC}"
    exit 1
fi

################################################################################
# Helper Functions
################################################################################

redis_command() {
    local cmd="$1"
    curl -s -X POST \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${API_URL}" \
        -d "{\"command\": \"${cmd}\"}"
}

# Get pending messages for a consumer
get_pending_count() {
    local stream="$1"
    local group="monitor_group"
    local response=$(redis_command "XPENDING $stream $group")

    if echo "$response" | grep -q '"error"'; then
        echo "0"
    else
        echo "$response" | grep -o '[0-9]*' | head -1
    fi
}

# Get stream info
get_stream_info() {
    local stream="$1"
    local response=$(redis_command "XINFO STREAM $stream")

    if echo "$response" | grep -q '"error"'; then
        echo "Error"
    else
        echo "$response"
    fi
}

# Get last message from stream
get_last_message() {
    local stream="$1"
    redis_command "XREVRANGE $stream + COUNT 1"
}

# Format timestamp for display
format_time() {
    local iso_time="$1"
    if [ -n "$iso_time" ]; then
        echo "$iso_time" | sed 's/T/ /; s/Z//'
    else
        echo "N/A"
    fi
}

# Clear screen
clear_screen() {
    clear
}

################################################################################
# Display Functions
################################################################################

display_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}${BOLD}           MUSICIAN MONITOR PORTAL - REAL-TIME STREAM MONITOR${NC}${BLUE}           ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} Refresh Interval: ${GREEN}${REFRESH_INTERVAL}s${NC} | Last Updated: $(date '+%Y-%m-%d %H:%M:%S') ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

display_musician_status() {
    local musician="$1"
    local description="$2"
    local stream_key="musician:${musician}"

    # Get pending count
    pending=$(get_pending_count "$stream_key")

    # Determine status indicator
    if [ "$pending" -gt 0 ]; then
        status_indicator="${RED}●${NC}"
        status_text="${RED}PENDING${NC}"
    else
        status_indicator="${GREEN}●${NC}"
        status_text="${GREEN}IDLE${NC}"
    fi

    # Get stream length
    length_response=$(redis_command "XLEN $stream_key")
    if echo "$length_response" | grep -q '"error"'; then
        length="0"
    else
        length=$(echo "$length_response" | grep -o '[0-9]*' | head -1)
    fi

    # Display musician info
    printf "${BLUE}┌─────────────────────────────────────────────────────────────────────────────┐${NC}\n"
    printf "${BLUE}│${NC} ${BOLD}${musician^^}${NC} - ${description}\n"
    printf "${BLUE}├─────────────────────────────────────────────────────────────────────────────┤${NC}\n"

    printf "${BLUE}│${NC} Stream:          ${CYAN}${stream_key}${NC}\n"
    printf "${BLUE}│${NC} Total Messages:  ${GREEN}${length}${NC}\n"
    printf "${BLUE}│${NC} Pending:         ${status_indicator} ${status_text}${NC} (${YELLOW}${pending}${NC})\n"
    printf "${BLUE}│${NC}\n"

    # Get and display last message
    last_msg=$(get_last_message "$stream_key")
    if echo "$last_msg" | grep -q 'instruction'; then
        instruction=$(echo "$last_msg" | grep -o '"instruction":"[^"]*' | cut -d'"' -f4)
        timestamp=$(echo "$last_msg" | grep -o '"timestamp":"[^"]*' | cut -d'"' -f4)
        priority=$(echo "$last_msg" | grep -o '"priority":"[^"]*' | cut -d'"' -f4)
        msg_id=$(echo "$last_msg" | grep -o '\[[0-9]*-[0-9]*\]' | tr -d '[]')

        printf "${BLUE}│${NC} Last Instruction:\n"
        printf "${BLUE}│${NC}   ID:      ${MAGENTA}${msg_id}${NC}\n"
        printf "${BLUE}│${NC}   Text:    ${instruction}\n"
        printf "${BLUE}│${NC}   Time:    ${timestamp}\n"
        printf "${BLUE}│${NC}   Priority: ${YELLOW}${priority}${NC}\n"
    else
        printf "${BLUE}│${NC} No messages yet\n"
    fi

    printf "${BLUE}└─────────────────────────────────────────────────────────────────────────────┘${NC}\n"
    echo ""
}

display_commands() {
    echo -e "${BLUE}COMMANDS:${NC}"
    echo -e "  ${CYAN}send <musician> <instruction>${NC}  - Send instruction to musician"
    echo -e "  ${CYAN}clear${NC}                          - Clear screen"
    echo -e "  ${CYAN}refresh <seconds>${NC}              - Change refresh interval"
    echo -e "  ${CYAN}quit${NC}                           - Exit monitoring"
    echo ""
}

################################################################################
# Main Loop
################################################################################

main() {
    while true; do
        clear_screen
        display_header

        # Display each musician
        display_musician_status "guitar1" "Guitar 1 - Rhythm"
        display_musician_status "guitar2" "Guitar 2 - Lead"
        display_musician_status "saxophone" "Saxophone - Melody"
        display_musician_status "vocalist" "Vocalist - Lead Voice"

        display_commands

        # Wait for next refresh
        sleep "$REFRESH_INTERVAL"
    done
}

# Handle interrupt
trap 'echo -e "\n${YELLOW}Monitor stopped${NC}"; exit 0' INT

# Start monitoring
main
