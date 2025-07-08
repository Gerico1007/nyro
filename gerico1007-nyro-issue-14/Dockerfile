FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Configure Poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Create workspace directory
WORKDIR /workspace

# Copy initialization script
COPY scripts/init-repos.sh /usr/local/bin/init-repos.sh
RUN chmod +x /usr/local/bin/init-repos.sh

# Set default command
CMD ["/bin/bash"]