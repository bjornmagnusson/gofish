#!/usr/bin/env bash

# Copyright (C) 2016, Matt Butcher

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Ripped from github.com/technosophos/helm-template's get-binary.sh script, with a few tweaks to fetch fish.

PROJECT_NAME="fish"
PROJECT_GH="fishworks/$PROJECT_NAME"

: ${INSTALL_PREFIX:="/usr/local/bin"}
: ${VERSION:="v0.1.0"}

if [[ $SKIP_BIN_INSTALL == "1" ]]; then
  echo "Skipping binary install"
  exit
fi

# initArch discovers the architecture for this system.
initArch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="armv7";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}

# initOS discovers the operating system for this system.
initOS() {
  OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')

  case "$OS" in
    # Msys support
    msys*) OS='windows';;
    # Minimalist GNU for Windows
    mingw*) OS='windows';;
  esac
}

# verifySupported checks that the os/arch combination is supported for
# binary builds.
verifySupported() {
  local supported="linux-386\nlinux-amd64\nlinux-arm\nlinux-arm64\nlinux-ppc64le\ndarwin-amd64\nwindows-amd64"
  if ! echo "${supported}" | grep -q "${OS}-${ARCH}"; then
    echo "No prebuilt binary for ${OS}-${ARCH}."
    exit 1
  fi

  if ! type "curl" > /dev/null && ! type "wget" > /dev/null; then
    echo "Either curl or wget is required"
    exit 1
  fi
}

# getDownloadURL checks the latest available version.
getDownloadURL() {
  DOWNLOAD_URL="https://bacongobbler.blob.core.windows.net/gofish/fish-$VERSION-$OS-$ARCH.tar.gz"
}

# downloadFile downloads the latest binary package and also the checksum
# for that binary.
downloadFile() {
  TMP_CACHE_FILE="/tmp/${PROJECT_NAME}.tgz"
  echo "Downloading $DOWNLOAD_URL"
  if type "curl" > /dev/null; then
    curl -L "$DOWNLOAD_URL" -o "$TMP_CACHE_FILE"
  elif type "wget" > /dev/null; then
    wget -q -O "$TMP_CACHE_FILE" "$DOWNLOAD_URL"
  fi
}

# installFile verifies the SHA256 for the file, then unpacks and
# installs it.
installFile() {
  TMPDIR="/tmp/$PROJECT_NAME"
  mkdir -p "$TMPDIR"
  tar xf "$TMP_CACHE_FILE" -C "$TMPDIR"
  TMPDIR_BIN="$TMPDIR/$OS-$ARCH/$NAME"
  echo "Preparing to install into ${INSTALL_PREFIX}"
  # Use * to also copy the file withe the exe suffix on Windows
  mkdir -p "$INSTALL_PREFIX"
  cp "$TMPDIR_BIN"* "$INSTALL_PREFIX"
}

# fail_trap is executed if an error occurs.
fail_trap() {
  result=$?
  if [ "$result" != "0" ]; then
    echo -e "!!!\tFailed to install $PROJECT_NAME"
    echo -e "!!!\tFor support, go to https://github.com/$PROJECT_GH."
  fi
  exit $result
}

# testVersion tests the installed client to make sure it is working.
testVersion() {
  set +e
  echo "$PROJECT_NAME installed into $INSTALL_PREFIX/$PROJECT_NAME"
  echo "Run 'fish init' to get started!"
  # To avoid to keep track of the Windows suffix,
  # call the plugin assuming it is in the PATH
  PATH=$PATH:$INSTALL_PREFIX
  fish -h > /dev/null
  set -e
}

# Execution

#Stop execution on any error
trap "fail_trap" EXIT
set -e
initArch
initOS
verifySupported
getDownloadURL
downloadFile
installFile
testVersion
