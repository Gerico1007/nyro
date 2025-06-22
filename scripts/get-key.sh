#!/bin/bash
source ../.env

curl -X GET "${KV_REST_API_URL}/get/$1" \
  -H "Authorization: Bearer $KV_REST_API_TOKEN"
