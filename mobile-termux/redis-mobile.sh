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
    
    # Dynamically detect all available profiles from .env file
    if [ -f ".env" ]; then
        for var in $(grep '^PROFILE_.*_URL=' .env | cut -d= -f1); do
            profile_name=$(echo "$var" | sed 's/^PROFILE_//' | sed 's/_URL$//' | tr '[:upper:]' '[:lower:]')
            echo "• $profile_name"
        done
    fi
    
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

# Function to scan keys by pattern
scan_keys_by_pattern() {
    local pattern="$1"
    local cursor="0"
    local all_keys=()
    
    echo "🔍 Scanning for keys matching: $pattern"
    
    # Use Redis SCAN command to find keys (using existing endpoint format)
    while true; do
        local cmd_array="[\"SCAN\", \"$cursor\", \"MATCH\", \"$pattern\", \"COUNT\", \"100\"]"
        local result=$(redis_rest_call "POST" "" "$cmd_array")
        
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error scanning keys: $result"
            return 1
        fi
        
        # Parse cursor and keys from result
        cursor=$(echo "$result" | jq -r '.result[0]')
        local keys_batch=$(echo "$result" | jq -r '.result[1][]?' 2>/dev/null)
        
        if [ -n "$keys_batch" ]; then
            while IFS= read -r key; do
                if [ -n "$key" ]; then
                    all_keys+=("$key")
                fi
            done <<< "$keys_batch"
        fi
        
        # Break if cursor is 0 (scan complete)
        if [ "$cursor" = "0" ]; then
            break
        fi
    done
    
    # Return all found keys
    printf '%s\n' "${all_keys[@]}"
}

# Function for interactive key selection
select_keys_interactive() {
    local keys=("$@")
    local selected_keys=()
    local selections=()
    
    if [ ${#keys[@]} -eq 0 ]; then
        echo "❌ No keys to select from."
        return 1
    fi
    
    echo ""
    echo "📋 Found ${#keys[@]} keys. Select keys for batch operations:"
    echo "═══════════════════════════════════════════════════"
    
    # Initialize selections array
    for i in "${!keys[@]}"; do
        selections[i]=false
    done
    
    while true; do
        echo ""
        # Display keys with selection status
        for i in "${!keys[@]}"; do
            local marker="○"
            if [ "${selections[i]}" = "true" ]; then
                marker="●"
            fi
            printf "%2d) %s %s\n" $((i+1)) "$marker" "${keys[i]}"
        done
        
        echo ""
        echo "Commands:"
        echo "• Enter numbers (space-separated) to toggle: 1 3 5"
        echo "• 'all' to select all, 'none' to clear selection"
        echo "• 'done' to confirm selection, 'quit' to cancel"
        echo ""
        echo -n "Selection: "
        read input
        
        case "$input" in
            "done")
                # Collect selected keys
                for i in "${!keys[@]}"; do
                    if [ "${selections[i]}" = "true" ]; then
                        selected_keys+=("${keys[i]}")
                    fi
                done
                
                if [ ${#selected_keys[@]} -eq 0 ]; then
                    echo "⚠️ No keys selected."
                    return 1
                fi
                
                echo "✅ Selected ${#selected_keys[@]} keys."
                printf '%s\n' "${selected_keys[@]}"
                return 0
                ;;
            "quit")
                echo "❌ Selection cancelled."
                return 1
                ;;
            "all")
                for i in "${!keys[@]}"; do
                    selections[i]=true
                done
                echo "✅ All keys selected."
                ;;
            "none")
                for i in "${!keys[@]}"; do
                    selections[i]=false
                done
                echo "✅ All selections cleared."
                ;;
            *)
                # Parse number input
                for num in $input; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#keys[@]} ]; then
                        local idx=$((num-1))
                        if [ "${selections[idx]}" = "true" ]; then
                            selections[idx]=false
                            echo "○ Deselected: ${keys[idx]}"
                        else
                            selections[idx]=true
                            echo "● Selected: ${keys[idx]}"
                        fi
                    fi
                done
                ;;
        esac
    done
}

