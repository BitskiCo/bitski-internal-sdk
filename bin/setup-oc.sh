#!/bin/sh

set -e

: ${OC_VERSION:=4.9}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

mkdir -p "$SDK_CACHE_DIR/oc"
cd "$SDK_CACHE_DIR"

# Install OpenShift CLI
# https://github.com/openshift/oc

mkdir -p "$SDK_CACHE_DIR/oc"
cd "$SDK_CACHE_DIR/oc"

if [ ! -d oc ]; then
    microdnf install -y git
    git clone --depth 1 -b "release-${OC_VERSION}" \
        https://github.com/openshift/oc.git
fi

cd oc

if [ ! -f oc ]; then
    microdnf install -y \
        gcc \
        git \
        golang \
        gpgme-devel \
        krb5-devel \
        libassuan-devel \
        make
    make oc
fi

cp oc /usr/local/bin

mkdir -p /etc/bash_completion.d /usr/local/share/zsh/site-functions
cp contrib/completions/bash/oc /etc/bash_completion.d
cp contrib/completions/zsh/oc /usr/local/share/zsh/site-functions

cd /
rm -rf "$SDK_CACHE_DIR" || true
