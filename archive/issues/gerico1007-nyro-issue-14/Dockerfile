FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    openssh-client \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create ubuntu user with UID 1000
RUN groupadd -g 1000 ubuntu && \
    useradd -u 1000 -g 1000 -m -s /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Poetry
RUN pip install poetry

# Configure Poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Create workspace directory and set ownership
WORKDIR /workspace
RUN chown -R ubuntu:ubuntu /workspace

# Copy initialization script
COPY scripts/init-repos.sh /usr/local/bin/init-repos.sh
RUN chmod +x /usr/local/bin/init-repos.sh

# Switch to ubuntu user
USER ubuntu

# Set default command
CMD ["/bin/bash"]