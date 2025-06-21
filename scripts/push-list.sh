#!/bin/bash
source ../.env
curl -X POST "$KV_REST_API_URL/lpush/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"element\":\"$2\"}"
