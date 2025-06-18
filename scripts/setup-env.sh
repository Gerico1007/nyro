#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Setting up Redis environment..."

# Check if .env exists
if [ ! -f "${SCRIPT_DIR}/../.env" ]; then
    echo "Creating new .env file..."
    cp "${SCRIPT_DIR}/../.env.example" "${SCRIPT_DIR}/../.env"
fi

# Interactive setup
echo "Please enter your Redis credentials (press Enter to skip and edit manually later):"
echo "For Upstash, the format is typically:"
echo "  Host: your-instance.upstash.io"
echo "  Port: 6379"
echo "  User: default"
echo "  Database: 0"
echo ""

read -p "Redis Host (e.g., your-instance.upstash.io): " redis_host
read -p "Redis Port [6379]: " redis_port
read -p "Redis User [default]: " redis_user
read -p "Redis Database [0]: " redis_db
read -s -p "Redis Password: " redis_pass
echo ""
read -p "Using SSL? [Y/n]: " use_ssl

# Set defaults
redis_port=${redis_port:-6379}
redis_user=${redis_user:-default}
redis_db=${redis_db:-0}
use_ssl=${use_ssl:-Y}

# Determine protocol based on SSL preference
if [[ "${use_ssl,,}" =~ ^(y|yes)$ ]]; then
    protocol="rediss"
else
    protocol="redis"
fi

read -p "Redis REST URL (e.g., https://your-instance.upstash.io): " rest_url
read -s -p "Redis REST Token: " rest_token
echo ""

# Only update if values are provided
if [ ! -z "$redis_host" ]; then
    # Create the Redis URL safely
    REDIS_URL="${protocol}://${redis_user}:${redis_pass}@${redis_host}:${redis_port}/${redis_db}"
    
    # Update the .env file using sed
    sed -i "s#^REDIS_URL=.*#REDIS_URL=\"${REDIS_URL}\"#" "${SCRIPT_DIR}/../.env"
    sed -i "s#^UPSTASH_REDIS_HOST=.*#UPSTASH_REDIS_HOST=\"${redis_host}\"#" "${SCRIPT_DIR}/../.env"
    sed -i "s#^UPSTASH_REDIS_PORT=.*#UPSTASH_REDIS_PORT=${redis_port}#" "${SCRIPT_DIR}/../.env"
    sed -i "s#^UPSTASH_REDIS_PASSWORD=.*#UPSTASH_REDIS_PASSWORD=\"${redis_pass}\"#" "${SCRIPT_DIR}/../.env"
    
    if [ ! -z "$rest_url" ]; then
        sed -i "s#^UPSTASH_REDIS_REST_URL=.*#UPSTASH_REDIS_REST_URL=\"${rest_url}\"#" "${SCRIPT_DIR}/../.env"
    fi
    if [ ! -z "$rest_token" ]; then
        sed -i "s#^UPSTASH_REDIS_REST_TOKEN=.*#UPSTASH_REDIS_REST_TOKEN=\"${rest_token}\"#" "${SCRIPT_DIR}/../.env"
    fi
    
    echo "Environment variables updated successfully!"
else
    echo "No values provided. Please edit .env file manually."
fi

echo ""
echo "Next steps:"
echo "1. Review your .env file to ensure all values are correct"
echo "2. Make sure .env is added to .gitignore"
echo "3. Never commit your .env file to version control"
