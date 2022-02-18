#!/bin/sh

# Install sccache
# https://github.com/mozilla/sccache

set -e

: ${SCCACHE_VERSION:=0.2.15}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

mkdir -p "$SDK_CACHE_DIR/sccache"
cd "$SDK_CACHE_DIR/sccache"

SCCACHE_ARCHIVE="sccache-v$SCCACHE_VERSION-$(uname -m)-unknown-linux-musl.tar.gz"
if [ ! -f "$SCCACHE_ARCHIVE" ] || [ ! -f "$SCCACHE_ARCHIVE.sha256" ]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/$SCCACHE_ARCHIVE"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/$SCCACHE_ARCHIVE.sha256"
    echo -n " $SCCACHE_ARCHIVE" >> "$SCCACHE_ARCHIVE.sha256"
    sha256sum -c "$SCCACHE_ARCHIVE.sha256"
    tar --strip-components=1 --wildcards '*/sccache' -xf "$SCCACHE_ARCHIVE"
    chmod +x sccache
fi

cp sccache /usr/local/bin

cd /
rm -rf "$SDK_CACHE_DIR" || true
