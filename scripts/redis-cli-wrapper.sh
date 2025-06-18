#!/bin/bash
source "$(dirname "$0")/../.env"

# Build Redis CLI command with TLS support
redis-cli -u "$REDIS_URL" --tls "$@"
