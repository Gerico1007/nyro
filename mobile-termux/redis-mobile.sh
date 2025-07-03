#!/bin/bash

# Nyro Redis Mobile - Enhanced Main Menu Script
# Multi-database support with massive data handling

# Initialize global variables
CURRENT_PROFILE="default"
CURRENT_URL=""
CURRENT_TOKEN=""

# Source environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    echo "Please run ./install.sh first or create .env file manually"
    exit 1
fi

# Function to load profile credentials
load_profile() {
    local profile="$1"
    
    if [ "$profile" = "default" ] || [ -z "$profile" ]; then
        CURRENT_URL="$KV_REST_API_URL"
        CURRENT_TOKEN="$KV_REST_API_TOKEN"
        CURRENT_PROFILE="default"
    else
        # Load profile-specific credentials
        local url_var="PROFILE_${profile^^}_URL"
        local token_var="PROFILE_${profile^^}_TOKEN"
        
        CURRENT_URL="${!url_var}"
        CURRENT_TOKEN="${!token_var}"
        CURRENT_PROFILE="$profile"
    fi
    
    # Validate credentials
    if [ -z "$CURRENT_URL" ] || [ -z "$CURRENT_TOKEN" ]; then
        echo "❌ Error: Profile '$profile' not configured or missing credentials"
        return 1
    fi
    
    return 0
}

# Function to create temp directory
ensure_temp_dir() {
    local temp_dir="${TEMP_DIR:-/tmp/nyro-temp}"
    if [ ! -d "$temp_dir" ]; then
        mkdir -p "$temp_dir"
    fi
    echo "$temp_dir"
}

# Function to check if input is too large for direct processing
check_input_size() {
    local input="$1"
    local max_size="${MAX_DIRECT_INPUT_SIZE:-1024}"
    local input_size=$(echo -n "$input" | wc -c)
    local max_bytes=$((max_size * 1024))
    
    if [ "$input_size" -gt "$max_bytes" ]; then
        return 1
    fi
    return 0
}

# Initialize with active profile or default
if [ -n "$ACTIVE_PROFILE" ]; then
    load_profile "$ACTIVE_PROFILE"
else
    load_profile "default"
fi

# Final validation
if [ -z "$CURRENT_URL" ] || [ -z "$CURRENT_TOKEN" ]; then
    echo "❌ Error: No valid profile configured"
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
        curl -s -X "$method" "${CURRENT_URL}${endpoint}" \
            -H "Authorization: Bearer $CURRENT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${CURRENT_URL}${endpoint}" \
            -H "Authorization: Bearer $CURRENT_TOKEN"
    fi
}

# Function to write diary entry (Upstash REST API format)
write_diary() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    echo "📝 Writing in diary: $diary_name"
    echo ""
    read -p "Enter what happened: " event
    read -p "Enter mood (optional, press enter to skip): " mood
    read -p "Enter location (optional, press enter to skip): " location
    read -p "Enter any extra details (optional, press enter to skip): " details

    # Build command array for XADD: ["XADD", "stream", "*", "field1", "value1", ...]
    local fields_array='["XADD", "'$diary_name'", "*", "event", "'"$event"'"'
    [ -n "$mood" ] && fields_array+=', "mood", "'"$mood"'"'
    [ -n "$location" ] && fields_array+=', "location", "'"$location"'"'
    [ -n "$details" ] && fields_array+=', "details", "'"$details"'"'
    fields_array+=']'

    local result=$(redis_rest_call "POST" "" "$fields_array")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error adding entry: $result"
    else
        echo "✅ Entry added successfully!"
        echo "📅 Stream ID: $(echo "$result" | jq -r '.result')"
    fi
}

# Function to read diary entries (handle array format)
read_diary() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    local count="${2:-10}"
    echo "📖 Reading diary: $diary_name (last $count entries)"
    echo ""
    # Use XRANGE command in full format
    local cmd_array='["XRANGE", "'$diary_name'", "-", "+", "COUNT", "'$count'"]'
    local result=$(redis_rest_call "POST" "" "$cmd_array")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error reading diary: $result"
    else
        echo "$result" | jq -r '.result[] | "📅 \(.[0])\n\(.[1] | to_entries | map("  \(.key): \(.value)") | join("\n"))\n"' 2>/dev/null || echo "$result"
    fi
}

# Function to show entries by location (handle array format)
show_by_location() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    echo "🗺️  Showing entries by location"
    echo ""
    local cmd_array='["XRANGE", "'$diary_name'", "-", "+", "COUNT", "100"]'
    local result=$(redis_rest_call "POST" "" "$cmd_array")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error reading diary: $result"
        return
    fi
    # Extract unique locations from array format
    local locations=$(echo "$result" | jq -r '.result[] | .[1] as $arr | [range(0; length/2) | select($arr[2*.] == "location") | $arr[2*.+1]] | .[]' | sort | uniq)
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
          .result[] | select(.[1] as $arr | [range(0; length/2) | select($arr[2*.] == "location" and $arr[2*.+1] == $loc)]) |
          "📅 \(.[0])\n\(.[1] | to_entries | map("  \(.key): \(.value)") | join("\n"))\n"
        '
    else
        echo "❌ Invalid selection"
    fi
}

