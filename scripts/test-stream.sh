#!/bin/bash
set -e

echo "1. Testing Redis connection..."
redis-cli PING

echo -e "\n2. Creating a test stream entry..."
RESULT=$(redis-cli --raw XADD teststream '*' sensor temperature25.5)
echo "XADD Result: $RESULT"

echo -e "\n3. Reading the stream..."
redis-cli XRANGE teststream - +

echo -e "\n4. Stream info..."
redis-cli XINFO STREAM teststream
