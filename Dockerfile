# Dockerfile for GitHub Actions self-hosted runner
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    jq \
    git \
    libicu70 \
    iputils-ping \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Download and extract GitHub Actions runner with the root user
ARG RUNNER_VERSION="2.325.0"
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Install runner dependencies with the root user
# This step requires root privileges and must be done before switching users.
# RUN ./bin/installdependencies.sh
RUN ./bin/installdependencies.sh

# Create the non-root user and switch to it for all subsequent commands.
RUN groupadd -r githubrunner && useradd -r -g githubrunner -m -s /bin/bash githubrunner
USER githubrunner

# Set the working directory for the non-root user
WORKDIR /home/githubrunner

# Create the workspace directory for the runner
RUN mkdir -p /home/githubrunner/_work

# Copy entrypoint script and set ownership
COPY --chown=githubrunner:githubrunner --chmod=755 entrypoint.sh entrypoint.sh

# Set environment variables
ENV GITHUB_RUNNER_URL=""
ENV GITHUB_RUNNER_TOKEN=""
ENV GITHUB_RUNNER_NAME="HausOfMTORunner"
ENV GITHUB_RUNNER_LABELS="Linux,X64,self-hosted"

ENTRYPOINT ["./entrypoint.sh"]
