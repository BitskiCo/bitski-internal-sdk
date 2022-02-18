#!/bin/sh

set -e

: ${IMAGE:=ghcr.io/bitskico/bitski-internal-sdk:devcontainer}

# Build devcontainer for local use

docker buildx build \
    --load \
    --build-arg RUST_VERSION=latest,nightly \
    --target devcontainer \
    --tag "$IMAGE" \
    "$(dirname "$0")/.."
