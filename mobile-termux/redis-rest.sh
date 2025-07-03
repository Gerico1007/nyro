#!/bin/bash

# Nyro Redis Mobile - Enhanced REST API Wrapper
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

# Function to handle massive data input
process_massive_data() {
    local operation="$1"
    local key="$2"
    local input="$3"
    local temp_dir=$(ensure_temp_dir)
    local temp_file="$temp_dir/massive_input_$$"
    
    echo "📦 Processing massive data input..."
    
    # Write input to temp file
    echo "$input" > "$temp_file"
    
    # Process in chunks
    local chunk_size="${CHUNK_SIZE:-512}"
    local chunk_size_bytes=$((chunk_size * 1024))
    local chunk_count=0
    
    while IFS= read -r -n "$chunk_size_bytes" chunk; do
        if [ -n "$chunk" ]; then
            chunk_count=$((chunk_count + 1))
            local chunk_key="${key}_chunk_${chunk_count}"
            
            echo "⏳ Processing chunk $chunk_count..."
            
            case "$operation" in
                "set")
                    result=$(redis_rest_call "POST" "/set/$chunk_key" "{\"value\":\"$chunk\"}")
                    if [[ "$result" == *"error"* ]]; then
                        echo "❌ Error processing chunk $chunk_count: $result"
                        rm -f "$temp_file"
                        return 1
                    fi
                    ;;
                "xadd")
                    result=$(redis_rest_call "POST" "/" "{\"command\":[\"XADD\", \"$key\", \"*\", \"chunk\", \"$chunk_count\", \"data\", \"$chunk\"]}")
                    if [[ "$result" == *"error"* ]]; then
                        echo "❌ Error processing chunk $chunk_count: $result"
                        rm -f "$temp_file"
                        return 1
                    fi
                    ;;
            esac
        fi
    done < "$temp_file"
    
    # Store metadata about chunks
    local metadata_key="${key}_metadata"
    metadata_result=$(redis_rest_call "POST" "/set/$metadata_key" "{\"value\":\"{\\\"chunks\\\":$chunk_count,\\\"operation\\\":\\\"$operation\\\"}\"}") 
    
    rm -f "$temp_file"
    echo "✅ Massive data processing complete: $chunk_count chunks processed"
    return 0
}

# Function to handle file input
process_file_input() {
    local operation="$1"
    local key="$2"
    local file_path="$3"
    
    if [ ! -f "$file_path" ]; then
        echo "❌ Error: File not found: $file_path"
        return 1
    fi
    
    # Check file size
    local max_size="${MAX_FILE_SIZE:-100}"
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
    local max_bytes=$((max_size * 1024 * 1024))
    
    if [ "$file_size" -gt "$max_bytes" ]; then
        echo "❌ Error: File too large (${file_size} bytes, max: ${max_bytes} bytes)"
        return 1
    fi
    
    echo "📁 Processing file: $file_path"
    local file_content=$(cat "$file_path")
    
    if check_input_size "$file_content"; then
        # Process directly
        case "$operation" in
            "set")
                result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$file_content\"}")
                ;;
            "xadd")
                result=$(redis_rest_call "POST" "/" "{\"command\":[\"XADD\", \"$key\", \"*\", \"file\", \"$file_path\", \"data\", \"$file_content\"]}")
                ;;
        esac
    else
        # Process as massive data
        process_massive_data "$operation" "$key" "$file_content"
        return $?
    fi
    
    if [[ "$result" == *"error"* ]]; then
        echo "❌ Error processing file: $result"
        return 1
    else
        echo "✅ File processed successfully!"
        return 0
    fi
}

