#!/bin/sh

set -o functrace
set -e

if [[ "$(uname -m)" != arm64 ]]; then
    echo "$0 should be run on arm64 machine"
    exit 1
fi

: ${REGISTRY:=ghcr.io/bitskico}
: ${NAME:=bitski-internal-sdk}
: ${TAG:=devcontainer}

: ${IMAGE_NAME:=${REGISTRY}/${NAME}}
: ${IMAGE:=${IMAGE_NAME}:${TAG}}
: ${LOCAL_IMAGE:=${NAME}:${TAG}-arm64}

# Build and push multi-arch devcontainer from ARM64 system

AMD64_DIGEST=`docker pull --platform amd64 "$IMAGE" | \
    grep Digest | cut -d' ' -f2`

LABELS=`docker inspect "$IMAGE_NAME@$AMD64_DIGEST" | jq -r '
    .[0].Config.Labels |
    to_entries | map(["--label", .key + "=" + .value]) |
    flatten | .[]'`

IFS=$'\n' command eval 'LABELS=($LABELS)'

docker buildx build \
    --load \
    --platform linux/arm64 \
    --target "$TAG" \
    --tag "$LOCAL_IMAGE" \
    "${LABELS[@]}" \
    "$(dirname "$0")/.."

docker tag "$IMAGE_NAME@$AMD64_DIGEST" "$IMAGE-amd64"
docker push "$IMAGE-amd64"

docker tag "$LOCAL_IMAGE" "$IMAGE-arm64"
docker push "$IMAGE-arm64"

docker manifest rm "$IMAGE"

docker manifest create "$IMAGE" \
    --amend "$IMAGE-amd64" \
    --amend "$IMAGE-arm64"

docker manifest push "$IMAGE"