# Function to perform batch operations on selected keys
batch_key_operations() {
    local keys=("$@")
    
    if [ ${#keys[@]} -eq 0 ]; then
        echo "❌ No keys provided for batch operations."
        return 1
    fi
    
    echo ""
    echo "🛠️ Batch Operations for ${#keys[@]} keys"
    echo "═══════════════════════════════════════"
    echo "1) Get all values"
    echo "2) Delete all keys (with confirmation)"
    echo "3) Export to file"
    echo "4) Export to clipboard"
    echo "5) Back to main menu"
    echo ""
    echo -n "Choose operation: "
    read operation
    
    case $operation in
        1)
            batch_get_values "${keys[@]}"
            ;;
        2)
            batch_delete_keys "${keys[@]}"
            ;;
        3)
            export_keys_to_file "${keys[@]}"
            ;;
        4)
            export_keys_to_clipboard "${keys[@]}"
            ;;
        5)
            return 0
            ;;
        *)
            echo "❌ Invalid operation selected."
            ;;
    esac
}

# Function to get values for multiple keys
batch_get_values() {
    local keys=("$@")
    
    echo ""
    echo "📦 Getting values for ${#keys[@]} keys..."
    echo "═══════════════════════════════════════════"
    
    for key in "${keys[@]}"; do
        echo ""
        echo "🔑 Key: $key"
        echo "───────────────────────────────────────────"
        local result=$(redis_rest_call "POST" "/get/$key")
        
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            # Parse the value from the result
            local value=$(echo "$result" | jq -r '.result // "null"')
            if [ "$value" = "null" ]; then
                echo "⚠️ Key not found or has no value"
            else
                # Try to parse as JSON first, fallback to plain text
                if echo "$value" | jq . >/dev/null 2>&1; then
                    echo "$value" | jq .
                else
                    echo "$value"
                fi
            fi
        fi
    done
    
    echo ""
    echo "✅ Batch get operation completed."
}

# Function to delete multiple keys
batch_delete_keys() {
    local keys=("$@")
    
    echo ""
    echo "⚠️ WARNING: This will permanently delete ${#keys[@]} keys!"
    echo "Keys to delete:"
    for key in "${keys[@]}"; do
        echo "  • $key"
    done
    echo ""
    echo -n "Type 'DELETE' to confirm: "
    read confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo "❌ Deletion cancelled."
        return 1
    fi
    
    echo ""
    echo "🗑️ Deleting ${#keys[@]} keys..."
    local deleted_count=0
    
    for key in "${keys[@]}"; do
        local result=$(redis_rest_call "POST" "/" "{\"command\":[\"DEL\", \"$key\"]}")
        
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Failed to delete $key: $result"
        else
            echo "✅ Deleted: $key"
            ((deleted_count++))
        fi
    done
    
    echo ""
    echo "✅ Batch deletion completed: $deleted_count/${#keys[@]} keys deleted."
}

# Function to export keys to file
export_keys_to_file() {
    local keys=("$@")
    
    # Create export directory
    local export_dir="$HOME/nyro-exports"
    mkdir -p "$export_dir"
    
    # Generate filename with timestamp and profile
    local timestamp=$(date +"%y%m%d_%H%M%S")
    local filename="${timestamp}_${CURRENT_PROFILE}_keys.md"
    local filepath="$export_dir/$filename"
    
    echo ""
    echo "📄 Exporting ${#keys[@]} keys to file..."
    
    # Generate markdown content
    {
        echo "# Nyro Redis Key Export"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Profile: $CURRENT_PROFILE"
        echo "URL: $CURRENT_URL"
        echo "Keys exported: ${#keys[@]}"
        echo ""
        
        for key in "${keys[@]}"; do
            echo "---"
            echo "## $key"
            echo ""
            
            local result=$(redis_rest_call "POST" "/get/$key")
            
            if [[ "$result" == *"error"* ]]; then
                echo "❌ Error: $result"
            else
                local value=$(echo "$result" | jq -r '.result // "null"')
                if [ "$value" = "null" ]; then
                    echo "⚠️ Key not found or has no value"
                else
                    echo "\`\`\`"
                    if echo "$value" | jq . >/dev/null 2>&1; then
                        echo "$value" | jq .
                    else
                        echo "$value"
                    fi
                    echo "\`\`\`"
                fi
            fi
            echo ""
        done
    } > "$filepath"
    
    echo "✅ Export completed!"
    echo "📁 File saved: $filepath"
}

