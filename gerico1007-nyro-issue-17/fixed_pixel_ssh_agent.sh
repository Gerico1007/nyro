#!/bin/bash

# Pixel SSH Agent - Android-Compatible SSH Agent Solution
# ♠️🌿🎸🧵 G.Music Assembly Mode - Issue #17
# Designed for Google Pixel devices running Android 14+

echo "🎸 Pixel SSH Agent - Android-Compatible Solution"
echo "♠️🌿🎸🧵 G.Music Assembly Mode Active"

# Step 1: Create Android-compatible SSH key storage
echo "♠️ Creating Android-compatible SSH key storage..."
mkdir -p ~/.ssh/pixel-agent
chmod 700 ~/.ssh/pixel-agent

# Step 2: Create persistent SSH agent using file-based approach
echo "🌿 Creating persistent SSH agent with file-based persistence..."
cat > ~/.ssh/pixel-agent/agent-wrapper.sh << 'EOF'
#!/bin/bash
# Pixel SSH Agent Wrapper - Survives Android process management

AGENT_FILE="$HOME/.ssh/pixel-agent/agent-env"
AGENT_PID_FILE="$HOME/.ssh/pixel-agent/agent.pid"

start_agent() {
    # Kill any existing agent
    if [ -f "$AGENT_PID_FILE" ]; then
        kill $(cat "$AGENT_PID_FILE") 2>/dev/null
    fi
    
    # Start new agent with Android-compatible settings
    ssh-agent -s > "$AGENT_FILE"
    source "$AGENT_FILE" >/dev/null 2>&1
    echo $SSH_AGENT_PID > "$AGENT_PID_FILE"
    
    # Set relaxed permissions for Android compatibility
    chmod 600 "$AGENT_FILE"
    chmod 600 "$AGENT_PID_FILE"
    
    >&2 echo "🎸 SSH Agent started with PID: $SSH_AGENT_PID"
    >&2 echo "🧵 Agent socket: $SSH_AUTH_SOCK"
}

load_agent() {
    if [ -f "$AGENT_FILE" ]; then
        source "$AGENT_FILE" >/dev/null 2>&1
        
        # Verify agent is still running
        if ! kill -0 $SSH_AGENT_PID 2>/dev/null; then
            >&2 echo "🌿 Agent died, restarting..."
            start_agent
        else
            >&2 echo "♠️ Agent alive with PID: $SSH_AGENT_PID"
        fi
    else
        >&2 echo "🎸 No agent found, starting new one..."
        start_agent
    fi
    cat "$AGENT_FILE"
}

case "$1" in
    start)
        start_agent
        ;;
    load)
        load_agent
        ;;
    stop)
        if [ -f "$AGENT_PID_FILE" ]; then
            kill $(cat "$AGENT_PID_FILE") 2>/dev/null
            rm -f "$AGENT_FILE" "$AGENT_PID_FILE"
            >&2 echo "🧵 SSH Agent stopped"
        fi
        ;;
    status)
        if [ -f "$AGENT_FILE" ]; then
            source "$AGENT_FILE" >/dev/null 2>&1
            if kill -0 $SSH_AGENT_PID 2>/dev/null; then
                >&2 echo "♠️ SSH Agent running (PID: $SSH_AGENT_PID)"
            else
                >&2 echo "🌿 SSH Agent not running"
            fi
        else
            >&2 echo "🎸 No SSH Agent configured"
        fi
        ;;
    *)
        >&2 echo "Usage: $0 {start|load|stop|status}"
        ;;
esac
EOF

chmod +x ~/.ssh/pixel-agent/agent-wrapper.sh

# Step 3: Create shell integration for persistent agent
echo "🧵 Creating shell integration for persistent SSH agent..."
cat > ~/.ssh/pixel-agent/shell-integration.sh << 'EOF'
# Pixel SSH Agent Shell Integration
# Add this to your .bashrc or .zshrc

