# Docker Redis CLI Tutorial

## Why Use Docker for Redis CLI?

Using Docker for Redis CLI has several benefits:

1. **No Local Installation Required**: You don't need to install Redis CLI on your system
2. **Consistent Environment**: Same Redis CLI version across all machines
3. **Isolation**: Redis CLI runs in its own container, not affecting your system
4. **Easy Updates**: Just pull a new Docker image to update Redis CLI
5. **Cross-Platform**: Works the same on Linux, macOS, and Windows

## Prerequisites

1. **Docker installed** on your system
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/) for Windows/Mac
   - [Docker Engine](https://docs.docker.com/engine/install/) for Linux

2. **Redis connection details** (Upstash or other Redis provider)

## Setup

### 1. Create Environment File

Create a `.env` file in your project root. You have two options:

#### Option 1: Single REDIS_URL (Recommended)

```bash
# .env
REDIS_URL=redis://default:[YOUR_KV_REST_API_TOKEN]@central-colt-14211.upstash.io:6379
```

#### Option 2: Separate Variables (More Flexible)

```bash
# .env
REDIS_HOST=central-colt-14211.upstash.io
REDIS_PORT=6379
REDIS_TOKEN=your_kv_rest_api_token_here
```

Replace the values with your actual Upstash credentials.

### 2. Make the Wrapper Script Executable

```bash
chmod +x scripts/redis-cli-wrapper.sh
```

## Usage

### Basic Usage

```bash
# Run the wrapper script
./scripts/redis-cli-wrapper.sh

# This will connect to your Redis instance via Docker
# You'll see connection details displayed for verification
```

### With Commands

```bash
# Ping the Redis server
./scripts/redis-cli-wrapper.sh ping

# Set a key
./scripts/redis-cli-wrapper.sh set mykey "Hello World"

# Get a key
./scripts/redis-cli-wrapper.sh get mykey

# List all keys
./scripts/redis-cli-wrapper.sh keys "*"

# Monitor Redis commands in real-time
./scripts/redis-cli-wrapper.sh monitor
```

### Interactive Mode

```bash
# Start interactive Redis CLI session
./scripts/redis-cli-wrapper.sh

# You'll see the Redis prompt: 127.0.0.1:6379>
# Type Redis commands directly:
# > ping
# > set test "Hello Docker Redis!"
# > get test
# > exit
```

## How the Wrapper Works

The `redis-cli-wrapper.sh` script:

1. **Sources environment variables** from `.env` file
2. **Supports two configuration formats**:
   - Single `REDIS_URL` variable
   - Separate `REDIS_HOST`, `REDIS_PORT`, and `REDIS_TOKEN` variables
3. **Parses the connection details** to extract token, host, and port
4. **Runs Docker command** with the redis:alpine image
5. **Passes through all arguments** to the Redis CLI
6. **Shows connection details** for verification (host, port, partial token)

### Docker Command Breakdown

```bash
docker run -it --rm redis:alpine redis-cli --tls -u "redis://default:${TOKEN}@${HOST}:${PORT}" "$@"
```

- `docker run`: Start a new container
- `-it`: Interactive mode with terminal
- `--rm`: Remove container when it exits
- `redis:alpine`: Use the lightweight Redis Alpine image
- `redis-cli`: Run the Redis CLI tool
- `--tls`: Enable TLS encryption (required for Upstash)
- `-u`: Specify the Redis URL
- `"$@"`: Pass all script arguments to redis-cli

## Configuration Options

### Option 1: REDIS_URL (Single Variable)

**Pros:**
- Simple, one-line configuration
- Standard format used by many Redis clients
- Easy to copy from Redis provider dashboards

**Example:**
```bash
REDIS_URL=redis://default:abc123def456@central-colt-14211.upstash.io:6379
```

### Option 2: Separate Variables

**Pros:**
- More readable and maintainable
- Easier to update individual components
- Better for scripts that need to access host/port separately
- Clearer error messages when individual parts are missing

**Example:**
```bash
REDIS_HOST=central-colt-14211.upstash.io
REDIS_PORT=6379
REDIS_TOKEN=abc123def456
```

## Alternative: Direct Docker Command

If you prefer not to use the wrapper, you can run Docker directly:

```bash
# Using REDIS_URL
docker run -it --rm redis:alpine redis-cli --tls -u "$REDIS_URL"

# Using separate variables
docker run -it --rm redis:alpine redis-cli --tls -u "redis://default:${REDIS_TOKEN}@${REDIS_HOST}:${REDIS_PORT}"
```

## Troubleshooting

### Docker Not Found
```bash
# Install Docker on Ubuntu/Debian
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional, for non-root access)
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### Permission Denied
```bash
# Make script executable
chmod +x scripts/redis-cli-wrapper.sh
```

### Configuration Errors

The script will show helpful error messages if configuration is missing:

```bash
Error: Redis configuration not found!

Please set up your Redis connection in one of these ways:

Option 1 - Single REDIS_URL in .env:
REDIS_URL=redis://default:[YOUR_TOKEN]@[YOUR_HOST]:[PORT]

Option 2 - Separate variables in .env:
REDIS_HOST=[YOUR_HOST]
REDIS_PORT=[YOUR_PORT]
REDIS_TOKEN=[YOUR_TOKEN]

Example for Upstash:
REDIS_HOST=central-colt-14211.upstash.io
REDIS_PORT=6379
REDIS_TOKEN=your_kv_rest_api_token_here
```

### Connection Issues
- Check your host, port, and token values
- Verify your Upstash token is correct
- Ensure your network allows outbound connections to port 6379
- Make sure you're using the correct host (e.g., `central-colt-14211.upstash.io`)

### TLS Certificate Issues
The `--tls` flag handles certificate validation. If you have issues:
```bash
# Skip certificate verification (not recommended for production)
docker run -it --rm redis:alpine redis-cli --tls --insecure -u "$REDIS_URL"
```

## Advanced Usage

### Executing Scripts Inside Docker Container

You can run custom scripts inside the Docker container with full access to Redis CLI and additional tools:

```bash
# Execute a script inside the container
./scripts/redis-cli-wrapper.sh --script scripts/example-redis-script.sh

# Or use the short form
./scripts/redis-cli-wrapper.sh -s scripts/example-redis-script.sh
```

**Benefits of script execution inside container:**
- **Consistent environment**: Same tools and Redis CLI version
- **TLS support**: Always available in the container
- **Additional tools**: bash, curl, jq are automatically installed
- **Environment variables**: Redis connection details are automatically set
- **Volume mounting**: Your project files are accessible at `/workspace`

**Available environment variables in your script:**
```bash
REDIS_HOST=central-colt-14211.upstash.io
REDIS_PORT=6379
REDIS_TOKEN=your_token_here
REDIS_URL=redis://default:token@host:port
```

**Example script usage:**
```bash
#!/bin/bash
# Your script can use redis-cli directly
redis-cli --tls -u "$REDIS_URL" set "mykey" "myvalue"
redis-cli --tls -u "$REDIS_URL" get "mykey"

# Or use environment variables
echo "Connecting to $REDIS_HOST:$REDIS_PORT"
```

### Custom Redis Commands

```bash
# Scan keys with pattern
./scripts/redis-cli-wrapper.sh --scan --pattern "user:*"

# Get server info
./scripts/redis-cli-wrapper.sh info

# Get memory usage
./scripts/redis-cli-wrapper.sh info memory

# Flush all data (be careful!)
./scripts/redis-cli-wrapper.sh flushall
```

### Working with Lists

```bash
# Push to list
./scripts/redis-cli-wrapper.sh lpush mylist "item1"
./scripts/redis-cli-wrapper.sh lpush mylist "item2"

# Pop from list
./scripts/redis-cli-wrapper.sh lpop mylist

# Get list length
./scripts/redis-cli-wrapper.sh llen mylist

# Get all items in list
./scripts/redis-cli-wrapper.sh lrange mylist 0 -1
```

### Working with Sets

```bash
# Add to set
./scripts/redis-cli-wrapper.sh sadd myset "member1"
./scripts/redis-cli-wrapper.sh sadd myset "member2"

# Get set members
./scripts/redis-cli-wrapper.sh smembers myset

# Check if member exists
./scripts/redis-cli-wrapper.sh sismember myset "member1"
```

## Benefits Over Local Installation

| Aspect | Local Installation | Docker |
|--------|-------------------|---------|
| Setup | Complex, OS-specific | Simple, universal |
| Updates | Manual, version conflicts | Automatic, isolated |
| Dependencies | System-wide | Containerized |
| Portability | Limited | Universal |
| Cleanup | Manual | Automatic |

## Next Steps

1. **Explore Redis commands**: Try different Redis data types and commands
2. **Create scripts**: Build automation scripts using the wrapper
3. **Monitor performance**: Use Redis INFO commands to monitor your database
4. **Backup data**: Learn about Redis persistence and backup strategies

## Resources

- [Redis Commands Reference](https://redis.io/commands/)
- [Docker Documentation](https://docs.docker.com/)
- [Upstash Redis Documentation](https://docs.upstash.com/redis)
- [Redis CLI Guide](https://redis.io/topics/rediscli) 