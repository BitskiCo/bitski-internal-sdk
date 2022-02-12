#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/rust.md
# Maintainer: The VS Code and Codespaces Teams

set -e

export CARGO_HOME=${CARGO_HOME:-/usr/local/cargo}
export RUSTUP_HOME=${RUSTUP_HOME:-/usr/local/rustup}
: ${USERNAME:=root}
: ${UPDATE_RC:=true}
: ${RUST_VERSION:=latest}
: ${RUSTUP_PROFILE:=minimal}
: ${SDK_CACHE_DIR:=/var/cache/bitski-internal-sdk}

mkdir -p "$SDK_CACHE_DIR/rust"
cd "$SDK_CACHE_DIR"

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

architecture="$(arch)"
download_architecture="${architecture}"
case ${download_architecture} in
 amd64 | x86_64) 
    download_architecture="x86_64"
    ;;
 aarch64 | arm64) 
    download_architecture="aarch64"
    ;;
 *) echo "(!) Architecture ${architecture} not supported."
    exit 1
    ;;
esac

# Install Rust dependencies
dnf repoquery --deplist rust | grep provider | cut -d':' -f2 | xargs dnf install -y

# Install Rust
umask 0002
if ! cat /etc/group | grep -e "^rustlang:" > /dev/null 2>&1; then
    groupadd -r rustlang
fi
usermod -a -G rustlang "${USERNAME}"
mkdir -p "${CARGO_HOME}" "${RUSTUP_HOME}"
chown :rustlang "${RUSTUP_HOME}" "${CARGO_HOME}"
chmod g+r+w+s "${RUSTUP_HOME}" "${CARGO_HOME}"

# Support multiple Rust versions
IFS=', ' read -r -a RUSTUP_INSTALL_TOOLCHAINS <<< "$RUST_VERSION"
RUST_VERSION="${RUSTUP_INSTALL_TOOLCHAINS[0]}"
RUSTUP_INSTALL_TOOLCHAINS=("${RUSTUP_INSTALL_TOOLCHAINS[@]:1}")

# Download and verify rustup sha
echo "Installing Rust..."
if [ "${RUST_VERSION}" != "latest" ] && [ "${RUST_VERSION}" != "lts" ] && [ "${RUST_VERSION}" != "stable" ]; then
    find_version_from_git_tags RUST_VERSION "https://github.com/rust-lang/rust" "tags/"
    default_toolchain_arg="--default-toolchain ${RUST_VERSION}"
fi
RUSTUP_INIT_FILE="target/${download_architecture}-unknown-linux-gnu/release/rustup-init"
if [[ ! -f "$RUSTUP_INIT_FILE" || ! -f rustup-init.sha256 ]]; then
    mkdir -p target/${download_architecture}-unknown-linux-gnu/release/
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init" -o "$RUSTUP_INIT_FILE"
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init.sha256" -o rustup-init.sha256
fi
sha256sum -c rustup-init.sha256
chmod +x "$RUSTUP_INIT_FILE"
"$RUSTUP_INIT_FILE" -y --no-modify-path --profile ${RUSTUP_PROFILE} ${default_toolchain_arg}

export PATH=${CARGO_HOME}/bin:${PATH}
echo "Installing common Rust dependencies..."
rustup component add clippy rls rust-analysis rust-src rustfmt
for rust_version in "${RUSTUP_INSTALL_TOOLCHAINS[@]}"; do
    rustup toolchain install "$rust_version" --component clippy rls rust-analysis rust-src rustfmt
done

# Add CARGO_HOME, RUSTUP_HOME and bin directory into bashrc/zshrc files (unless disabled)
updaterc "$(cat << EOF
export RUSTUP_HOME="${RUSTUP_HOME}"
export CARGO_HOME="${CARGO_HOME}"
if [[ "\${PATH}" != *"\${CARGO_HOME}/bin"* ]]; then export PATH="\${CARGO_HOME}/bin:\${PATH}"; fi
EOF
)"

# Make files writable for rustlang group
chmod -R g+r+w "${RUSTUP_HOME}" "${CARGO_HOME}"

cd /
rm -rf "$SDK_CACHE_DIR" || true
