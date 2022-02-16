# syntax=docker/dockerfile:1

ARG RUNTIME_BASE=registry.access.redhat.com/ubi8/ubi

ARG DEVCONTAINER_BASE=rust
ARG RUST_BASE=runtime

#############################################################################
# Base container                                                            #
#############################################################################
FROM $RUNTIME_BASE AS runtime

ARG SCCACHE_VERSION

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure cache
ARG SDK_WORKDIR=/tmp/bitski-internal-sdk

# Install system dependencies
RUN --mount=target=/usr/local/bin/setup-ubi.sh,source=bin/setup-ubi.sh \
    --mount=type=cache,target=/var/cache/yum \
    setup-ubi.sh

# Install sccache
RUN --mount=target=/usr/local/bin/setup-sccache.sh,source=bin/setup-sccache.sh \
    --mount=type=cache,target=$SDK_WORKDIR \
    setup-sccache.sh

#############################################################################
# Rust SDK container                                                        #
#############################################################################
FROM $RUST_BASE AS rust

ARG RUST_VERSION

# Configure cache
ARG SDK_WORKDIR=/tmp/bitski-internal-sdk

# Configure sccache
ARG RUSTC_WRAPPER=sccache
ARG SCCACHE_DIR=/var/cache/sccache
ARG SCCACHE_CACHE_SIZE=2G
# sccache in AWS S3
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_IAM_CREDENTIALS_URL
ARG SCCACHE_BUCKET
ARG SCCACHE_ENDPOINT
ARG SCCACHE_S3_USE_SSL
# sccache in Redis
ARG SCCACHE_REDIS
# sccache in Memcached
ARG SCCACHE_MEMCACHED
# sccache in Google Cloud Storage
ARG SCCACHE_GCS_BUCKET
ARG SCCACHE_GCS_KEY_PATH
ARG SCCACHE_GCS_OAUTH_URL
ARG SCCACHE_GCS_RW_MODE
ARG SCCACHE_GCS_KEY_PREFIX

# Install Rust toolchains
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH=${CARGO_HOME}/bin:$PATH
RUN --mount=target=/usr/local/bin/setup-rust.sh,source=bin/setup-rust.sh \
    --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    --mount=type=cache,target=$SCCACHE_DIR \
    --mount=type=cache,target=/var/cache/yum \
    setup-rust.sh

# Install cargo-cache
RUN --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    --mount=type=cache,target=$SCCACHE_DIR \
    cargo install --root /usr/local \
    --target-dir $SDK_WORKDIR/target cargo-cache

# Install Diesel client
RUN --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    --mount=type=cache,target=$SCCACHE_DIR \
    cargo install --root /usr/local \
    --no-default-features --features postgres \
    --target-dir $SDK_WORKDIR/target diesel_cli

#############################################################################
# Devcontainer container                                                    #
#############################################################################
FROM $DEVCONTAINER_BASE AS devcontainer

ARG DEFAULT_SHELL=/usr/local/bin/zsh
ARG USERNAME

ARG DOCKER_COMPOSE_VERSION
ARG OC_VERSION
ARG ZSH_VERSION

# Configure cache
ARG SDK_WORKDIR=/tmp/bitski-internal-sdk

# Configure sccache
ARG SCCACHE_DIR=/var/cache/sccache
ARG SCCACHE_CACHE_SIZE=2G
# sccache in AWS S3
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_IAM_CREDENTIALS_URL
ARG SCCACHE_BUCKET
ARG SCCACHE_ENDPOINT
ARG SCCACHE_S3_USE_SSL
# sccache in Redis
ARG SCCACHE_REDIS
# sccache in Memcached
ARG SCCACHE_MEMCACHED
# sccache in Google Cloud Storage
ARG SCCACHE_GCS_BUCKET
ARG SCCACHE_GCS_KEY_PATH
ARG SCCACHE_GCS_OAUTH_URL
ARG SCCACHE_GCS_RW_MODE
ARG SCCACHE_GCS_KEY_PREFIX

ENV SHELL=$DEFAULT_SHELL
ENV DOCKER_BUILDKIT=1
ENV RUSTC_WRAPPER=sccache

# Always sign Git commits
RUN git config --system commit.gpgsign true

# Install Docker
RUN --mount=target=/usr/local/bin/setup-docker.sh,source=bin/setup-docker.sh \
    --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$SCCACHE_DIR \
    --mount=type=cache,target=/var/cache/yum \
    setup-docker.sh

# Install OpenShift CLI
RUN --mount=target=/usr/local/bin/setup-oc.sh,source=bin/setup-oc.sh \
    --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$SCCACHE_DIR \
    env CC=sccache-cc setup-oc.sh

# Install zsh
RUN --mount=target=/usr/local/bin/setup-zsh.sh,source=bin/setup-zsh.sh \
    --mount=type=cache,target=$SDK_WORKDIR \
    --mount=type=cache,target=$SCCACHE_DIR \
    env CC=sccache-cc setup-zsh.sh

# Setup GitHub Codespaces themes
RUN --mount=target=/usr/local/bin/setup-codespaces.sh,source=bin/setup-codespaces.sh \
    setup-codespaces.sh

USER $USERNAME
WORKDIR /workspace
