# syntax=docker/dockerfile:1

ARG RUNTIME_BASE=registry.access.redhat.com/ubi8/ubi

ARG DEVCONTAINER_BASE=rust
ARG RUST_BASE=runtime

#############################################################################
# Base container                                                            #
#############################################################################
FROM $RUNTIME_BASE AS runtime

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install system dependencies
RUN --mount=target=/usr/local/bin/setup-ubi.sh,source=bin/setup-ubi.sh \
    --mount=type=cache,target=/var/cache/yum \
    setup-ubi.sh

#############################################################################
# Rust SDK container                                                        #
#############################################################################
FROM $RUST_BASE AS rust

ARG RUST_VERSION

# Configure sccache
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG SCCACHE_BUCKET
ARG SCCACHE_S3_USE_SSL
ARG RUSTC_WRAPPER

ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH=${CARGO_HOME}/bin:$PATH

# Install Rust toolchains
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
RUN --mount=target=/usr/local/bin/setup-rust.sh,source=bin/setup-rust.sh \
    --mount=type=cache,target=/tmp/rustup \
    --mount=type=cache,target=/var/cache/yum \
    setup-rust.sh

# Install cargo-cache
RUN --mount=type=cache,target=/var/cache/cargo \
    CARGO_HOME=/var/cache/cargo \
    cargo install --root /usr/local \
    --target-dir /var/cache/cargo/target cargo-cache

# Install Diesel client
RUN --mount=type=cache,target=/var/cache/cargo \
    CARGO_HOME=/var/cache/cargo \
    cargo install --no-default-features --features postgres \
    --root /usr/local --target-dir /var/cache/cargo/target diesel_cli

#############################################################################
# Devcontainer container                                                    #
#############################################################################
FROM $DEVCONTAINER_BASE AS devcontainer

ARG DEFAULT_SHELL=/usr/local/bin/zsh

ARG DOCKER_COMPOSE_VERSION
ARG OC_VERSION
ARG ZSH_VERSION

ENV SHELL=$DEFAULT_SHELL
ENV DOCKER_BUILDKIT=1

# Always sign Git commits
RUN git config --system commit.gpgsign true

# Install Docker
RUN --mount=target=/usr/local/bin/setup-docker.sh,source=bin/setup-docker.sh \
    --mount=type=cache,target=/tmp/docker \
    setup-docker.sh

# Install OpenShift CLI
RUN --mount=target=/usr/local/bin/setup-oc.sh,source=bin/setup-oc.sh \
    --mount=type=cache,target=/tmp/oc \
    setup-oc.sh

# Install zsh
RUN --mount=target=/usr/local/bin/setup-zsh.sh,source=bin/setup-zsh.sh \
    --mount=type=cache,target=/tmp/zsh \
    setup-zsh.sh

# Setup GitHub Codespaces themes
RUN --mount=target=/usr/local/bin/setup-codespaces.sh,source=bin/setup-codespaces.sh \
    setup-codespaces.sh

USER $USERNAME
WORKDIR /workspace
