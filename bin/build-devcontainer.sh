#!/bin/sh

set -e

docker buildx build \
    --load \
    --build-arg USERNAME=bitski \
    --build-arg RUST_VERSION=latest,1.58,1.57,1.56 \
    --target devcontainer \
    --tag bitski-internal-sdk:devcontainer \
    "$(dirname "$(readlink "$0")")"
