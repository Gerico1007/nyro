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

# Parse REDIS_URL to extract connection details
# Expected format: rediss://default:password@host:port
if [[ "$REDIS_URL" =~ rediss?://([^:]+):([^@]+)@([^:]+):([0-9]+) ]]; then
    REDIS_USER="${BASH_REMATCH[1]}"
    REDIS_PASS="${BASH_REMATCH[2]}"
    REDIS_HOST="${BASH_REMATCH[3]}"
    REDIS_PORT="${BASH_REMATCH[4]}"
    echo "Connecting to Redis at $REDIS_HOST:$REDIS_PORT as $REDIS_USER"
else
    echo "Error: Invalid REDIS_URL format. Expected: redis[s]://user:pass@host:port"
    exit 1
fi

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" --no-auth-warning XRANGE "$STREAM_KEY" - + COUNT "$COUNT"
