#!/bin/bash

# Source environment variables
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="/workspace/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

# Get pattern or default to all keys
PATTERN="${1:-*}"

# Use Redis CLI with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Scanning keys with pattern '$PATTERN'..."
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning --scan --pattern "$PATTERN"
else
    echo "Scanning keys with pattern '$PATTERN'..."
    redis-cli -u "$REDIS_URL" --no-auth-warning --scan --pattern "$PATTERN"
fi
