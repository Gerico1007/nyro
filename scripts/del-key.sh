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

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <key>"
    exit 1
fi

KEY="$1"

# Use Redis CLI with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Deleting key '$KEY'..."
    redis-cli --tls -u "$REDIS_URL" DEL "$KEY"
else
    echo "Deleting key '$KEY'..."
    redis-cli -u "$REDIS_URL" DEL "$KEY"
fi
