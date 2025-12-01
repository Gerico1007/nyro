# Nyro Installation Guide
**♠️🌿🎸🧵 G.Music Assembly Package**

Easy setup guide for deploying Nyro on any device.

## 🚀 Quick Installation

### Prerequisites
- Python 3.7+ 
- pip package manager
- Internet connection

### One-Command Install
```bash
git clone https://github.com/gerico1007/nyro.git
cd nyro
pip install -e .
nyro init
```

## 📋 Step-by-Step Installation

### 1. Clone the Repository
```bash
git clone https://github.com/gerico1007/nyro.git
cd nyro
```

### 2. Install the Package
```bash
# Install in development mode
pip install -e .

# Or install specific extras
pip install -e .[musical]  # With music features
pip install -e .[dev]      # With development tools
pip install -e .[all]      # Everything
```

### 3. Initialize Environment
```bash
nyro init
```

This creates a `.env` file with template configuration.

### 4. Configure Redis Credentials
Edit the `.env` file with your actual Redis credentials:

```bash
# Edit with your favorite editor
nano .env
# or
vim .env
# or
code .env
```

**Required configuration:**
```env
# Your Upstash Redis REST API credentials
KV_REST_API_URL=https://your-redis-url.upstash.io
KV_REST_API_TOKEN=your_actual_token_here
```

### 5. Test Installation
```bash
# Test connection
nyro test

# Start interactive mode
nyro interactive
```

## 🎯 Complete Setup Example

```bash
# 1. Clone and install
git clone https://github.com/gerico1007/nyro.git
cd nyro
pip install -e .

# 2. Initialize environment
nyro init

# 3. Edit .env file (replace with your credentials)
echo 'KV_REST_API_URL=https://your-actual-redis.upstash.io' > .env
echo 'KV_REST_API_TOKEN=your_actual_token' >> .env

# 4. Test everything works
nyro test
nyro set welcome "Hello from Nyro!"
nyro get welcome

# 5. Enjoy unified Redis operations!
nyro interactive
```

## 🔧 Configuration Options

### Multiple Profiles
Add additional Redis databases to `.env`:

```env
# Default database
KV_REST_API_URL=https://primary-redis.upstash.io
KV_REST_API_TOKEN=primary_token

# Additional profiles
PROFILE_SECONDARY_URL=https://secondary-redis.upstash.io
PROFILE_SECONDARY_TOKEN=secondary_token

PROFILE_TESTING_URL=https://test-redis.upstash.io
PROFILE_TESTING_TOKEN=test_token
```

### Redis CLI Support
For direct Redis CLI usage (alternative to REST API):

```env
# Use Redis CLI instead of REST API
REDIS_URL=redis://localhost:6379
# or with authentication
REDIS_URL=rediss://user:password@redis-host.com:6380
```

## 📱 Device-Specific Instructions

### Linux/Ubuntu
```bash
# Install Python if needed
sudo apt update
sudo apt install python3 python3-pip git

# Install Nyro
git clone https://github.com/gerico1007/nyro.git
cd nyro
pip3 install -e .
nyro init
```

### macOS
```bash
# Install Python if needed (using Homebrew)
brew install python git

# Install Nyro
git clone https://github.com/gerico1007/nyro.git
cd nyro
pip install -e .
nyro init
```

### Windows
```cmd
# Install Python from python.org if needed
# Install Git from git-scm.com if needed

# Install Nyro
git clone https://github.com/gerico1007/nyro.git
cd nyro
pip install -e .
nyro init
```

### Docker Installation
```dockerfile
FROM python:3.9-slim

# Install Nyro
RUN git clone https://github.com/gerico1007/nyro.git /app/nyro
WORKDIR /app/nyro
RUN pip install -e .

# Initialize and configure
RUN nyro init
COPY .env .env

# Ready to use
CMD ["nyro", "interactive"]
```

## 🎼 Musical Features Setup

For full musical ledger capabilities:

```bash
# Install with musical dependencies
pip install -e .[musical]

# Test musical features
nyro music summary
```

## 🧪 Testing Installation

### Quick Test
```bash
# Basic functionality
nyro test
nyro set test "installation_success"
nyro get test
nyro del test
```

### Comprehensive Test
```bash
# Run full Assembly test suite
python -m testing.test_framework
```

### Interactive Test
```bash
nyro interactive
# Choose option 9 for "Quick Scan & Test"
```

## 🚨 Troubleshooting

### Common Issues

**"No .env file found"**
```bash
# Solution: Initialize environment
nyro init
# Then edit .env with your credentials
```

**"Connection failed"**
```bash
# Check your credentials in .env
cat .env
# Verify URLs and tokens are correct
nyro profiles current
```

**"Module not found"**
```bash
# Reinstall the package
pip install -e . --force-reinstall
```

**"Permission denied"**
```bash
# Install with user flag
pip install -e . --user
```

## 📊 Verification Checklist

After installation, verify these work:

- [ ] `nyro --help` shows command options
- [ ] `nyro init` creates `.env` file
- [ ] `nyro test` reports connection success  
- [ ] `nyro interactive` starts CLI interface
- [ ] `nyro set key value` works without errors
- [ ] `nyro get key` retrieves the value
- [ ] `nyro profiles list` shows available profiles

## 🎯 What Nyro Replaces

This single package replaces these bash scripts:
- ✅ `menu.sh` → `nyro interactive`
- ✅ `set-key.sh` → `nyro set`
- ✅ `get-key.sh` → `nyro get` 
- ✅ `del-key.sh` → `nyro del`
- ✅ `scan-garden.sh` → `nyro scan --garden`
- ✅ `stream-add.sh` → `nyro stream diary add`
- ✅ `stream-read.sh` → `nyro stream diary read`
- ✅ `push-list.sh` → `nyro list push`
- ✅ `read-list.sh` → `nyro list read`
- ✅ `redis-mobile.sh` → `nyro interactive` (enhanced)
- ✅ `redis-rest.sh` → Built into core functionality
- ✅ `setup-env.sh` → `nyro init`
- ✅ All profile management scripts → `nyro profiles`

## 🎵 Musical Integration

Nyro includes unique musical session tracking:

```bash
# Enable musical logging
nyro --musical interactive

# View session melodies
nyro music summary

# Export ABC notation
nyro music export
```

## 🆘 Support

- **Documentation**: Check `CLAUDE.md` for Assembly team info
- **Testing**: Run `python -m testing.test_framework`
- **Issues**: Review `ASSEMBLY_LEDGER.md` for session details
- **Musical**: See `ECHOTHREADS_ENHANCEMENT_PROPOSAL.md`

---

**🎼 Installation Complete!**  
*Welcome to the ♠️🌿🎸🧵 G.Music Assembly experience*

*Jerry's ⚡ vision of unified Redis operations is now at your fingertips!*