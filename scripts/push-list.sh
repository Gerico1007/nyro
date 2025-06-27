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

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <list-name> <element>"
    exit 1
fi

LIST_NAME="$1"
ELEMENT="$2"

# Use Redis CLI with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Pushing to list '$LIST_NAME'..."
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning LPUSH "$LIST_NAME" "$ELEMENT"
else
    echo "Pushing to list '$LIST_NAME'..."
    redis-cli -u "$REDIS_URL" --no-auth-warning LPUSH "$LIST_NAME" "$ELEMENT"
fi
