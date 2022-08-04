# syntax=docker/dockerfile:1

ARG DEVCONTAINER_BASE=mcr.microsoft.com/vscode/devcontainers/universal:latest
ARG DOWNLOAD_BUILDER_BASE=debian:buster-slim
ARG DOWNLOAD_BIN_BASE=download-builder
ARG OPENSHIFT_BUILDER_BASE=registry.access.redhat.com/ubi8/ubi-minimal
ARG OPENSHIFT_BIN_BASE=openshift-builder
ARG RUST_BUILDER_BASE=rust:1-buster
ARG RUST_BASE=rust:1-buster

ARG CARGO_CACHE_BUILDER_BASE=rust-builder-runtime
ARG CARGO_CACHE_BIN_BASE=cargo-cache-builder
ARG CARGO_EDIT_BUILDER_BASE=rust-builder-runtime
ARG CARGO_EDIT_BIN_BASE=cargo-edit-builder
ARG CARGO_UDEPS_BUILDER_BASE=rust-builder-runtime
ARG CARGO_UDEPS_BIN_BASE=cargo-udeps-builder
ARG DIESEL_BUILDER_BASE=rust-builder-runtime
ARG DIESEL_BIN_BASE=diesel-builder

#############################################################################
# Download builder                                                          #
#############################################################################
FROM $DOWNLOAD_BUILDER_BASE AS download-builder-runtime

ARG DOCKLE_VERSION
ARG SCCACHE_VERSION
ARG TRIVY_VERSION

# Configure cache
ARG SDK_CACHE_DIR=/var/cache/bitski-internal-sdk

# Upgrade dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get upgrade -y

# Install dependencies
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install --no-install-recommends -y ca-certificates curl

# Download binaries
RUN --mount=target=/usr/local/bin/setup-downloads.sh,source=bin/setup-downloads.sh \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=$SDK_CACHE_DIR \
    setup-downloads.sh

FROM bufbuild/buf:1.6.0 AS download-buf

FROM scratch AS download-builder

COPY --from=download-builder-runtime /usr/local/bin/* /usr/local/bin/
COPY --from=download-buf /usr/local/bin/* /usr/local/bin/

FROM $DOWNLOAD_BIN_BASE AS download-bin

#############################################################################
# OpenShift binary builder                                                  #
#############################################################################
FROM $OPENSHIFT_BUILDER_BASE as openshift-builder-runtime

ARG OC_VERSION

# Configure cache
ARG SDK_CACHE_DIR=/var/cache/bitski-internal-sdk
ARG GOCACHE=/var/cache/golang

RUN --mount=type=cache,target=/var/cache/dnf \
    microdnf upgrade -y

# Install OpenShift CLI
RUN --mount=target=/usr/local/bin/setup-oc.sh,source=bin/setup-oc.sh \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=$SDK_CACHE_DIR \
    --mount=type=cache,target=$GOCACHE \
    setup-oc.sh

FROM scratch AS openshift-builder

COPY --from=openshift-builder-runtime \
    /usr/local/bin/oc \
    /usr/local/bin/
COPY --from=openshift-builder-runtime \
    /etc/bash_completion.d/oc \
    /etc/bash_completion.d/
COPY --from=openshift-builder-runtime \
    /usr/local/share/zsh/site-functions/oc \
    /usr/local/share/zsh/site-functions/

FROM $OPENSHIFT_BIN_BASE as openshift-bin

#############################################################################
# Rust binary builder                                                       #
#############################################################################
FROM $RUST_BUILDER_BASE AS rust-builder-runtime

# Upgrade dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get upgrade -y

#---------------------------------------------------------------------------#
FROM $CARGO_CACHE_BUILDER_BASE AS cargo-cache-builder-runtime

# Install cargo-cache
RUN --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    cargo install --root /usr/local cargo-cache

FROM scratch AS cargo-cache-builder

COPY --from=cargo-cache-builder-runtime /usr/local/bin/* /usr/local/bin/

FROM $CARGO_CACHE_BIN_BASE AS cargo-cache-bin

#---------------------------------------------------------------------------#
FROM $CARGO_EDIT_BUILDER_BASE AS cargo-edit-builder-runtime

# Install cargo-edit
RUN --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    cargo install --root /usr/local cargo-edit

FROM scratch AS cargo-edit-builder

COPY --from=cargo-edit-builder-runtime /usr/local/bin/* /usr/local/bin/

FROM $CARGO_EDIT_BIN_BASE AS cargo-edit-bin

#---------------------------------------------------------------------------#
FROM $CARGO_UDEPS_BUILDER_BASE AS cargo-udeps-builder-runtime

# Install cargo-udeps
RUN --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    cargo install --root /usr/local cargo-udeps

FROM scratch AS cargo-udeps-builder

COPY --from=cargo-cache-builder-runtime /usr/local/bin/* /usr/local/bin/

FROM $CARGO_UDEPS_BIN_BASE AS cargo-udeps-bin

#---------------------------------------------------------------------------#
FROM $DIESEL_BUILDER_BASE AS diesel-builder-runtime

# Install diesel
RUN --mount=type=cache,target=$CARGO_HOME/git \
    --mount=type=cache,target=$CARGO_HOME/registry \
    cargo install --root /usr/local \
    --no-default-features --features postgres diesel_cli

FROM scratch AS diesel-builder

COPY --from=diesel-builder-runtime \
    /usr/local/bin/diesel \
    /usr/local/bin/

FROM $DIESEL_BIN_BASE AS diesel-bin

#############################################################################
# Rust SDK                                                                  #
#############################################################################
FROM $RUST_BASE AS rust

# Upgrade and install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y cmake protobuf-compiler zstd

# Install Rust binaries
COPY --from=cargo-cache-bin /usr/local/bin/* /usr/local/bin/
COPY --from=diesel-bin /usr/local/bin/* /usr/local/bin/

# Install OpenShift client
COPY --from=openshift-bin /usr/local/bin/* /usr/local/bin/

# Install dockle, sccache, and trivy
COPY --from=download-bin /usr/local/bin/* /usr/local/bin/

#############################################################################
# Devcontainer                                                              #
#############################################################################
FROM $DEVCONTAINER_BASE AS devcontainer

# Upgrade and install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y cmake protobuf-compiler zstd

# Install Rust binaries
COPY --from=cargo-cache-bin /usr/local/bin/* /usr/local/bin/
COPY --from=cargo-edit-bin /usr/local/bin/* /usr/local/bin/
COPY --from=cargo-udeps-bin /usr/local/bin/* /usr/local/bin/
COPY --from=diesel-bin /usr/local/bin/* /usr/local/bin/

# Install dockle, sccache, and trivy
COPY --from=download-bin /usr/local/bin/* /usr/local/bin/

# Install OpenShift client
COPY --from=openshift-bin \
    /usr/local/bin/oc \
    /usr/local/bin/
COPY --from=openshift-bin \
    /etc/bash_completion.d/oc \
    /etc/bash_completion.d/
COPY --from=openshift-bin \
    /usr/local/share/zsh/site-functions/oc \
    /usr/local/share/zsh/site-functions/

# Always sign Git commits
RUN sudo git config --system commit.gpgsign true
