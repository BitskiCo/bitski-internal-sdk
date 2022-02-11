# syntax=docker/dockerfile:1

ARG RUST_BASE=base
ARG DEVCONTAINER_BASE=rust

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ARG OC_VERSION
ARG RUST_VERSION
ARG ZSH_VERSION

ARG DEFAULT_SHELL=/bin/zsh

#############################################################################
# Base container                                                            #
#############################################################################
FROM registry.access.redhat.com/ubi8/ubi AS base

# Install system dependencies
RUN --mount=target=/usr/local/bin/setup-ubi.sh,source=bin/setup-ubi.sh \
    --mount=type=cache,target=/var/cache/yum \
    setup-ubi.sh

#############################################################################
# Rust SDK container                                                        #
#############################################################################
FROM $RUST_BASE AS rust

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
RUN --mount=type=cache,target=/var/cache/cargo \
    CARGO_HOME=/var/cache/cargo \
    su $USERNAME -c \
    'cargo install --no-default-features --features postgres --root /usr/local/cargo diesel_cli'

#############################################################################
# Devcontainer container                                                    #
#############################################################################
FROM $DEVCONTAINER_BASE AS devcontainer

ENV SHELL=$DEFAULT_SHELL

# Always sign Git commits
RUN git config --system commit.gpgsign true

# Install zsh
RUN --mount=target=/usr/local/bin/setup-zsh.sh,source=bin/setup-zsh.sh \
    --mount=type=cache,target=/tmp/zsh \
    setup-zsh.sh

# Setup GitHub Codespaces themes
RUN --mount=target=/usr/local/bin/setup-codespaces.sh,source=bin/setup-codespaces.sh \
    setup-codespaces.sh

# Install OpenShift CLI
RUN --mount=target=/usr/local/bin/setup-oc.sh,source=bin/setup-oc.sh \
    --mount=type=cache,target=/tmp/oc \
    setup-oc.sh

USER $USERNAME
WORKDIR /workspace
