#!/bin/bash

# This script is intended to be run on a Termux instance to fix SSH agent issues.

# Step 1: Update Termux and Install Essential Packages
echo "Updating Termux packages and installing libfido2 and termux-services..."
pkg update && pkg upgrade -y && pkg install -y libfido2 termux-services

# Step 2: Enable the ssh-agent Service
echo "Enabling the ssh-agent service..."
sv-enable ssh-agent

# Step 3: Configure Your Shell
echo "Adding SSH_AUTH_SOCK to your .bashrc..."
echo 'export SSH_AUTH_SOCK="$PREFIX/var/run/ssh-agent.sock"' >> ~/.bashrc

echo "
# Step 4: Disable Battery Optimization for Termux
# This is a manual step that you need to perform in your phone's settings.
# 1. Go to your phone's Settings -> Apps -> See all apps -> Termux -> App battery usage.
# 2. Set the battery usage to 'Unrestricted'.
# This will help prevent Android from killing the ssh-agent and sshd processes.

# After running this script, please restart your Termux session for the changes to take effect.
"
