#!/bin/bash
set -e

# Nyro – Germination: Redis Stream Insertion Script
# Reads .env, parses Redis URI per lettuce spec, writes to Redis stream

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Clean Windows line endings and source env vars
set -a
source <(tr -d '\r' < "$ENV_FILE")
set +a

if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

# Validate CLI and check version
if ! command -v redis-cli &> /dev/null; then
    echo "Error: redis-cli is not installed. Please install it."
    exit 1
fi

# Check Redis CLI version and TLS support
REDIS_VERSION=$(redis-cli --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
if redis-cli --help 2>&1 | grep -q -- '--tls'; then
    SUPPORTS_TLS=1
else
    SUPPORTS_TLS=0
    echo "Warning: Your redis-cli version $REDIS_VERSION does not support TLS."
    echo "For secure connections, please upgrade to Redis 6.0+ with TLS support."
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <stream-key> <field> <value> [field2 value2 ...]"
    exit 1
fi

STREAM_KEY="$1"
shift

# Parse REDIS_URL
REDIS_SCHEME=$(echo "$REDIS_URL" | sed -n 's,^\([a-z\-]*\)://.*,\1,p')
URI_BODY=$(echo "$REDIS_URL" | sed -n 's,^[a-z\-]*://,,p')

REDIS_TLS=0
case "$REDIS_SCHEME" in
    rediss) REDIS_TLS=1 ;;
    redis) REDIS_TLS=0 ;;
    redis-socket)
        REDIS_SOCKET=$(echo "$URI_BODY" | cut -d'?' -f1)
        ;;
    *)
        echo "Error: Unsupported Redis scheme: $REDIS_SCHEME"
        exit 1
        ;;
esac

# Defaults
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_USER=""
REDIS_PASS=""

if [[ "$REDIS_SCHEME" == "redis-socket" ]]; then
    :
elif [[ "$URI_BODY" =~ ^([^:@/]*):([^@]*)@([^:/]+):([0-9]+) ]]; then
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

# Compose CLI args
CLI_ARGS=()
if [ "$REDIS_TLS" = "1" ]; then
    if [ "$SUPPORTS_TLS" = "1" ]; then
        CLI_ARGS+=(--tls)
    else
        echo "Error: Your redis-cli does not support TLS (--tls flag)."
        echo "Current version: $REDIS_VERSION"
        echo "Please upgrade to Redis 6.0+ with TLS support, or use a non-TLS connection."
        exit 1
    fi
fi
if [ -n "$REDIS_HOST" ]; then
    CLI_ARGS+=(-h "$REDIS_HOST")
fi
if [ -n "$REDIS_PORT" ]; then
    CLI_ARGS+=(-p "$REDIS_PORT")
fi
if [ -n "$REDIS_PASS" ]; then
    CLI_ARGS+=(-a "$REDIS_PASS")
fi

# For UNIX socket
if [ -n "$REDIS_SOCKET" ]; then
    CLI_ARGS=(-s "$REDIS_SOCKET")
fi

# Build field-value pairs (as arguments)
FIELDVALS=()
while [ "$#" -gt 1 ]; do
    FIELDVALS+=("$1" "$2")
    shift 2
done

# Final command
echo "Connecting: redis-cli ${CLI_ARGS[*]}"
echo "Inserting into stream '$STREAM_KEY' with fields: ${FIELDVALS[*]}"

redis-cli "${CLI_ARGS[@]}" XADD "$STREAM_KEY" * "${FIELDVALS[@]}"

