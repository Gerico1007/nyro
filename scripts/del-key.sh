#!/bin/bash
source ../.env
curl -X DELETE "https://loyal-lamb-40648.upstash.io/del/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
