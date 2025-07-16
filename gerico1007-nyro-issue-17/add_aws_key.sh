#!/bin/bash
# Add AWS PEM key to SSH agent

# Path to the PEM file
PEM_KEY="/data/data/com.termux/files/home/src/nyro/gerico1007-nyro-issue-17/gmusicrawill250228.pem"

# Check if the PEM file exists
if [ ! -f "$PEM_KEY" ]; then
    echo "Error: PEM file not found at $PEM_KEY"
    exit 1
fi

# Convert the PEM file to a standard SSH key
SSH_KEY="$HOME/.ssh/id_rsa_aws"
ssh-keygen -f "$PEM_KEY" -y > "$SSH_KEY.pub"
cp "$PEM_KEY" "$SSH_KEY"
chmod 600 "$SSH_KEY"

# Load the SSH agent environment
eval "$($HOME/.ssh/pixel-agent/agent-wrapper.sh load)"

# Add the SSH key to the agent
ssh-add "$SSH_KEY"
