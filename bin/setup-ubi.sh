#!/bin/sh
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# ** This script is community supported **
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/common.md
# Maintainer: The VS Code and Codespaces Teams

set -e

: ${USERNAME:=root}
: ${USER_UID:=1000}
: ${USER_GID:=1000}

if [[ "$USERNAME" == "root" ]]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
elif [[ -z "${USERNAME}" ]]; then
    USERNAME=vscode
fi

# Install common dependencies
dnf install -y \
    bash-completion \
    ca-certificates \
    compat-openssl10 \
    curl \
    dirmngr \
    gcc \
    git \
    gnupg2 \
    golang \
    grep \
    iproute \
    jq \
    krb5-libs \
    less \
    libicu \
    libpq-devel \
    lsof \
    make \
    man-db \
    nano \
    ncurses-devel \
    net-tools \
    openssh-clients \
    openssl-libs \
    procps \
    psmisc \
    redhat-lsb-core \
    rsync \
    sed \
    sudo \
    unzip \
    vim-minimal \
    wget \
    which \
    xz \
    zip \
    zlib \
    zstd

# Create or update a non-root user to match UID/GID.
group_name="${USERNAME}"
if id -u ${USERNAME} > /dev/null 2>&1; then
    # User exists, update if needed
    if [ "${USER_GID}" != "automatic" ] && [ "$USER_GID" != "$(id -g $USERNAME)" ]; then 
        group_name="$(id -gn $USERNAME)"
        groupmod --gid $USER_GID ${group_name}
        usermod --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "$USER_UID" != "$(id -u $USERNAME)" ]; then 
        usermod --uid $USER_UID $USERNAME
    fi
else
    # Create user
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd $USERNAME
    else
        groupadd --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" = "automatic" ]; then 
        useradd -s /bin/bash --gid $USERNAME -m $USERNAME
    else
        useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME
    fi
fi

# Add add sudo support for non-root user
if [ "${USERNAME}" != "root" ]; then
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME
fi