# Function to export keys to clipboard
export_keys_to_clipboard() {
    local keys=("$@")
    
    echo ""
    echo "📋 Exporting ${#keys[@]} keys to clipboard..."
    
    # Check if termux-clipboard-set is available
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        echo "⚠️ termux-clipboard-set not available. Showing content instead:"
        echo ""
    fi
    
    # Generate content
    local content=""
    content+="# Nyro Redis Key Export\n"
    content+="Generated: $(date '+%Y-%m-%d %H:%M:%S')\n"
    content+="Profile: $CURRENT_PROFILE\n"
    content+="Keys exported: ${#keys[@]}\n\n"
    
    for key in "${keys[@]}"; do
        content+="---\n"
        content+="## $key\n\n"
        
        local result=$(redis_rest_call "POST" "/get/$key")
        
        if [[ "$result" == *"error"* ]]; then
            content+="❌ Error: $result\n"
        else
            local value=$(echo "$result" | jq -r '.result // "null"')
            if [ "$value" = "null" ]; then
                content+="⚠️ Key not found or has no value\n"
            else
                content+="\`\`\`\n"
                if echo "$value" | jq . >/dev/null 2>&1; then
                    content+=$(echo "$value" | jq .)
                    content+="\n"
                else
                    content+="$value\n"
                fi
                content+="\`\`\`\n"
            fi
        fi
        content+="\n"
    done
    
    # Copy to clipboard if available, otherwise display
    if command -v termux-clipboard-set >/dev/null 2>&1; then
        echo -e "$content" | termux-clipboard-set
        echo "✅ Content copied to clipboard!"
    else
        echo "Content to copy:"
        echo "=================="
        echo -e "$content"
    fi
}

# Function for interactive key scanner main flow
scan_and_select_keys() {
    echo ""
    echo "🔍 Interactive Key Scanner & Selector"
    echo "═══════════════════════════════════════"
    echo "Current Profile: $CURRENT_PROFILE"
    echo "Database URL: $CURRENT_URL"
    echo ""
    echo -n "Enter key scan pattern (use * for wildcards): "
    read pattern
    
    # Sanitize pattern
    if [ -z "$pattern" ]; then
        pattern="*"
        echo "📌 Using default pattern: *"
    fi
    
    # Scan for keys
    local keys_output
    keys_output=$(scan_keys_by_pattern "$pattern")
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to scan keys."
        return 1
    fi
    
    # Convert output to array
    local keys=()
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            keys+=("$line")
        fi
    done <<< "$keys_output"
    
    if [ ${#keys[@]} -eq 0 ]; then
        echo "❌ No keys found matching pattern: $pattern"
        return 1
    fi
    
    echo "✅ Found ${#keys[@]} keys matching pattern: $pattern"
    
    # Interactive selection
    local selected_keys_output
    selected_keys_output=$(select_keys_interactive "${keys[@]}")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Convert selected keys to array
    local selected_keys=()
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            selected_keys+=("$line")
        fi
    done <<< "$selected_keys_output"
    
    # Perform batch operations
    batch_key_operations "${selected_keys[@]}"
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
    echo "9) Scan & Select Keys (Interactive)"
    echo ""
    echo "Profile Management:"
    echo "10) Switch database profile"
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
            scan_and_select_keys
            ;;
        10)
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