# Function to set a key
set_key() {
    read -p "Enter key: " key
    echo "1) Enter value directly"
    echo "2) Enter massive data (multi-line)"
    echo "3) Load from file"
    echo -n "Choose input method: "
    read method
    
    case $method in
        1)
            read -p "Enter value: " value
            local result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$value\"}")
            if [[ "$result" == *"error"* ]]; then
                echo "❌ Error setting key: $result"
            else
                echo "✅ Key set successfully!"
            fi
            ;;
        2)
            echo "📥 Enter massive data (press Ctrl+D when finished):"
            massive_data=$(cat)
            if check_input_size "$massive_data"; then
                local result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$massive_data\"}")
                if [[ "$result" == *"error"* ]]; then
                    echo "❌ Error setting key: $result"
                else
                    echo "✅ Key set successfully!"
                fi
            else
                echo "📦 Data too large for direct input, processing in chunks..."
                ./redis-rest.sh set-massive "$key" <<< "$massive_data"
            fi
            ;;
        3)
            read -p "Enter file path: " file_path
            if [ -f "$file_path" ]; then
                ./redis-rest.sh set-file "$key" "$file_path"
            else
                echo "❌ File not found: $file_path"
            fi
            ;;
        *)
            echo "❌ Invalid method selected"
            ;;
    esac
}

# Function to get a key (parse value)
get_key() {
    read -p "Enter key to get: " key
    local result=$(redis_rest_call "GET" "/get/$key")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error getting key: $result"
    else
        # Extract the inner value if it's a stringified JSON
        value=$(echo "$result" | jq -r '.result' 2>/dev/null)
        if [[ "$value" =~ ^\{.*\}$ ]]; then
            # If value is a JSON object, extract .value
            value=$(echo "$value" | jq -r '.value' 2>/dev/null)
        fi
        # Fallback if value is empty
        if [ -z "$value" ] || [ "$value" = "null" ]; then
            value="$result"
        fi
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
    local cmd_array='["SCAN", "0", "MATCH", "'$pattern'", "COUNT", "100"]'
    local result=$(redis_rest_call "POST" "" "$cmd_array")
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error listing keys: $result"
    else
        echo "$result" | jq -r '.result[1][]?' 2>/dev/null || echo "$result"
    fi
}

# Function to switch profile
switch_profile() {
    echo "🔧 Profile Management"
    echo "=================="
    echo "Current Profile: $CURRENT_PROFILE"
    echo "Current URL: $CURRENT_URL"
    echo ""
    echo "Available profiles:"
    echo "• default"
    
    # Check for additional profiles
    for profile in dev prod test; do
        url_var="PROFILE_${profile^^}_URL"
        if [ -n "${!url_var}" ]; then
            echo "• $profile"
        fi
    done
    
    echo ""
    read -p "Enter profile name to switch to: " profile_name
    
    if load_profile "$profile_name"; then
        echo "✅ Switched to profile: $profile_name"
        echo "URL: $CURRENT_URL"
    else
        echo "❌ Failed to load profile: $profile_name"
    fi
}

# Function to add massive data to stream
write_massive_diary() {
    local diary_name="${1:-$DEFAULT_DIARY}"
    echo "📝 Writing massive data to diary: $diary_name"
    echo "Choose input method:"
    echo "1) Enter data directly (multi-line)"
    echo "2) Load from file"
    echo -n "Choose method: "
    read method
    
    case $method in
        1)
            echo "📥 Enter massive data (press Ctrl+D when finished):"
            massive_data=$(cat)
            if check_input_size "$massive_data"; then
                local result=$(redis_rest_call "POST" "/" "{\"command\":[\"XADD\", \"$diary_name\", \"*\", \"data\", \"$massive_data\"]}")
                if [[ "$result" == *"error"* ]]; then
                    echo "❌ Error adding entry: $result"
                else
                    echo "✅ Entry added successfully!"
                    echo "📅 Stream ID: $(echo "$result" | jq -r '.result')"
                fi
            else
                echo "📦 Data too large for direct input, processing in chunks..."
                ./redis-rest.sh xadd-massive "$diary_name" <<< "$massive_data"
            fi
            ;;
        2)
            read -p "Enter file path: " file_path
            if [ -f "$file_path" ]; then
                ./redis-rest.sh xadd-file "$diary_name" "$file_path"
            else
                echo "❌ File not found: $file_path"
            fi
            ;;
        *)
            echo "❌ Invalid method selected"
            ;;
    esac
}

# Main menu
while true; do
    echo ""
    echo "🌱 Nyro Redis Mobile Menu (Profile: $CURRENT_PROFILE)"
    echo "================================================"
    echo "Diary Operations:"
    echo "1) Write in garden diary (with location!)"
    echo "2) Read garden diary"
    echo "3) Show entries by location"
    echo "4) Write massive data to diary"
    echo ""
    echo "Key Operations:"
    echo "5) Set a key"
    echo "6) Get a key"
    echo "7) Delete a key"
    echo "8) List all keys"
    echo ""
    echo "Profile Management:"
    echo "9) Switch database profile"
    echo "0) Show profile info"
    echo ""
    echo "q) Quit"
    echo ""
    echo -n "Choose an option: "
    read choice
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
            write_massive_diary
            ;;
        5)
            set_key
            ;;
        6)
            get_key
            ;;
        7)
            delete_key
            ;;
        8)
            list_keys
            ;;
        9)
            switch_profile
            ;;
        0)
            echo "🔧 Current Profile Information:"
            echo "============================="
            echo "Profile Name: $CURRENT_PROFILE"
            echo "API URL: $CURRENT_URL"
            echo "Token: ${CURRENT_TOKEN:0:8}..."
            echo "Temp Dir: ${TEMP_DIR:-/tmp/nyro-temp}"
            echo "Max Direct Input: ${MAX_DIRECT_INPUT_SIZE:-1024}KB"
            echo "Max File Size: ${MAX_FILE_SIZE:-100}MB"
            echo "Chunk Size: ${CHUNK_SIZE:-512}KB"
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
