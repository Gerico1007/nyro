#!/bin/bash

# Universal Walking Payload Creator
# Creates walking payload from any directory for GPT conversations

echo "🚶‍♂️ Universal Walking Payload Creator"
echo "=================================="

# Get current date for payload key
DATE_KEY=$(date +"%y%m%d")

# Ask for directory
echo -n "📁 Enter directory path (or press Enter for current): "
read target_dir

# Use current directory if empty
if [ -z "$target_dir" ]; then
    target_dir=$(pwd)
fi

# Validate directory exists
if [ ! -d "$target_dir" ]; then
    echo "❌ Directory not found: $target_dir"
    exit 1
fi

echo "📂 Target directory: $target_dir"
echo "📅 Date key: $DATE_KEY"

# Switch to tashdum profile for upload
echo "🔄 Switching to tashdum profile..."
./redis-rest.sh profile tashdum

# Get list of files (excluding .env and common ignore patterns)
echo "🔍 Scanning files in directory..."
cd "$target_dir"

# Find all files, excluding common patterns
files=$(find . -type f \
    -not -name ".env" \
    -not -name "*.log" \
    -not -name "*.tmp" \
    -not -name ".git*" \
    -not -name "node_modules" \
    -not -name "*.swp" \
    -not -name "*~" \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    | sort)

if [ -z "$files" ]; then
    echo "❌ No files found in directory"
    exit 1
fi

file_count=$(echo "$files" | wc -l)
echo "📊 Found $file_count files to upload"

# Show files that will be uploaded
echo ""
echo "📋 Files to upload:"
echo "$files" | head -10
if [ "$file_count" -gt 10 ]; then
    echo "   ... and $((file_count - 10)) more files"
fi

echo ""
echo -n "🤔 Continue with upload? (y/N): "
read confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Upload cancelled"
    exit 0
fi

echo ""
echo "📤 Uploading files..."

# Create file index
uploaded_files="[]"
total_size=0

# Upload each file
file_num=0
while IFS= read -r file; do
    if [ -n "$file" ]; then
        file_num=$((file_num + 1))
        
        # Clean filename for key (remove ./ and replace / with _)
        clean_name=$(echo "$file" | sed 's|^\./||' | sed 's|/|_|g')
        key="walking:file:${clean_name}:${DATE_KEY}"
        
        echo "📄 [$file_num/$file_count] Uploading: $file → $key"
        
        # Get file size and type
        file_size=$(wc -l < "$file" 2>/dev/null || echo "binary")
        file_type="unknown"
        
        case "$file" in
            *.sh) file_type="bash_script" ;;
            *.md) file_type="markdown" ;;
            *.js) file_type="javascript" ;;
            *.py) file_type="python" ;;
            *.json) file_type="json" ;;
            *.txt) file_type="text" ;;
            *.yml|*.yaml) file_type="yaml" ;;
            *) file_type="text" ;;
        esac
        
        # Upload file content
        if cat "$file" | ./redis-rest.sh set-massive "$key" >/dev/null 2>&1; then
            echo "   ✅ Uploaded successfully"
            total_size=$((total_size + file_size))
            
            # Add to index (simple append)
            uploaded_files="${uploaded_files%]}, {\"key\": \"$key\", \"path\": \"$file\", \"type\": \"$file_type\", \"size\": \"$file_size lines\"}]"
        else
            echo "   ❌ Upload failed"
        fi
    fi
done <<< "$files"

# Fix JSON array format
uploaded_files=$(echo "$uploaded_files" | sed 's|^\[\], |[|')

# Create main index
INDEX="{
  \"walking_session\": {
    \"date\": \"$(date '+%Y-%m-%d')\",
    \"time\": \"$(date '+%H:%M:%S')\",
    \"directory\": \"$target_dir\",
    \"session_key\": \"$DATE_KEY\",
    \"total_files\": $file_count,
    \"total_lines\": $total_size
  },
  \"files_uploaded\": $uploaded_files,
  \"usage\": {
    \"description\": \"Walking payload created from directory scan\",
    \"gpt_instructions\": \"Fetch individual files using their keys for detailed analysis\",
    \"main_index_key\": \"walking:index:$DATE_KEY\"
  },
  \"ready_for_walk\": true
}"

echo ""
echo "📋 Creating session index..."
echo "$INDEX" | ./redis-rest.sh set-massive "walking:index:$DATE_KEY"

# Create quick summary
SUMMARY="Walking session $DATE_KEY: $file_count files from $target_dir ($total_size total lines). Ready for GPT conversation."
./redis-rest.sh set "walking:summary:$DATE_KEY" "$SUMMARY"

echo ""
echo "🎉 Walking payload created successfully!"
echo "==============================================" 
echo "📊 Session Summary:"
echo "   Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "   Directory: $target_dir"
echo "   Files uploaded: $file_count"
echo "   Total lines: $total_size"
echo ""
echo "🔑 Keys created:"
echo "   📋 Main index: walking:index:$DATE_KEY"
echo "   📝 Summary: walking:summary:$DATE_KEY"
echo "   📁 Files: walking:file:*:$DATE_KEY"
echo ""
echo "🚶‍♂️ Ready for your walk and GPT conversation!"
echo "   Tell your GPT to fetch: walking:index:$DATE_KEY"
echo ""