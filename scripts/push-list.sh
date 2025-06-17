#!/bin/bash
source ../.env
curl -X POST "https://loyal-lamb-40648.upstash.io/lpush/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"element\":\"$2\"}"
