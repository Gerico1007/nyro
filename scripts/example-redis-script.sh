#!/bin/bash

# Example script that runs inside the Docker container
# This script demonstrates Redis operations with your Upstash instance

echo "=== Redis Script Example ==="
echo "Running inside Docker container with Redis connection"
echo ""

# Check if Redis environment variables are available
if [ -z "$REDIS_HOST" ] || [ -z "$REDIS_TOKEN" ]; then
    echo "Error: Redis environment variables not set"
    exit 1
fi

echo "Redis Host: $REDIS_HOST"
echo "Redis Port: $REDIS_PORT"
echo "Redis Token: ${REDIS_TOKEN:0:8}..."
echo ""

# Test Redis connection
echo "Testing Redis connection..."
redis-cli --tls -u "$REDIS_URL" ping
echo ""

# Set some test data
echo "Setting test data..."
redis-cli --tls -u "$REDIS_URL" set "script_test:timestamp" "$(date)"
redis-cli --tls -u "$REDIS_URL" set "script_test:hostname" "$(hostname)"
redis-cli --tls -u "$REDIS_URL" set "script_test:container" "docker-redis-script"
echo ""

# Get the data back
echo "Retrieving test data..."
echo "Timestamp: $(redis-cli --tls -u "$REDIS_URL" get "script_test:timestamp")"
echo "Hostname: $(redis-cli --tls -u "$REDIS_URL" get "script_test:hostname")"
echo "Container: $(redis-cli --tls -u "$REDIS_URL" get "script_test:container")"
echo ""

# List keys with pattern
echo "Keys matching 'script_test:*':"
redis-cli --tls -u "$REDIS_URL" keys "script_test:*"
echo ""

# Get Redis server info
echo "Redis Server Info:"
redis-cli --tls -u "$REDIS_URL" info server | head -5
echo ""

# Clean up test data (optional)
echo "Cleaning up test data..."
redis-cli --tls -u "$REDIS_URL" del "script_test:timestamp"
redis-cli --tls -u "$REDIS_URL" del "script_test:hostname"
redis-cli --tls -u "$REDIS_URL" del "script_test:container"
echo ""

echo "=== Script completed successfully ===" 