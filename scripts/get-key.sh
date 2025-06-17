#!/bin/bash
source ../.env
curl -X GET "https://loyal-lamb-40648.upstash.io/get/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
