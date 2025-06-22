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

# Extract all full location phrases (not split by spaces)
locations=$(echo "$entries" | awk '/location/ {getline; print $0}' | awk '{$1=$1};1' | sort | uniq)

if [ -z "$locations" ]; then
    echo "No locations found in the stream."
    exit 0
fi

echo "Available locations:"
select loc in $locations; do
    if [ -n "$loc" ]; then
        echo "\nShowing entries for location: $loc\n"
        break
    else
        echo "Invalid selection. Try again."
    fi
done

# Print full entries for the selected location
awk_script='BEGIN {entry=""; found=0;}
/^1\)/ {if (found) print entry "\n"; entry=$0; found=0; next}
/location/ {getline; if ($0 == loc) found=1; entry=entry "\nlocation\n" $0; next}
{entry=entry "\n" $0}
END {if (found) print entry "\n";}'

if [[ "$REDIS_URL" =~ ^rediss:// ]]; then
    redis-cli --tls -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100 | awk -v loc="$loc" "$awk_script"
else
    redis-cli -u "$REDIS_URL" --no-auth-warning XRANGE "$diary_name" - + COUNT 100 | awk -v loc="$loc" "$awk_script"
fi 