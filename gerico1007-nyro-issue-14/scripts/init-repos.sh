#!/bin/bash

# Repository initialization script
# Clones all specified repositories and sets up dependencies

set -e

echo "🚀 Initializing G.Music Assembly Workspace..."

# Setup SSH for GitHub
echo "🔐 Configuring SSH for GitHub..."
mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || echo "SSH key scanning completed"

# Repository definitions
declare -A REPOS=(
    ["EchoNexus"]="git@github.com:jgwill/EchoNexus.git"
    ["orpheus"]="git@github.com:jgwill/orpheus.git"
    ["edgehub"]="git@github.com:jgwill/edgehub.git"
    ["EchoThreads"]="git@github.com:jgwill/EchoThreads.git"
    ["ea"]="git@github.com:Gerico1007/ea.git"
    ["CreerSaVieHelper"]="git@github.com:jgwill/CreerSaVieHelper.git"
    ["whitefeathers"]="git@github.com:jgwill/whitefeathers.git"
    ["tushell"]="git@github.com:jgwill/tushell.git"
    ["nyro"]="git@github.com:Gerico1007/nyro.git"
    ["Jamai-core"]="git@github.com:Gerico1007/Jamai-core.git"
    ["nyroportal"]="git@github.com:Gerico1007/nyroportal.git"
    ["SharedSpark"]="git@github.com:gmusic1007/SharedSpark.git"
)

cd /workspace

# Clone repositories
for repo_name in "${!REPOS[@]}"; do
    repo_url="${REPOS[$repo_name]}"
    echo "🔄 Cloning $repo_name..."
    
    if [ ! -d "$repo_name" ]; then
        git clone "$repo_url" "$repo_name"
    else
        echo "  ✅ $repo_name already exists, skipping clone"
    fi
    
    # Setup dependencies
    cd "$repo_name"
    
    if [ -f "pyproject.toml" ]; then
        echo "  📦 Installing Poetry dependencies for $repo_name..."
        poetry install --no-root 2>/dev/null || echo "  ⚠️  Poetry install failed for $repo_name"
    elif [ -f "requirements.txt" ]; then
        echo "  📦 Installing pip dependencies for $repo_name..."
        pip install -r requirements.txt || echo "  ⚠️  Pip install failed for $repo_name"
    else
        echo "  ℹ️  No Python dependencies found for $repo_name"
    fi
    
    cd /workspace
done

echo "✅ All repositories initialized successfully!"
echo "🎼 G.Music Assembly Workspace ready for orchestration"