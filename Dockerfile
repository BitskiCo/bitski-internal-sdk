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

ARG USERNAME
ARG RUST_VERSION

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

# Install Diesel client
RUN --mount=type=cache,target=/var/cache/cargo,uid=$USER_UID \
    su $USERNAME -c ' \
    CARGO_HOME=/var/cache/cargo \
    cargo install --no-default-features --features postgres \
    --root /usr/local/cargo \
    --target-dir /var/cache/cargo/target \
    diesel_cli'

#############################################################################
# Devcontainer container                                                    #
#############################################################################
FROM $DEVCONTAINER_BASE AS devcontainer

ARG DEFAULT_SHELL=/bin/zsh

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