# Show help if no arguments
if [ $# -eq 0 ]; then
    echo "🌱 Nyro Redis Mobile - Enhanced REST API Wrapper"
    echo "=============================================="
    echo ""
    echo "Current Profile: $CURRENT_PROFILE"
    echo "Current URL: $CURRENT_URL"
    echo ""
    echo "Usage: $0 <command> [arguments...]"
    echo ""
    echo "Basic Commands:"
    echo "  ping                    - Test connection"
    echo "  set <key> <value>       - Set a key-value pair"
    echo "  get <key>               - Get a value"
    echo "  del <key>               - Delete a key"
    echo "  keys <pattern>          - List keys matching pattern"
    echo "  xadd <stream> <data>    - Add to stream"
    echo "  xrange <stream> [count] - Read from stream"
    echo "  info                    - Show connection info"
    echo ""
    echo "Profile Management:"
    echo "  profile <name>          - Switch to profile"
    echo "  profile-list            - List available profiles"
    echo "  profile-info            - Show current profile info"
    echo ""
    echo "Massive Data Handling:"
    echo "  set-file <key> <file>   - Set key from file"
    echo "  xadd-file <stream> <file> - Add file to stream"
    echo "  set-massive <key>       - Set key from stdin (for large data)"
    echo "  xadd-massive <stream>   - Add stdin to stream (for large data)"
    echo ""
    echo "Examples:"
    echo "  $0 ping"
    echo "  $0 set mykey 'my value'"
    echo "  $0 profile dev"
    echo "  $0 set-file mykey /path/to/large/file.txt"
    echo "  echo 'massive data' | $0 set-massive mykey"
    echo ""
    exit 0
fi

# Parse command
case "$1" in
    ping)
        echo "🏓 Testing connection..."
        result=$(redis_rest_call "GET" "/ping")
        if [[ "$result" == *"PONG"* ]] || [[ "$result" == *"pong"* ]]; then
            echo "✅ Connection successful!"
        else
            echo "❌ Connection failed: $result"
        fi
        ;;
    
    set)
        if [ $# -lt 3 ]; then
            echo "❌ Usage: $0 set <key> <value>"
            exit 1
        fi
        key="$2"
        value="$3"
        echo "🔧 Setting key: $key"
        result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$value\"}")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            echo "✅ Key set successfully!"
        fi
        ;;
    
    get)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 get <key>"
            exit 1
        fi
        key="$2"
        echo "📦 Getting key: $key"
        result=$(redis_rest_call "GET" "/get/$key")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            # Clean JSON response parsing
            value=$(echo "$result" | jq -r '.result' 2>/dev/null)
            if [[ "$value" =~ ^\{.*\}$ ]]; then
                # If result is stringified JSON, parse it
                value=$(echo "$value" | jq -r '.value' 2>/dev/null)
            fi
            # Fallback to raw result if parsing fails
            if [ -z "$value" ] || [ "$value" = "null" ]; then
                value="$result"
            fi
            echo "📦 Value: $value"
        fi
        ;;
    
    del)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 del <key>"
            exit 1
        fi
        key="$2"
        echo "🗑️  Deleting key: $key"
        result=$(redis_rest_call "DELETE" "/del/$key")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            echo "✅ Key deleted successfully!"
        fi
        ;;
    
    keys)
        pattern="${2:-*}"
        echo "🔑 Listing keys matching: $pattern"
        # Use SCAN command in full format
        cmd_array='["SCAN", "0", "MATCH", "'$pattern'", "COUNT", "100"]'
        result=$(redis_rest_call "POST" "" "$cmd_array")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            echo "$result" | jq -r '.result[1][]?' 2>/dev/null || echo "$result"
        fi
        ;;
    
    xadd)
        if [ $# -lt 3 ]; then
            echo "❌ Usage: $0 xadd <stream> <field1> <value1> [field2] [value2] ..."
            echo "Example: $0 xadd garden.diary event 'saw butterfly' location 'garden'"
            exit 1
        fi
        stream="$2"
        shift 2
        
        # Build command array: ["XADD", "stream", "*", "field1", "value1", ...]
        cmd_array='["XADD", "'$stream'", "*"'
        while [ $# -gt 0 ]; do
            cmd_array="${cmd_array}, \"$1\""
            shift
        done
        cmd_array="${cmd_array}]"
        
        echo "📝 Adding to stream: $stream"
        result=$(redis_rest_call "POST" "" "$cmd_array")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            echo "✅ Added to stream! ID: $(echo "$result" | jq -r '.result')"
        fi
        ;;
    
    xrange)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 xrange <stream> [count]"
            exit 1
        fi
        stream="$2"
        count="${3:-10}"
        echo "📖 Reading from stream: $stream (last $count entries)"
        
        # Use full command format for XRANGE
        cmd_array='["XRANGE", "'$stream'", "-", "+", "COUNT", "'$count'"]'
        result=$(redis_rest_call "POST" "" "$cmd_array")
        if [[ "$result" == *"error"* ]]; then
            echo "❌ Error: $result"
        else
            echo "$result" | jq -r '.result[] | "📅 \(.[0])\n\(.[1] | to_entries | map("  \(.key): \(.value)") | join("\n"))\n"' 2>/dev/null || echo "$result"
        fi
        ;;
    
    info)
        echo "🌱 Nyro Redis Mobile - Connection Info"
        echo "===================================="
        echo "Profile: $CURRENT_PROFILE"
        echo "API URL: $CURRENT_URL"
        echo "Token: ${CURRENT_TOKEN:0:8}..."
        echo "Default Diary: ${DEFAULT_DIARY:-garden.diary}"
        echo ""
        echo "Testing connection..."
        result=$(redis_rest_call "GET" "/ping")
        if [[ "$result" == *"PONG"* ]] || [[ "$result" == *"pong"* ]]; then
            echo "✅ Connection: OK"
        else
            echo "❌ Connection: Failed"
        fi
        ;;
    
    profile)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 profile <name>"
            echo "Available profiles: default, dev, prod, test"
            exit 1
        fi
        profile_name="$2"
        if load_profile "$profile_name"; then
            echo "✅ Switched to profile: $profile_name"
            echo "URL: $CURRENT_URL"
        else
            echo "❌ Failed to load profile: $profile_name"
            exit 1
        fi
        ;;
    
    profile-list)
        echo "🔧 Available Profiles:"
        echo "==================="
        echo "• default (current: $([[ "$CURRENT_PROFILE" == "default" ]] && echo "✅" || echo "○"))"
        
        # Dynamically detect all available profiles from .env file
        if [ -f ".env" ]; then
            for var in $(grep '^PROFILE_.*_URL=' .env | cut -d= -f1); do
                profile_name=$(echo "$var" | sed 's/^PROFILE_//' | sed 's/_URL$//' | tr '[:upper:]' '[:lower:]')
                echo "• $profile_name (current: $([[ "$CURRENT_PROFILE" == "$profile_name" ]] && echo "✅" || echo "○"))"
            done
        fi
        ;;
    
    profile-info)
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
    
    set-file)
        if [ $# -lt 3 ]; then
            echo "❌ Usage: $0 set-file <key> <file>"
            exit 1
        fi
        key="$2"
        file="$3"
        process_file_input "set" "$key" "$file"
        ;;
    
    xadd-file)
        if [ $# -lt 3 ]; then
            echo "❌ Usage: $0 xadd-file <stream> <file>"
            exit 1
        fi
        stream="$2"
        file="$3"
        process_file_input "xadd" "$stream" "$file"
        ;;
    
    set-massive)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 set-massive <key>"
            echo "Data will be read from stdin"
            exit 1
        fi
        key="$2"
        echo "📥 Reading massive data from stdin..."
        echo "Press Ctrl+D when finished entering data"
        massive_data=$(cat)
        
        if check_input_size "$massive_data"; then
            echo "🔧 Setting key directly: $key"
            result=$(redis_rest_call "POST" "/set/$key" "{\"value\":\"$massive_data\"}")
            if [[ "$result" == *"error"* ]]; then
                echo "❌ Error: $result"
            else
                echo "✅ Key set successfully!"
            fi
        else
            echo "📦 Data too large for direct input, processing in chunks..."
            process_massive_data "set" "$key" "$massive_data"
        fi
        ;;
    
    xadd-massive)
        if [ $# -lt 2 ]; then
            echo "❌ Usage: $0 xadd-massive <stream>"
            echo "Data will be read from stdin"
            exit 1
        fi
        stream="$2"
        echo "📥 Reading massive data from stdin..."
        echo "Press Ctrl+D when finished entering data"
        massive_data=$(cat)
        
        if check_input_size "$massive_data"; then
            echo "📝 Adding to stream directly: $stream"
            result=$(redis_rest_call "POST" "/" "{\"command\":[\"XADD\", \"$stream\", \"*\", \"data\", \"$massive_data\"]}")
            if [[ "$result" == *"error"* ]]; then
                echo "❌ Error: $result"
            else
                echo "✅ Added to stream! ID: $(echo "$result" | jq -r '.result')"
            fi
        else
            echo "📦 Data too large for direct input, processing in chunks..."
            process_massive_data "xadd" "$stream" "$massive_data"
        fi
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0' for help"
        exit 1
        ;;
esac 