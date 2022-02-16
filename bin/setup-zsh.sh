#!/bin/sh

set -e

: ${ZSH_VERSION:=5.8.1}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

mkdir -p "$SDK_CACHE_DIR/zsh"
cd "$SDK_CACHE_DIR"

sccache --show-stats || true

# Install zsh
# https://www.zsh.org

FILE="zsh-${ZSH_VERSION}.tar.xz"
if [[ ! -f "$FILE" || ! -f "${FILE}.asc" ]]; then
    curl -sSL --proto '=https' --tlsv1.2 -O "https://www.zsh.org/pub/${FILE}"
    curl -sSL --proto '=https' --tlsv1.2 -O "https://www.zsh.org/pub/${FILE}.asc"

    gpg --keyserver keyserver.ubuntu.com --recv \
        7CA7ECAAF06216B90F894146ACF8146CAE8CBBC4
    gpg --verify "zsh-${ZSH_VERSION}.tar.xz.asc"
    rm -rf ~/.gpg || true

    rm -rf "zsh-${ZSH_VERSION}"
    tar -xf "zsh-${ZSH_VERSION}.tar.xz"
fi

cd "zsh-${ZSH_VERSION}"

./configure --with-tcsetpgrp --enable-pcre

make
make install

# Install oh-my-zsh
# https://github.com/ohmyzsh/ohmyzsh

git clone --depth=1 \
    -c core.eol=lf \
    -c core.autocrlf=false \
    -c fsck.zeroPaddedFilemode=ignore \
    -c fetch.fsck.zeroPaddedFilemode=ignore \
    -c receive.fsck.zeroPaddedFilemode=ignore \
    https://github.com/ohmyzsh/ohmyzsh.git /etc/skel/.oh-my-zsh

cp /etc/skel/.oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
cd /etc/skel/.oh-my-zsh && git repack -adf --depth=1 --window=1

sed -i "/plugins=\(.*\)/a plugins+=(docker docker-compose rust)" \
    /etc/skel/.zshrc

sccache --stop-server || true

cd /
rm -rf "$SDK_CACHE_DIR" || true
