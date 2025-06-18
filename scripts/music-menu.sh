#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../.env"

echo "🎵 Nyro Music Notation System"
echo "----------------------------"
echo "1) Add new notation entry"
echo "2) Read notation entries"
echo "3) Extract parts from ABC"
echo "4) List all notation streams"
echo "5) Search notation by part"
echo "q) Quit"
echo

add_notation() {
    local stream_name="notation:stream"
    read -p "Enter part ID (e.g., violin1, piano_right): " part_id
    read -p "Enter format (abc/musicxml) [abc]: " format
    format=${format:-abc}
    
    echo "Enter notation content (press Ctrl+D when done):"
    content=$(cat)

    # Use arrays to properly handle arguments with spaces
    args=("${SCRIPT_DIR}/stream-add.sh" "$stream_name")
    args+=("part_id" "$part_id")
    args+=("format" "$format")
    args+=("content" "$content")
    args+=("timestamp" "$(date -u +%FT%TZ)")

    "${args[@]}"
}

read_notations() {
    local stream_name="notation:stream"
    read -p "How many entries to show? [10]: " count
    count=${count:-10}
    "${SCRIPT_DIR}/stream-read.sh" "$stream_name" "$count"
}

extract_parts() {
    echo "Feature coming soon: Will use music21 to extract parts"
    echo "For now, please enter parts manually using option 1"
}

list_streams() {
    echo "Listing all notation-related streams:"
    "${SCRIPT_DIR}/scan-garden.sh" "notation:*"
}

search_by_part() {
    read -p "Enter part ID to search for: " part_id
    "${SCRIPT_DIR}/stream-read.sh" "notation:stream" 100 | grep -A 3 "part_id.*$part_id"
}

while true; do
    read -p "Choose an option: " choice
    case $choice in
        1)
            add_notation
            ;;
        2)
            read_notations
            ;;
        3)
            extract_parts
            ;;
        4)
            list_streams
            ;;
        5)
            search_by_part
            ;;
        q|Q)
            echo "Goodbye! 🎵"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    echo
done
