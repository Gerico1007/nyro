# 🌱 Nyro Redis Mobile - Termux Edition

A mobile-friendly version of Nyro Redis utilities designed specifically for Android Termux.

## 📱 What is this?

This is a lightweight, Docker-free version of your Nyro Redis garden diary that works perfectly on Android devices using Termux. No Docker required!

## ✨ Features

- **🌍 Location-based diary entries** - Track where you were when you wrote each entry
- **📝 Garden diary with streams** - Write and read your garden observations
- **🔍 Location filtering** - View entries by location (e.g., "show me entries from 'park'")
- **⚡ REST API powered** - Fast and reliable connection to Upstash Redis
- **📱 Mobile optimized** - Works great on Android with Termux
- **🔒 Secure** - Uses your Upstash REST API tokens

## 🚀 Quick Start

### 1. Install Termux
- Download Termux from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended) or Google Play
- Open Termux and grant storage permissions

### 2. Clone and Install
```bash
# Clone the repository
git clone https://github.com/Gerico1007/nyro.git
cd nyro/mobile-termux

# Run the installer
chmod +x install.sh
./install.sh
```

### 3. Configure Your Redis
```bash
# Edit your configuration
nano .env
```

Add your Upstash credentials:
```bash
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_kv_rest_api_token_here
```

### 4. Start Using!
```bash
# Run the mobile menu
./redis-mobile.sh
```

## 📋 Menu Options

```
🌱 Nyro Redis Mobile Menu
------------------------
1) Write in garden diary (with location!)
2) Read garden diary
3) Show entries by location
4) Set a key
5) Get a key
6) Delete a key
7) List all keys
q) Quit
```

## 🗺️ Location Features

### Writing with Location
```
Enter what happened: I saw a beautiful butterfly
Enter mood (optional): happy
Enter location (optional): central park
Enter any extra details (optional): It was orange and black
```

### Reading by Location
```
Available locations:
1) central park
2) home
3) coffee shop

Select a location to view all entries from that place!
```

## 🔧 Technical Details

### How it works
- Uses **Upstash REST API** instead of Redis CLI
- **No Docker required** - works directly on Android
- **Location tracking** - stores location with each diary entry
- **Stream-based storage** - uses Redis streams for diary entries

### Files Structure
```
mobile-termux/
├── install.sh          # Installation script
├── redis-mobile.sh     # Main mobile menu
├── diary-write.sh      # Write diary entries
├── diary-read.sh       # Read diary entries
├── location-filter.sh  # Filter by location
├── redis-rest.sh       # REST API wrapper
├── .env.example        # Configuration template
└── README.md          # This file
```

## 🛠️ Troubleshooting

### "curl: command not found"
```bash
pkg install curl
```

### "Permission denied"
```bash
chmod +x *.sh
```

### "Error: KV_REST_API_URL not found"
Make sure your `.env` file exists and contains your Upstash credentials.

### Connection issues
- Check your internet connection
- Verify your Upstash credentials in `.env`
- Ensure your Upstash instance is active

## 🔐 Security

- Your API tokens are stored locally in `.env`
- REST API calls use HTTPS encryption
- No sensitive data is logged or displayed

## 🚶‍♂️ Walking Script - GPT Payload Creator

### Create Walking Payloads for GPT Conversations
Transform any directory into a comprehensive payload for GPT conversations during walks!

```bash
# Run the walking script
./create-walk.sh

# Enter directory (or press Enter for current)
📁 Enter directory path: /path/to/project

# Confirm upload
🤔 Continue with upload? (y/N): y

# Get your keys for GPT
🔑 Main index: walking:index:250703
📝 Summary: walking:summary:250703
```

### What the Walking Script Does
- 🔍 **Scans directory** - Finds all project files automatically
- 📤 **Uploads to Redis** - Stores in your `tashdum` database
- 🗂️ **Creates index** - Organized structure for GPT access
- 🛡️ **Smart filtering** - Excludes `.env`, `.git`, logs automatically
- 📊 **Progress tracking** - Shows upload status and file counts

### GPT Integration
Tell your GPT to fetch: `walking:index:250703` for complete project context during walks!

### See Also
- `WALKING_TUTORIAL.md` - Detailed examples and use cases
- Option 9 in menu - Interactive key scanner for exploring uploaded data

## 📚 Advanced Usage

### Direct REST API calls
```bash
# Test connection
./redis-rest.sh ping

# Set a key
./redis-rest.sh set mykey "my value"

# Get a key
./redis-rest.sh get mykey
```

### Custom diary names
```bash
# Use a different diary name
./diary-write.sh my-special-diary
./diary-read.sh my-special-diary
```

## 🤝 Contributing

Found a bug or want to add features? 
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the same license as the main Nyro project.

## 🙏 Acknowledgments

- **Termux** - For providing an amazing Linux environment on Android
- **Upstash** - For reliable Redis hosting
- **Redis** - For the powerful stream functionality

---

**Happy gardening on the go! 🌱📱** 