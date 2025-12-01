#!/bin/bash

# G.Music Assembly - AWS Cloud Deployment Script
# ♠️🌿🎸🧵 Secure Global Access Setup

set -e

echo "🌐 G.Music Assembly - AWS Cloud Deployment"
echo "♠️🌿🎸🧵 Setting up global secure access..."

# Configuration
AWS_IP="${1:-your-aws-ip}"
AWS_KEY="${2:-your-aws-key.pem}"
AWS_USER="${3:-ubuntu}"

if [ "$AWS_IP" = "your-aws-ip" ]; then
    echo "Usage: $0 <aws-ip> <aws-key.pem> [aws-user]"
    echo "Example: $0 18.223.xxx.xxx ~/.ssh/aws-key.pem ubuntu"
    exit 1
fi

echo "🚀 Step 1: Creating deployment package..."
tar -czf gmusic-assembly-aws.tar.gz \
    docker-compose.yml \
    Dockerfile \
    Makefile \
    .env.example \
    scripts/ \
    SECURITY.md \
    DEPLOYMENT_GUIDE.md \
    CLAUDE.md \
    testing/ \
    assembly_session_melody.abc \
    workspace/README.md

echo "📦 Step 2: Transferring to AWS..."
scp -i "$AWS_KEY" gmusic-assembly-aws.tar.gz "$AWS_USER@$AWS_IP:/home/$AWS_USER/"

echo "🔧 Step 3: Setting up AWS environment..."
ssh -i "$AWS_KEY" "$AWS_USER@$AWS_IP" << 'EOF'
    # Update system
    sudo apt update
    sudo apt install -y docker.io docker-compose git curl

    # Setup Docker
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker

    # Extract deployment
    tar -xzf gmusic-assembly-aws.tar.gz
    cd gmusic-assembly-aws/

    # Generate SSH key for GitHub
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -C "aws-gmusic-$(date +%Y%m%d)" -N "" -f ~/.ssh/id_rsa
        echo "🔑 Generated SSH key. Add this to GitHub:"
        cat ~/.ssh/id_rsa.pub
        echo ""
        echo "Press Enter after adding the key to GitHub..."
        read
    fi

    # Test GitHub access
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    ssh -T git@github.com || echo "GitHub SSH access configured"

    echo "🏗️ Building G.Music Assembly environment..."
    docker compose build

    echo "📦 Initializing repositories..."
    docker compose run --rm dev /usr/local/bin/init-repos.sh

    echo "✅ AWS deployment complete!"
    echo "🎼 G.Music Assembly ready for global access"
EOF

echo "🌐 Step 4: Setting up secure access options..."

cat << EOF

🎉 AWS Deployment Complete!

🔐 Secure Access Options:

1. 📡 SSH Tunneling (Immediate):
   ssh -i $AWS_KEY -L 8080:localhost:8080 $AWS_USER@$AWS_IP
   # Then run: docker compose run --rm -p 8080:8080 dev
   # Access via: http://localhost:8080

2. 🌐 Tailscale (Recommended for permanent access):
   # On AWS:
   ssh -i $AWS_KEY $AWS_USER@$AWS_IP
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   
   # On your devices: Install Tailscale and connect to same network
   # Access via Tailscale IP: tailscale ssh aws-gmusic

3. 💻 Direct SSH Development:
   ssh -i $AWS_KEY $AWS_USER@$AWS_IP
   cd gmusic-assembly-aws
   make shell-nyro

🎼 Montreal Commands:
   make assembly-status    # Check system status
   make shell-<repo>      # Access any repository
   make start-all         # Start all services

🧵 Security: All repositories are securely mounted with SSH keys
🌿 Persistence: All changes saved in AWS workspace
🎸 Performance: Optimized for cloud deployment

Ready for global G.Music Assembly orchestration! 🌍🎵

EOF