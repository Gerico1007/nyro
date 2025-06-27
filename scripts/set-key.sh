#!/bin/bash

# Source environment variables
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="/workspace/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Source env file
set -a
source "$ENV_FILE"
set +a

if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <key> <value>"
    exit 1
fi

KEY="$1"
VALUE="$2"

# Use Redis CLI with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Setting key '$KEY'..."
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning SET "$KEY" "$VALUE"
else
    echo "Setting key '$KEY'..."
    redis-cli -u "$REDIS_URL" --no-auth-warning SET "$KEY" "$VALUE"
fi
