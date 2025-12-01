# 🎯 Nyro Profile System - Quick Reference

## ✅ Your Setup
Your `.env` file now has:
- **1 Default Profile**: `default` (primary Redis database)
- **3 Named Profiles**: `testing`, `production`, `secondary`

## 📋 Profile Structure

### How to Set Up Multiple Profiles in `.env`

```bash
# ═══════════════════════════════════════════════════════════════
# DEFAULT PROFILE (always used by default)
# ═══════════════════════════════════════════════════════════════
KV_REST_API_URL="https://your-main-db.upstash.io"
KV_REST_API_TOKEN="your_main_token_here"

# ═══════════════════════════════════════════════════════════════
# NAMED PROFILES (use with --profile flag)
# ═══════════════════════════════════════════════════════════════

# Format: PROFILE_<NAME>_URL and PROFILE_<NAME>_TOKEN
# Name must match between both variables

# Profile 1
PROFILE_TESTING_URL="https://test-db.upstash.io"
PROFILE_TESTING_TOKEN="test_token_here"

# Profile 2
PROFILE_PRODUCTION_URL="https://prod-db.upstash.io"
PROFILE_PRODUCTION_TOKEN="prod_token_here"

# Profile 3
PROFILE_SECONDARY_URL="https://secondary-db.upstash.io"
PROFILE_SECONDARY_TOKEN="secondary_token_here"
```

## 🎮 Usage Patterns

### Pattern 1: Work with Default Profile
```bash
$ nyro set key1 "value1"
$ nyro get key1
$ nyro scan '*'
```

### Pattern 2: Use --profile Flag (Don't Switch)
```bash
# Query testing without switching
$ nyro --profile testing get key1
$ nyro -p testing scan '*'

# Then use production without switching
$ nyro -p production set key2 "value2"
```

### Pattern 3: Switch Profile (Persistent)
```bash
# Switch to testing
$ nyro profiles switch testing

# All commands now use testing profile
$ nyro set key "test_value"
$ nyro get key
$ nyro list

# Switch to production
$ nyro profiles switch production

# Now all commands use production
$ nyro get key                  # Gets from production
```

## 🔧 Key Commands

| Command | Purpose |
|---------|---------|
| `nyro profiles list` | Show all available profiles |
| `nyro profiles current` | Show active profile |
| `nyro profiles switch <name>` | Switch to profile |
| `nyro -p <name> command` | Run command on specific profile |
| `nyro --profile <name> set key val` | Long form of above |

## 💡 Common Scenarios

### Scenario A: Development & Testing
```bash
# Work on testing database
$ nyro profiles switch testing
$ nyro set user:123 '{"name":"Alice"}'
$ nyro get user:123

# Verify production before deploying
$ nyro -p production get user:123
```

### Scenario B: Data Migration
```bash
# Copy from testing to production
$ nyro -p testing get legacy_user:1
$ nyro -p production set user:1 '{"name":"Bob"}'
```

### Scenario C: Multi-Terminal Workflow
```bash
# Terminal 1: Interactive mode on testing
$ nyro profiles switch testing
$ nyro interactive

# Terminal 2: Query production (doesn't affect Terminal 1)
$ nyro -p production scan '*'
$ nyro -p production get key
```

## 📝 Best Practices

✅ **DO:**
- Use descriptive profile names: `TESTING`, `PRODUCTION`, `STAGING`
- Keep tokens secure in `.env` file (don't commit!)
- Use `--profile` flag for one-off queries
- Use `profiles switch` for sustained work

❌ **DON'T:**
- Use generic names like `DB1`, `DB2`
- Put tokens in code or shell history
- Forget which profile you're on before writing data
- Create too many profiles (confusing)

## 🔐 Security Reminder

Your `.env` contains sensitive tokens:
- Add `.env` to `.gitignore` ✅
- Don't share `.env` publicly ✅
- Use different tokens per profile ✅
- Rotate tokens periodically ✅

---

**Your Current Setup:**
```
default      → https://central-colt-14211.upstash.io (active)
├── testing  → https://test-redis.upstash.io
├── production → https://prod-redis.upstash.io
└── secondary → https://secondary-redis.upstash.io
```
