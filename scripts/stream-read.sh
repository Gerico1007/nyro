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
# Handle different URL formats
REDIS_SCHEME=$(echo "$REDIS_URL" | sed -n 's,^\([a-z\-]*\)://.*,\1,p')
URI_BODY=$(echo "$REDIS_URL" | sed -n 's,^[a-z\-]*://,,p')

# Defaults
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_USER=""
REDIS_PASS=""

# Parse different URL formats
if [[ "$URI_BODY" =~ ^([^:@/]*):([^@]*)@([^:/]+):([0-9]+) ]]; then
    # username:password@host:port
    REDIS_USER="${BASH_REMATCH[1]}"
    REDIS_PASS="${BASH_REMATCH[2]}"
    REDIS_HOST="${BASH_REMATCH[3]}"
    REDIS_PORT="${BASH_REMATCH[4]}"
elif [[ "$URI_BODY" =~ ^:([^@]*)@([^:/]+):([0-9]+) ]]; then
    # :password@host:port
    REDIS_PASS="${BASH_REMATCH[1]}"
    REDIS_HOST="${BASH_REMATCH[2]}"
    REDIS_PORT="${BASH_REMATCH[3]}"
elif [[ "$URI_BODY" =~ ^([^@]+)@([^:/]+):([0-9]+) ]]; then
    # password@host:port
    REDIS_PASS="${BASH_REMATCH[1]}"
    REDIS_HOST="${BASH_REMATCH[2]}"
    REDIS_PORT="${BASH_REMATCH[3]}"
elif [[ "$URI_BODY" =~ ^([^:/]+):([0-9]+) ]]; then
    # host:port
    REDIS_HOST="${BASH_REMATCH[1]}"
    REDIS_PORT="${BASH_REMATCH[2]}"
fi

# Build CLI args
CLI_ARGS=()
if [ -n "$REDIS_HOST" ]; then
    CLI_ARGS+=(-h "$REDIS_HOST")
fi
if [ -n "$REDIS_PORT" ]; then
    CLI_ARGS+=(-p "$REDIS_PORT")
fi
if [ -n "$REDIS_PASS" ]; then
    CLI_ARGS+=(-a "$REDIS_PASS")
fi

echo "Connecting to Redis at $REDIS_HOST:$REDIS_PORT"
redis-cli "${CLI_ARGS[@]}" XRANGE "$STREAM_KEY" - + COUNT "$COUNT"
