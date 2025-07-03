#!/bin/bash

echo "🔍 Uploading individual files for walking payload..."

# Switch to tashdum profile
./redis-rest.sh profile tashdum

# Upload each file with metadata
echo "📄 Uploading redis-mobile.sh..."
cat redis-mobile.sh | ./redis-rest.sh set-massive "walking:file:redis-mobile.sh:250703"

echo "📄 Uploading QUICK_START.md..."
cat QUICK_START.md | ./redis-rest.sh set-massive "walking:file:QUICK_START.md:250703"

echo "📄 Uploading testing/TESTING_LEDGER.md..."
cat testing/TESTING_LEDGER.md | ./redis-rest.sh set-massive "walking:file:TESTING_LEDGER.md:250703"

echo "📄 Uploading .env configuration..."
cat .env | ./redis-rest.sh set-massive "walking:file:env:250703"

# Create an index with file list
INDEX='{
  "walking_session": {
    "date": "2025-07-03",
    "session_type": "Interactive Key Scanner Implementation",
    "issue_resolved": "#11",
    "branch": "11-key-scanner",
    "commit_hash": "b8afe3c"
  },
  "files_uploaded": [
    {
      "key": "walking:file:redis-mobile.sh:250703",
      "description": "Enhanced main menu script with interactive key scanner, multi-select interface, and batch operations",
      "type": "bash_script",
      "size": "849 lines"
    },
    {
      "key": "walking:file:QUICK_START.md:250703", 
      "description": "Updated tutorial with comprehensive key scanner documentation and usage instructions",
      "type": "documentation",
      "size": "170 lines"
    },
    {
      "key": "walking:file:TESTING_LEDGER.md:250703",
      "description": "Complete testing ledger with Session 9 four-perspective analysis",
      "type": "testing_log", 
      "size": "975 lines"
    },
    {
      "key": "walking:file:env:250703",
      "description": "Multi-database configuration with tashdum, musebase, threeways profiles",
      "type": "configuration",
      "size": "56 lines"
    }
  ],
  "achievements": {
    "lines_added": 795,
    "files_modified": 4,
    "new_features": [
      "Interactive Key Scanner with Redis SCAN integration",
      "Multi-select interface with visual indicators (●/○)",
      "Batch operations: get values, delete keys, export",
      "Pattern-based key discovery with wildcards",
      "Organized markdown export with timestamps",
      "Profile-aware operations across all databases"
    ]
  },
  "ready_for_gpt": true
}'

echo "📋 Creating file index..."
echo "$INDEX" | ./redis-rest.sh set-massive "walking:index:250703"

echo "✅ All files uploaded individually!"
echo "📊 Keys created:"
echo "  - walking:index:250703 (main index)"
echo "  - walking:file:redis-mobile.sh:250703"
echo "  - walking:file:QUICK_START.md:250703"
echo "  - walking:file:TESTING_LEDGER.md:250703"
echo "  - walking:file:env:250703"
echo "🚶‍♂️ Complete file contents ready for GPT conversation!"