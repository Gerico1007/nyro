#!/bin/bash

# Source environment variables
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Source env file
set -a
source <(cat "$ENV_FILE" | tr -d '\r')
set +a

if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

# Check if list name is provided
if [ -z "$1" ]; then
    echo "Error: List name is required"
    echo "Usage: $0 <list-name> [start] [stop]"
    exit 1
fi

LIST_NAME="$1"
START="${2:-0}"
STOP="${3:-10}"

# Use Redis CLI with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Reading list '$LIST_NAME'..."
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning LRANGE "$LIST_NAME" "$START" "$STOP"
else
    echo "Reading list '$LIST_NAME'..."
    redis-cli -u "$REDIS_URL" --no-auth-warning LRANGE "$LIST_NAME" "$START" "$STOP"
fi
