#!/bin/bash
source ../.env

# Get pattern or default to all keys
PATTERN="${1:-*}"

curl -X GET "https://loyal-lamb-40648.upstash.io/scan/0/match/$PATTERN/count/100" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
