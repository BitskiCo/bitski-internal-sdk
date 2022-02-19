#!/bin/sh

set -e

: ${DOCKLE_VERSION:=0.4.4}
: ${SCCACHE_VERSION:=0.2.15}
: ${TRIVY_VERSION:=0.23.0}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

case `uname -m` in
amd64 | x86_64) 
    DOCKLE_TRIVY_ARCH=64bit
    ;;
aarch64 | arm64) 
    DOCKLE_TRIVY_ARCH=ARM64
    ;;
*)
    >&2 echo "Arch $(uname -m) not supported"
    exit 1
    ;;
esac

# Download Dockle
# https://github.com/goodwithtech/dockle
mkdir -p "$SDK_CACHE_DIR/dockle"
cd "$SDK_CACHE_DIR/dockle"

DOCKLE_ARCHIVE="dockle_${DOCKLE_VERSION}_Linux-$DOCKLE_TRIVY_ARCH.deb"
if [ ! -f "$DOCKLE_ARCHIVE" ] || [ ! -f "$DOCKLE_ARCHIVE.sha256" ]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/goodwithtech/dockle/releases/download/v$DOCKLE_VERSION/dockle_${DOCKLE_VERSION}_checksums.txt"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/goodwithtech/dockle/releases/download/v$DOCKLE_VERSION/$DOCKLE_ARCHIVE"
    cat "dockle_${DOCKLE_VERSION}_checksums.txt" | grep "$DOCKLE_ARCHIVE" >> "$DOCKLE_ARCHIVE.sha256"
    sha256sum -c "$DOCKLE_ARCHIVE.sha256"
fi

dpkg -i "$DOCKLE_ARCHIVE"

# Download sccache
# https://github.com/mozilla/sccache
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

# Download Trivy
# https://github.com/aquasecurity/trivy
mkdir -p "$SDK_CACHE_DIR/trivy"
cd "$SDK_CACHE_DIR/trivy"

TRIVY_ARCHIVE="trivy_${TRIVY_VERSION}_Linux-$DOCKLE_TRIVY_ARCH.deb"
if [ ! -f "$TRIVY_ARCHIVE" ] || [ ! -f "$TRIVY_ARCHIVE.sha256" ]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/aquasecurity/trivy/releases/download/v$TRIVY_VERSION/trivy_${TRIVY_VERSION}_checksums.txt"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/aquasecurity/trivy/releases/download/v$TRIVY_VERSION/$TRIVY_ARCHIVE"
    cat "trivy_${TRIVY_VERSION}_checksums.txt" | grep "$TRIVY_ARCHIVE" >> "$TRIVY_ARCHIVE.sha256"
    sha256sum -c "$TRIVY_ARCHIVE.sha256"
fi

dpkg -i "$TRIVY_ARCHIVE"

cd /
rm -rf "$SDK_CACHE_DIR" || true
