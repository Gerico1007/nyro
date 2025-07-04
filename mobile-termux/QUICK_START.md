# 🚀 Quick Start Guide - Termux

## 5-Minute Setup

### 1. Install Termux
- Download from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended)
- Or from Google Play Store

### 2. Clone and Setup
```bash
# Clone the repository
git clone https://github.com/Gerico1007/nyro.git
cd nyro/mobile-termux

# Run the installer
./install.sh
```

### 3. Configure Your Redis
```bash
# Edit the configuration file
nano .env
```

Replace the placeholder values with your actual Upstash credentials:
```bash
KV_REST_API_URL=https://loyal-lamb-40648.upstash.io
KV_REST_API_TOKEN=your_actual_token_here
```

### 4. Start Using!
```bash
# Run the mobile menu
./redis-mobile.sh
```

## 🎯 First Steps

1. **Test connection**: Choose option 5, then set a test key
2. **Write your first diary entry**: Choose option 1
3. **Add location**: When prompted, enter where you are
4. **Read your entries**: Choose option 2
5. **Filter by location**: Choose option 3
6. **Explore your data**: Choose option 9 to scan and select keys

## 📱 Mobile Tips

- **Use landscape mode** for better menu visibility
- **Copy-paste** your Upstash credentials from your dashboard
- **Use location names** like "home", "park", "coffee shop"
- **Save battery** by closing Termux when not using

## 🗃️ Multiple Database Profiles

### Add a New Profile
1. **Edit .env file**:
```bash
nano .env
```

2. **Add profile lines** (replace PROFILENAME with your chosen name):
```bash
# New profile example
PROFILE_PROFILENAME_URL="https://your-database.upstash.io"
PROFILE_PROFILENAME_TOKEN="your_token_here"
```

3. **Profile appears automatically** in:
   - CLI: `./redis-rest.sh profile-list`
   - Interactive menu: Option 9

### Switch Between Profiles
```bash
# CLI switching
./redis-rest.sh profile profilename

# Or use interactive menu
./redis-mobile.sh
# Choose option 9
```

### Delete a Profile
1. **Edit .env file**:
```bash
nano .env
```

2. **Remove both lines** for the profile:
```bash
# Delete these lines
PROFILE_PROFILENAME_URL="..."
PROFILE_PROFILENAME_TOKEN="..."
```

3. **Profile disappears automatically** from all menus

**Note**: Deleting from .env only removes access - your actual database data remains safe and untouched.

### Pre-configured Profiles
- **default**: Points to tashdum (productivity database)
- **musebase**: Creative and artistic data storage
- **tashdum**: Task and productivity data storage
- **threeways**: Multi-purpose data storage

## 🔍 Key Scanner → Clipboard (Enhanced!)

### What is it?
The Key Scanner & Clipboard Export (option 9) provides a streamlined workflow inspired by `fzf`:
- **Pattern-based search**: Find keys using wildcards
- **Visual multi-select**: Use `fzf` for intuitive selection (TAB to mark, ENTER to confirm)
- **Content export**: Gets actual key values, not just key names
- **Direct to clipboard**: Content copied to clipboard + saved to file
- **Timestamp organization**: Files saved with timestamps for easy tracking

### How to use:
1. **Choose option 9** from the main menu
2. **Enter a pattern** (e.g., `walking*`, `user*`, `*` for all)
3. **Select keys with fzf**: 
   - Use **TAB** to mark/unmark keys
   - Use **ENTER** to confirm selection
   - Navigate with arrow keys
4. **Automatic export**: Selected key content copied to clipboard and saved to file

### Pattern Examples:
- `*` - Find all keys
- `user*` - Find keys starting with "user"
- `*project*` - Find keys containing "project"
- `walking*` - Find walking session keys
- `art-*` - Find keys starting with "art-"

### fzf Selection Interface:
```
✅ Select keys (TAB to mark, ENTER to confirm):
> walking:summary:250703
  walking:payload:250703
▶ walking:index:250703
  walking:file:upload-files.sh:250703
  walking:file:redis-mobile.sh:250703
  ...
  17/17 (+) [17/17]
```

### Key Features:
- **Smart fallback**: If `fzf` not available, uses built-in visual selector
- **Content retrieval**: Gets actual values from Redis for each selected key
- **Dual export**: Both clipboard and timestamped file export
- **Organized format**: Each key becomes a markdown section with its content

### Export Format:
Content is exported as markdown with:
```markdown
# walking:index:250703
{
  "walking_session": {
    "date": "2025-07-03",
    ...
  }
}

# walking:file:redis-mobile.sh:250703
#!/bin/bash
# Enhanced redis mobile script...
```

### Output:
- **Clipboard**: Content immediately available for pasting
- **File**: Saved to `~/nyro-exports/YYMMDD_HHMM_pattern_keys.md`
- **Feedback**: Shows progress and completion status

### Fallback Mode (without fzf):
If `fzf` is not installed, uses numbered selection:
- **Numbers**: `1 3 5` - Select specific keys
- **a** - Select all found keys  
- **n** - Clear all selections
- **Enter** - Export selected keys
- **q** - Cancel and return to menu

## 🔧 Troubleshooting

### "curl: command not found"
```bash
pkg install curl
```

### "Permission denied"
```bash
chmod +x *.sh
```

### Connection errors
- Check your internet connection
- Verify your Upstash credentials
- Make sure your Upstash instance is active

### Profile not appearing
- Check .env file syntax (no spaces around =)
- Ensure both URL and TOKEN lines are present
- Profile names are case-sensitive (use lowercase)

## 🌱 Happy Gardening!

Your mobile garden diary with multiple databases is ready! 📱✨ 