# Auto-load SSH agent on shell startup
if [ -f "$HOME/.ssh/pixel-agent/agent-wrapper.sh" ]; then
    eval $("$HOME/.ssh/pixel-agent/agent-wrapper.sh" load)
fi

# Convenient aliases
alias ssh-agent-start='$HOME/.ssh/pixel-agent/agent-wrapper.sh start'
alias ssh-agent-stop='$HOME/.ssh/pixel-agent/agent-wrapper.sh stop'
alias ssh-agent-status='$HOME/.ssh/pixel-agent/agent-wrapper.sh status'
alias ssh-agent-reload='eval $("$HOME/.ssh/pixel-agent/agent-wrapper.sh" load)'
EOF

# Step 4: Update packages for modern SSH support
echo "🎸 Updating packages for modern SSH key support..."
pkg update && pkg upgrade -y
pkg install -y openssh libfido2 termux-services

# Step 5: Add shell integration to .bashrc
echo "♠️ Adding shell integration to .bashrc..."
if ! grep -q "pixel-agent/shell-integration.sh" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Pixel SSH Agent Integration" >> ~/.bashrc
    echo "source ~/.ssh/pixel-agent/shell-integration.sh" >> ~/.bashrc
fi

# Step 6: Create modern SSH key support script
echo "🌿 Creating modern SSH key support script..."
cat > ~/.ssh/pixel-agent/modern-keys.sh << 'EOF'
#!/bin/bash
# Modern SSH Key Support for Pixel

echo "🎸 Modern SSH Key Support"

# Generate ed25519 key (recommended for modern servers)
generate_ed25519() {
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    echo "♠️ Generated ed25519 key: ~/.ssh/id_ed25519"
}

# Generate RSA key with modern length
generate_rsa() {
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "🌿 Generated RSA 4096 key: ~/.ssh/id_rsa"
}

# Add all keys to agent
add_all_keys() {
    eval $("$HOME/.ssh/pixel-agent/agent-wrapper.sh" load)
    
    for key in ~/.ssh/id_*; do
        if [[ -f "$key" && ! "$key" =~ \.pub$ ]]; then
            ssh-add "$key" 2>/dev/null && echo "🧵 Added key: $key"
        fi
    done
}

# Add AWS key to agent
add_aws_key() {
    /data/data/com.termux/files/home/src/nyro/gerico1007-nyro-issue-17/add_aws_key.sh
}

case "$1" in
    ed25519)
        generate_ed25519
        ;;
    rsa)
        generate_rsa
        ;;
    add-all)
        add_all_keys
        ;;
    add-aws)
        add_aws_key
        ;;
    *)
        echo "Usage: $0 {ed25519|rsa|add-all|add-aws}"
        echo "🎸 ed25519: Generate modern ed25519 key"
        echo "🌿 rsa: Generate RSA 4096 key"
        echo "🧵 add-all: Add all keys to agent"
        echo "🔑 add-aws: Add AWS PEM key to agent"
        ;;
esac
EOF

chmod +x ~/.ssh/pixel-agent/modern-keys.sh

echo ""
echo "🎸 Pixel SSH Agent Installation Complete!"
echo "♠️🌿🎸🧵 G.Music Assembly Mode - Next Steps:"
echo ""
echo "1. Restart your Termux session or run:"
echo "   source ~/.bashrc"
echo ""
echo "2. Generate modern SSH keys:"
echo "   ~/.ssh/pixel-agent/modern-keys.sh ed25519"
echo ""
echo "3. Add keys to agent:"
echo "   ~/.ssh/pixel-agent/modern-keys.sh add-all"
echo ""
echo "4. Add your AWS key:"
echo "   ~/.ssh/pixel-agent/modern-keys.sh add-aws"
echo ""
echo "5. Check agent status:"
echo "   ssh-agent-status"
echo ""
echo "🧵 This solution bypasses Android security restrictions by:"
echo "- Using file-based agent persistence"
echo "- Automatic agent restart on shell startup"
echo "- Modern SSH key format support"
echo "- Android-compatible permission handling"
