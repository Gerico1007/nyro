#!/bin/bash

# Nyro Redis Mobile - REST API Wrapper
# Standalone script for direct Redis operations via REST API

# Source environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Check required environment variables
if [ -z "$KV_REST_API_URL" ] || [ -z "$KV_REST_API_TOKEN" ]; then
    echo "❌ Error: KV_REST_API_URL and KV_REST_API_TOKEN not set in .env file"
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

# Show help if no arguments
if [ $# -eq 0 ]; then
    echo "🌱 Nyro Redis Mobile - REST API Wrapper"
    echo "======================================"
    echo ""
    echo "Usage: $0 <command> [arguments...]"
    echo ""
    echo "Commands:"
    echo "  ping                    - Test connection"
    echo "  set <key> <value>       - Set a key-value pair"
    echo "  get <key>               - Get a value"
    echo "  del <key>               - Delete a key"
    echo "  keys <pattern>          - List keys matching pattern"
    echo "  xadd <stream> <data>    - Add to stream"
    echo "  xrange <stream> [count] - Read from stream"
    echo "  info                    - Show connection info"
    echo ""
    echo "Examples:"
    echo "  $0 ping"
    echo "  $0 set mykey 'my value'"
    echo "  $0 get mykey"
    echo "  $0 xadd garden.diary '{\"event\":\"saw a butterfly\"}'"
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
        echo "API URL: ${KV_REST_API_URL}"
        echo "Token: ${KV_REST_API_TOKEN:0:8}..."
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
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0' for help"
        exit 1
        ;;
esac 