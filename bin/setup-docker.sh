#!/bin/sh
set -e

_=${DOCKER_COMPOSE_VERSION:="2.2.3"}

cd /tmp/docker

# Install Docker
# https://www.docker.com
yum install -y yum-utils

yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

echo "Installing sccache..."
DOCKER_COMPOSE_FILE="docker-compose-$(uname -s)-$(uname -m)"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE,,}"
if [[ ! -f "$DOCKER_COMPOSE_FILE" || ! -f "${DOCKER_COMPOSE_FILE}.sha256" ]]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/${DOCKER_COMPOSE_FILE}"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/${DOCKER_COMPOSE_FILE}.sha256"
fi
sha256sum -c "${DOCKER_COMPOSE_FILE}.sha256"
chmod +x "$DOCKER_COMPOSE_FILE"
mkdir -p /usr/local/lib/docker/cli-plugins
mv "$DOCKER_COMPOSE_FILE" /usr/local/lib/docker/cli-plugins/docker-compose

rm -rf /tmp/docker || true