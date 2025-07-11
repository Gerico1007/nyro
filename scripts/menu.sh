#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "/workspace/.env" ]; then
    source "/workspace/.env"
fi

echo "Nyro Redis Utilities Menu"
echo "------------------------"
echo "1) Set a key"
echo "2) Get a key"
echo "3) Delete a key"
echo "4) Push to list"
echo "5) Read from list"
echo "6) Look around the garden (SCAN)"
echo "7) Write in garden diary (STREAM ADD)"
echo "8) Read garden diary (STREAM READ)"
echo "q) Quit"
echo

while true; do
    read -p "Choose an option: " choice
    case $choice in
        1)
            read -p "Enter key: " key
            read -p "Enter value: " value
            "${SCRIPT_DIR}/set-key.sh" "$key" "$value"
            ;;
        2)
            read -p "Enter key to get: " key
            "${SCRIPT_DIR}/get-key.sh" "$key"
            ;;
        3)
            read -p "Enter key to delete: " key
            "${SCRIPT_DIR}/del-key.sh" "$key"
            ;;
        4)
            read -p "Enter list name: " list
            read -p "Enter element: " element
            "${SCRIPT_DIR}/push-list.sh" "$list" "$element"
            ;;
        5)
            read -p "Enter list name: " list
            read -p "Enter start index (default 0): " start
            read -p "Enter stop index (default 10): " stop
            "${SCRIPT_DIR}/read-list.sh" "$list" "${start:-0}" "${stop:-10}"
            ;;
        6)
            read -p "Enter pattern to search (default *): " pattern
            "${SCRIPT_DIR}/scan-garden.sh" "${pattern:-*}"
            ;;
        7)
            read -p "Enter diary name (default garden.diary): " diary
            read -p "Enter what happened: " event
            read -p "Enter mood (optional, press enter to skip): " mood
            read -p "Enter any extra details (optional, press enter to skip): " details
            
            # Build argument list with proper quoting
            ARGS=("${SCRIPT_DIR}/stream-add.sh" "${diary:-garden.diary}")
            ARGS+=("event" "$event")
            if [ -n "$mood" ]; then
                ARGS+=("mood" "$mood")
            fi
            if [ -n "$details" ]; then
                ARGS+=("details" "$details")
            fi
            
            # Execute the command directly
            "${ARGS[@]}"
            ;;
        8)
            read -p "Enter diary name (default garden.diary): " diary
            read -p "How many entries to read? (default 10): " count
            "${SCRIPT_DIR}/stream-read.sh" "${diary:-garden.diary}" "${count:-10}"
            ;;
        q|Q)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    echo
done
