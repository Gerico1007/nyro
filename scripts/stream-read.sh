#!/bin/bash
set -e

# Source environment variables using proper shell syntax
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Source env file but clean up any Windows line endings
set -a
source <(cat "$ENV_FILE" | tr -d '\r')
set +a

# Check Redis URL
if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

# Check if redis-cli is installed
if ! command -v redis-cli &> /dev/null; then
    echo "Error: redis-cli is not installed. Please install Redis CLI tools first."
    exit 1
fi

# Check if stream key is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <stream-key> [count]"
    echo "Example: $0 garden.diary 10"
    exit 1
fi

STREAM_KEY="$1"
COUNT="${2:-10}"  # Default to 10 entries if not specified

# Use XRANGE to read from the stream
echo "Reading up to $COUNT entries from stream $STREAM_KEY"

# Use REDIS_URL directly with TLS support
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    echo "Connecting to Redis with TLS..."
    redis-cli --tls -u "$REDIS_URL" XRANGE "$STREAM_KEY" - + COUNT "$COUNT"
else
    echo "Connecting to Redis..."
    redis-cli -u "$REDIS_URL" XRANGE "$STREAM_KEY" - + COUNT "$COUNT"
fi
