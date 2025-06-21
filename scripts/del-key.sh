#!/bin/bash
source ../.env
curl -X DELETE "$KV_REST_API_URL/del/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
