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

1. **Test connection**: Choose option 4, then set a test key
2. **Write your first diary entry**: Choose option 1
3. **Add location**: When prompted, enter where you are
4. **Read your entries**: Choose option 2
5. **Filter by location**: Choose option 3

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
- **default**: Main development database
- **musebase**: Creative and artistic data storage
- **tashdum**: Task and productivity data storage

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