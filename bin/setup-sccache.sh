set -e

: ${SCCACHE_VERSION:=0.2.15}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

mkdir -p "$SDK_CACHE_DIR/sccache"
cd "$SDK_CACHE_DIR"

# Install sccache
# https://github.com/mozilla/sccache

SCCACHE_ARCHIVE="sccache-v${SCCACHE_VERSION}-$(uname -m)-unknown-linux-musl.tar.gz"
SCCACHE_ARCHIVE="${SCCACHE_ARCHIVE,,}"

if [[ ! -f "$SCCACHE_ARCHIVE" || ! -f "${SCCACHE_ARCHIVE}.sha256" ]]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/${SCCACHE_ARCHIVE}"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/${SCCACHE_ARCHIVE}.sha256"
    echo -n " ${SCCACHE_ARCHIVE}" >> "${SCCACHE_ARCHIVE}.sha256"
fi

sha256sum -c "${SCCACHE_ARCHIVE}.sha256"

rm -rf sccache
tar --strip-components=1 '*/sccache' -xf "$SCCACHE_ARCHIVE"
chmod +x sccache

mv sccache /usr/local/bin

for EXEC in cc gcc; do
    cat <<EOL | tee "/usr/local/bin/sccache-$EXEC"
#!/bin/sh
/usr/local/bin/sccache "$(which "$EXEC")" "\$@"
EOL
    chmod +x "/usr/local/bin/sccache-$EXEC"
done

cd /
rm -rf "$SDK_CACHE_DIR" || true
