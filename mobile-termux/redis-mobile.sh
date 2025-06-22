#!/bin/bash

# Nyro Redis Mobile - Main Menu Script
# Mobile-friendly version for Termux with location features

# Source environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    echo "Please run ./install.sh first or create .env file manually"
    exit 1
fi

# Check required environment variables
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo "❌ Error: KV_REST_API_URL and KV_REST_API_TOKEN not set in .env file"
    echo "Please edit .env file with your Upstash credentials"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is not installed"
    echo "Please run: pkg install curl"
    exit 1
fi

# Function to make REST API calls
redis_rest_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "${KV_REST_API_URL}${endpoint}" \
            -H "Authorization: Bearer $KV_REST_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${KV_REST_API_URL}${endpoint}" \
            -H "Authorization: Bearer $KV_REST_API_TOKEN"
    fi
}

# Function to write diary entry (Upstash expects flat array)
write_diary() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    echo "📝 Writing in diary: $diary_name"
    echo ""
    read -p "Enter what happened: " event
    read -p "Enter mood (optional, press enter to skip): " mood
    read -p "Enter location (optional, press enter to skip): " location
    read -p "Enter any extra details (optional, press enter to skip): " details
    # Build the stream entry as a flat array
    local stream_data="[\"event\",\"$event\""
    if [ -n "$mood" ]; then
        stream_data=",$stream_data,\"mood\",\"$mood\""
    fi
    if [ -n "$location" ]; then
        stream_data="$stream_data,\"location\",\"$location\""
    fi
    if [ -n "$details" ]; then
        stream_data="$stream_data,\"details\",\"$details\""
    fi
    stream_data="$stream_data]"
    local result=$(redis_rest_call "POST" "/xadd/$diary_name" "$stream_data")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error adding entry: $result"
    else
        echo "✅ Entry added successfully!"
        echo "📅 Stream ID: $result"
    fi
}

# Function to read diary entries (handle array format)
read_diary() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    local count="${2:-10}"
    echo "📖 Reading diary: $diary_name (last $count entries)"
    echo ""
    local result=$(redis_rest_call "GET" "/xrange/$diary_name/-/+?count=$count")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error reading diary: $result"
    else
        echo "$result" | jq -r '
          .[] | "📅 \(.[0])" ,
          (.[1] | to_entries | map("  \(.value)") | join("\n")) , ""
        '
    fi
}

# Function to show entries by location (handle array format)
show_by_location() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    echo "🗺️  Showing entries by location"
    echo ""
    local result=$(redis_rest_call "GET" "/xrange/$diary_name/-/+?count=100")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error reading diary: $result"
        return
    fi
    # Extract unique locations from array format
    local locations=$(echo "$result" | jq -r '.[] | .[1] as $arr | [range(0; length/2) | select($arr[2*.] == "location") | $arr[2*.+1]] | .[]' | sort | uniq)
    if [ -z "$locations" ]; then
        echo "📭 No entries with location found"
        return
    fi
    echo "📍 Available locations:"
    local i=1
    local location_array=()
    while IFS= read -r loc; do
        if [ -n "$loc" ]; then
            echo "  $i) $loc"
            location_array+=("$loc")
            ((i++))
        fi
    done <<< "$locations"
    echo ""
    read -p "Select location (1-$((i-1))): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
        local selected_location="${location_array[$((choice-1))]}"
        echo ""
        echo "📍 Entries from: $selected_location"
        echo ""
        echo "$result" | jq -r --arg loc "$selected_location" '
          .[] | select(.[1] as $arr | [range(0; length/2) | select($arr[2*.] == "location" and $arr[2*.+1] == $loc)]) |
          "📅 \(.[0])" ,
          (.[1] | to_entries | map("  \(.value)") | join("\n")) , ""
        '
    else
        echo "❌ Invalid selection"
    fi
}

# Function to set a key
set_key() {
    read -p "Enter key: " key
    read -p "Enter value: " value
    local result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$value\"}")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error setting key: $result"
    else
        echo "✅ Key set successfully!"
    fi
}

# Function to get a key (parse value)
get_key() {
    read -p "Enter key to get: " key
    local result=$(redis_rest_call "GET" "/get/$key")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error getting key: $result"
    else
        # Try to extract value
        value=$(echo "$result" | jq -r '.result.value // .result // .value // .')
        echo "📦 Value: $value"
    fi
}

# Function to delete a key
delete_key() {
    read -p "Enter key to delete: " key
    local result=$(redis_rest_call "DELETE" "/del/$key")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error deleting key: $result"
    else
        echo "✅ Key deleted successfully!"
    fi
}

# Function to list keys (fallback to raw if jq fails)
list_keys() {
    read -p "Enter pattern (default *): " pattern
    pattern="${pattern:-*}"
    local result=$(redis_rest_call "GET" "/scan/0/match/$pattern/count/100")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error listing keys: $result"
    else
        if ! echo "$result" | jq -r '.[1][]?' 2>/dev/null; then
            echo "$result"
        fi
    fi
}

# Main menu
while true; do
    echo ""
    echo "🌱 Nyro Redis Mobile Menu"
    echo "------------------------"
    echo "1) Write in garden diary (with location!)"
    echo "2) Read garden diary"
    echo "3) Show entries by location"
    echo "4) Set a key"
    echo "5) Get a key"
    echo "6) Delete a key"
    echo "7) List all keys"
    echo "q) Quit"
    echo ""
    read -p "Choose an option: " choice
    case $choice in
        1)
            write_diary
            ;;
        2)
            read_diary
            ;;
        3)
            show_by_location
            ;;
        4)
            set_key
            ;;
        5)
            get_key
            ;;
        6)
            delete_key
            ;;
        7)
            list_keys
            ;;
        q|Q)
            echo "👋 Goodbye! Happy gardening! 🌱"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac
done 