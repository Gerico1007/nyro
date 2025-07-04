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

## 🔍 Key Scanner & Selector (New!)

### What is it?
The Interactive Key Scanner & Selector (option 9) allows you to:
- Search for keys using patterns (wildcards)
- Select multiple keys at once
- Perform batch operations on selected keys
- Export data in organized formats

### How to use:
1. **Choose option 9** from the main menu
2. **Enter a pattern** (e.g., `user*`, `art-*`, `task*`, or `*` for all)
3. **Select keys** using numbers (space-separated) or commands
4. **Choose operation**: get values, delete, export to file/clipboard

### Pattern Examples:
- `*` - Find all keys
- `user*` - Find keys starting with "user"
- `*project*` - Find keys containing "project"
- `art-*` - Find keys starting with "art-"
- `task*` - Find productivity-related keys

### Selection Commands:
- **Numbers**: `1 3 5` - Select specific keys
- **all** - Select all found keys
- **none** - Clear all selections
- **done** - Confirm selection and continue
- **quit** - Cancel and return to menu

### Batch Operations:
1. **Get Values** - Display all selected key values
2. **Delete Keys** - Remove selected keys (with confirmation)
3. **Export to File** - Save to `~/nyro-exports/` with timestamp
4. **Export to Clipboard** - Copy formatted data (if available)

### Export Format:
Exports are saved as markdown files with:
- Timestamp and profile information
- Organized key-value sections
- JSON formatting when applicable
- Clear separation between entries

## 🚀 Quick Scan → Clipboard (Enhanced!)

### What is it?
The Quick Scan → Clipboard feature (option 10) provides a streamlined workflow:
- **Faster workflow**: Pattern → Visual selector → Direct clipboard
- **Visual interface**: See all keys with selection indicators
- **One-step export**: Press Enter to copy selected keys directly to clipboard
- **Optimized for speed**: Perfect for frequent key copying tasks

### How to use:
1. **Choose option 10** from the main menu
2. **Enter a pattern** (e.g., `walking*`, `user*`, `*`)
3. **Visual selection**: Keys displayed with selection markers
4. **Select keys**: Use numbers, 'a' for all, 'n' for none
5. **Press Enter**: Selected keys copied directly to clipboard

### Visual Interface Example:
```
📋 Select keys (Press Enter to copy to clipboard)
─────────────────────────────────────────────────
  walking:summary:250703
  walking:payload:250703
▌ walking:index:250703 [SELECTED]
  walking:file:upload-files.sh:250703
▌ walking:file:redis-mobile.sh:250703 [SELECTED]
  ...
  17/17 (2 selected) ─────────────────────────────────
> 

Commands: [numbers] select, [a]ll, [n]one, [Enter] copy to clipboard, [q]uit
```

### Quick Commands:
- **Numbers**: `1 5 8` - Toggle selection of specific keys
- **a** - Select all keys
- **n** - Clear all selections  
- **Enter** - Copy selected keys to clipboard
- **q** - Cancel and return to menu

### When to use Quick Scan vs Regular Scanner:
- **Quick Scan (Option 10)**: When you want keys copied to clipboard quickly
- **Regular Scanner (Option 9)**: When you need other operations (view values, delete, export to file)

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