#!/bin/sh

set -e

# probe the OS and machine architecture
os=$(uname)
machine=$(uname -m)

# the OS platform (linux|mac|windows)
platform="unknown"

# the OS platform's alternative name (macos) or the same as platform if no alternative exists
alt_platform="unknown"

# the chipset architecture (amd64|arm64)
architecture="unknown"

# normalize the platform/architecture
case "$os" in
  Linux)
    platform="linux"
    alt_platform="linux"
    case "$machine" in
      x86_64) architecture="amd64" ;;
      arm64 | aarch64) architecture="arm64" ;;
    esac
    ;;
  Darwin)
    platform="darwin"
    alt_platform="macos"
    case "$machine" in
      x86_64) architecture="amd64" ;;
      arm64) architecture="arm64" ;;
    esac
    ;;
  MINGW* | CYGWIN* | MSYS*)
    platform="windows"
    alt_platform="windows"
    case "$machine" in
      x86_64) architecture="amd64" ;;
      ARM64) architecture="arm64" ;;
    esac
    ;;
esac

# install kubectl
install_kubectl() {
  echo "Installing kubectl..."

  # return early if already exists
  if [ -f "bin/kubectl" ]; then
    return 0
  fi

  # ensure bin dir
  mkdir -p bin

  # grab latest stable version
  version=$(curl -L -s https://dl.k8s.io/release/stable.txt)

  # install
  curl -Lo bin/kubectl "https://dl.k8s.io/release/${version}/bin/${platform}/${architecture}/kubectl"

  # ensure executable
  chmod +x bin/kubectl
}

install_kind() {
  echo "Installing kind..."

  # return early if already exists
  if [ -f "bin/kind" ]; then
    return 0
  fi

  # ensure bin dir
  mkdir -p bin

# grab latest stable version
  version=$(curl --silent "https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" | jq -r '.tag_name')

  # install
  curl -Lo bin/kind "https://kind.sigs.k8s.io/dl/${version}/kind-${platform}-${architecture}"

  # ensure executable
  chmod +x bin/kind
}

install_helm() {
  echo "Installing helm..."

  # return early if already exists
  if [ -f "bin/helm" ]; then
    return 0
  fi

  # ensure bin dir
  mkdir -p bin

  # install
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | \
    HELM_INSTALL_DIR="./bin" USE_SUDO="false" bash -

  # ensure executable
  chmod +x bin/helm
}

install_jq() {
  echo "Installing jq..."

  # return early if already exists
  if [ -f "bin/jq" ]; then
    return 0
  fi

  # ensure bin dir
  mkdir -p bin

   # install
  curl -Lo bin/jq "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-${alt_platform}-${architecture}"

  # ensure executable
  chmod +x bin/jq
}

# extract the requested utility
utility="$1"

# assume all if not specified
if [ "$utility" = "" ]; then
  utility="all"
fi

# kubectl
if [ "$utility" = "kubectl" ] || [ "$utility" = "all" ]; then
  install_kubectl
fi

# kind
if [ "$utility" = "kind" ] || [ "$utility" = "all" ]; then
  install_kind
fi

# helm
if [ "$utility" = "helm" ] || [ "$utility" = "all" ]; then
  install_helm
fi

# helm
if [ "$utility" = "jq" ] || [ "$utility" = "all" ]; then
  install_jq
fi
