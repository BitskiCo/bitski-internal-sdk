#!/bin/sh

set -e

# Install common dependencies
dnf install -y \
    bash-completion \
    curl \
    gcc \
    git \
    glibc \
    gnupg2 \
    golang \
    grep \
    jq \
    less \
    libgcc \
    libicu \
    libpq-devel \
    libstdc++ \
    llvm-libs \
    lsof \
    make \
    man-db \
    nano \
    ncurses-devel \
    net-tools \
    openssh-clients \
    openssl-libs \
    procps-ng \
    psmisc \
    less \
    make \
    rsync \
    sudo \
    unzip \
    vim-minimal \
    wget \
    xz \
    zip \
    zlib \
    zstd
