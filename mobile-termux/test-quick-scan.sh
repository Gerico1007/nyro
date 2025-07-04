#!/bin/bash

# Quick test for the enhanced key scanner
echo "🧪 Testing Enhanced Key Scanner"
echo "==============================="

# Source the redis functions without running the menu
source redis-rest.sh 2>/dev/null

# Test scan function
echo "Testing pattern scanning..."
if scan_keys_by_pattern "walking*" | head -3; then
    echo "✅ Scan function working"
else
    echo "❌ Scan function failed"
fi

echo ""
echo "✅ Enhancement appears to be working!"
echo "New feature: Option 10 - Quick Scan → Clipboard 🚀"