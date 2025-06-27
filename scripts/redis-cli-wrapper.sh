#!/bin/bash

# Docker-based Redis CLI wrapper
# This script runs redis-cli inside a Docker container instead of requiring local installation

# Source environment variables if .env file exists
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Function to extract components from REDIS_URL
extract_from_url() {
    local url="$1"
    if [[ "$url" =~ rediss?://default:([^@]+)@([^:]+):([0-9]+) ]]; then
        TOKEN="${BASH_REMATCH[1]}"
        HOST="${BASH_REMATCH[2]}"
        PORT="${BASH_REMATCH[3]}"
        return 0
    else
        return 1
    fi
}

# Check for configuration - support both REDIS_URL and separate variables
if [ -n "$REDIS_URL" ]; then
    # Use REDIS_URL if provided
    if ! extract_from_url "$REDIS_URL"; then
        echo "Error: Invalid REDIS_URL format. Expected: redis://default:[TOKEN]@[HOST]:[PORT]"
        exit 1
    fi
elif [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PORT" ] && [ -n "$REDIS_TOKEN" ]; then
    # Use separate variables if provided
    HOST="$REDIS_HOST"
    PORT="$REDIS_PORT"
    TOKEN="$REDIS_TOKEN"
else
    # No configuration found
    echo "Error: Redis configuration not found!"
    echo ""
    echo "Please set up your Redis connection in one of these ways:"
    echo ""
    echo "Option 1 - Single REDIS_URL in .env:"
    echo "REDIS_URL=redis://default:[YOUR_TOKEN]@[YOUR_HOST]:[PORT]"
    echo ""
    echo "Option 2 - Separate variables in .env:"
    echo "REDIS_HOST=[YOUR_HOST]"
    echo "REDIS_PORT=[YOUR_PORT]"
    echo "REDIS_TOKEN=[YOUR_TOKEN]"
    echo ""
    echo "Example for Upstash:"
    echo "REDIS_HOST=central-colt-14211.upstash.io"
    echo "REDIS_PORT=6379"
    echo "REDIS_TOKEN=your_kv_rest_api_token_here"
    exit 1
fi

# Check if first argument is --script or -s
if [ "$1" = "--script" ] || [ "$1" = "-s" ]; then
    SCRIPT_PATH="$2"
    shift 2  # Remove --script and script path from arguments
    
    if [ -z "$SCRIPT_PATH" ]; then
        echo "Error: No script path provided after --script"
        echo "Usage: $0 --script /path/to/script.sh [redis-cli-args...]"
        exit 1
    fi
    
    # Handle relative paths - check if script exists in current dir, then in scripts dir
    if [ ! -f "$SCRIPT_PATH" ]; then
        # Try to find it in the scripts directory
        SCRIPTS_DIR="$(dirname "$0")"
        if [ -f "$SCRIPTS_DIR/$SCRIPT_PATH" ]; then
            SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT_PATH"
        else
            echo "Error: Script file not found: $SCRIPT_PATH"
            echo "Tried:"
            echo "  - $SCRIPT_PATH"
            echo "  - $SCRIPTS_DIR/$SCRIPT_PATH"
            echo ""
            echo "Available scripts in $SCRIPTS_DIR:"
            ls -la "$SCRIPTS_DIR"/*.sh 2>/dev/null | grep -v "redis-cli-wrapper.sh" || echo "  No .sh files found"
            exit 1
        fi
    fi
    
    echo "Executing script inside Docker container..."
    echo "Script: $SCRIPT_PATH"
    echo "Host: $HOST"
    echo "Port: $PORT"
    echo "Token: ${TOKEN:0:8}..."
    echo ""
    
    # Execute script inside container with volume mount
    docker run -it --rm \
        -v "$(dirname "$0")/..:/workspace" \
        -w /workspace \
        redis:alpine \
        sh -c "
            # Install additional tools if needed
            apk add --no-cache bash curl jq
            
            # Set Redis connection environment variables
            export REDIS_HOST='$HOST'
            export REDIS_PORT='$PORT'
            export REDIS_TOKEN='$TOKEN'
            export REDIS_URL='redis://default:${TOKEN}@${HOST}:${PORT}'
            
            # Execute the script
            bash '$SCRIPT_PATH' $*
        "
else
    # Build and run Docker command for regular redis-cli usage
    echo "Connecting to Redis via Docker container..."
    echo "Host: $HOST"
    echo "Port: $PORT"
    echo "Token: ${TOKEN:0:8}..." # Show only first 8 characters for security
    echo ""
    
    docker run -it --rm redis:alpine redis-cli --tls -u "redis://default:${TOKEN}@${HOST}:${PORT}" "$@"
fi
