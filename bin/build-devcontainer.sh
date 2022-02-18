#!/bin/sh

set -e

: ${IMAGE:=ghcr.io/bitskico/bitski-internal-sdk:devcontainer}

# Build devcontainer for local use

docker buildx build \
    --load \
    --build-arg USERNAME=bitski \
    --build-arg RUST_VERSION=latest,nightly,1.58,1.57,1.56,1.55 \
    --target devcontainer \
    --tag "$IMAGE" \
    "$(dirname "$0")/.."
