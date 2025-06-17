#!/bin/bash
source ../.env

# Check if list name is provided
if [ -z "$1" ]; then
    echo "Error: List name is required"
    echo "Usage: ./read-list.sh <list-name> [start] [stop]"
    exit 1
fi

LIST_NAME="$1"
START="${2:-0}"
STOP="${3:-10}"

curl -X GET "https://loyal-lamb-40648.upstash.io/lrange/$LIST_NAME/$START/$STOP" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
