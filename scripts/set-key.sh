#!/bin/bash
source ../.env
curl -X POST "$KV_REST_API_URL/set/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"value\":\"$2\"}"
