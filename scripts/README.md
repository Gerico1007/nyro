# Redis Scripts

This directory contains bash scripts for interacting with Redis via REST API.

## Configuration

All scripts use the `KV_REST_API_URL` variable from the `.env` file for the Redis REST API endpoint. 

### Setup

1. **Copy the .env.example file** (if it exists) to create your `.env` file:
   ```bash
   cp ../.env.example ../.env
   ```

2. **Edit the .env file** and set your Redis configuration:
   ```
   KV_REST_API_URL="https://your-instance.upstash.io"
   KV_REST_API_TOKEN="your-rest-token"
   ```

3. **Run the setup script** to configure your environment:
   ```bash
   ./setup-env.sh
   ```

### Required Variables

The following variables must be defined in your `.env` file:
- `KV_REST_API_URL` - Your Redis REST API endpoint (e.g., "https://your-instance.upstash.io")
- `KV_REST_API_TOKEN` - Your Redis REST API token

## Available Scripts

- `del-key.sh` - Delete a key
- `get-key.sh` - Get a key's value
- `set-key.sh` - Set a key's value
- `push-list.sh` - Push to a list
- `read-list.sh` - Read from a list
- `scan-garden.sh` - Scan keys with pattern
- `stream-add.sh` - Add to a stream
- `stream-read.sh` - Read from a stream
- `menu.sh` - Interactive menu
- `setup-env.sh` - Setup environment variables

## Usage Examples

```bash
# Make sure your .env file is configured first
./set-key.sh mykey myvalue
./get-key.sh mykey
./del-key.sh mykey
```

## Troubleshooting

If you get errors about undefined variables, make sure:
1. Your `.env` file exists in the parent directory
2. `KV_REST_API_URL` and `KV_REST_API_TOKEN` are properly defined in the `.env` file
3. The `.env` file is being sourced correctly (all scripts should do this automatically) 