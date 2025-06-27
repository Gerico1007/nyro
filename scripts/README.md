# Redis Scripts

This directory contains bash scripts for interacting with Redis via Dockerized redis-cli.

## Configuration

All scripts use the `REDIS_URL` variable from the `.env` file for the Redis endpoint. 

### Setup

1. **Copy the .env.example file** (if it exists) to create your `.env` file:
   ```bash
   cp ../.env.example ../.env
   ```

2. **Edit the .env file** and set your Redis configuration:
   ```
   REDIS_URL="rediss://default:your-token@your-instance.upstash.io:6379"
   ```

3. **Run the setup script** to configure your environment:
   ```bash
   ./setup-env.sh
   ```

### Required Variables

The following variables must be defined in your `.env` file:
- `REDIS_URL` - Your Redis endpoint (e.g., "rediss://default:your-token@your-instance.upstash.io:6379")

## Usage Examples

- **Interactive menu:**
  ```bash
  ./redis-cli-wrapper.sh --script scripts/menu.sh
  ```
- **Direct script usage:**
  ```bash
  ./redis-cli-wrapper.sh --script scripts/set-key.sh mykey myvalue
  ./redis-cli-wrapper.sh --script scripts/get-key.sh mykey
  ./redis-cli-wrapper.sh --script scripts/del-key.sh mykey
  ```

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

## Troubleshooting

If you get errors about undefined variables, make sure:
1. Your `.env` file exists in the project root
2. `REDIS_URL` is properly defined in the `.env` file
3. The `.env` file is being sourced correctly (all scripts do this automatically)

## Dockerized Usage

All scripts are intended to be run via the Dockerized wrapper:
```bash
./redis-cli-wrapper.sh --script scripts/menu.sh
```
This ensures you do not need to install redis-cli locally. 