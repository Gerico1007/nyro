#!/bin/bash

# Show entries by location for the garden diary stream
# Usage: ./show-by-location.sh [diary_name]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

set -a
source <(cat "$ENV_FILE" | tr -d '\r')
set +a

if [ -z "$REDIS_URL" ]; then
    echo "Error: REDIS_URL is not set in $ENV_FILE"
    exit 1
fi

diary_name="${1:-garden.diary}"

# Get all entries (limit to 100 for performance)
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    entries=$(redis-cli --tls -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100)
else
    entries=$(redis-cli -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100)
fi

# Extract all locations
locations=$(echo "$entries" | grep -A1 'location' | grep -v 'location' | awk '{$1=$1};1' | sort | uniq)

if [ -z "$locations" ]; then
    echo "No locations found in the stream."
    exit 0
fi

echo "Available locations:"
select loc in $locations; do
    if [ -n "$loc" ]; then
        echo "Showing entries for location: $loc"
        break
    else
        echo "Invalid selection. Try again."
    fi
done

# Show entries for the selected location
if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100 | awk -v loc="$loc" '
    BEGIN {entry=""; show=0;}
    /^1\)/ {entry=$0; show=0; next}
    /location/ {getline; if ($0 ~ loc) show=1; else show=0; next}
    {if (show) print entry "\n" $0;}'
else
    redis-cli -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100 | awk -v loc="$loc" '
    BEGIN {entry=""; show=0;}
    /^1\)/ {entry=$0; show=0; next}
    /location/ {getline; if ($0 ~ loc) show=1; else show=0; next}
    {if (show) print entry "\n" $0;}'
fi 