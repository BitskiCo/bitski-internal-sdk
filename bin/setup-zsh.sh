#!/bin/sh

set -e

: ${USERNAME:=root}
: ${ZSH_VERSION:=5.8}

# Install zsh
# https://www.zsh.org

mkdir -p /tmp/zsh
cd /tmp/zsh

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

cd /
rm -rf /tmp/zsh || true

# Install oh-my-zsh
# https://github.com/ohmyzsh/ohmyzsh

su $USERNAME -c 'git clone --depth=1 \
    -c core.eol=lf \
    -c core.autocrlf=false \
    -c fsck.zeroPaddedFilemode=ignore \
    -c fetch.fsck.zeroPaddedFilemode=ignore \
    -c receive.fsck.zeroPaddedFilemode=ignore \
    https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh'

su $USERNAME -c 'cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc'
su $USERNAME -c 'cd ~/.oh-my-zsh && git repack -adf --depth=1 --window=1'

su "$USERNAME" -c \
    'sed -i "/plugins=\(.*\)/a plugins+=(docker docker-compose rust)" ~/.zshrc'
