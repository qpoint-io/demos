#!/bin/sh

set -e

bin/helm uninstall argocd -n argocd --ignore-not-found
bin/helm repo add argo https://argoproj.github.io/argo-helm
bin/helm repo update
bin/helm install argocd argo/argo-cd --version 5.52.0 -n argocd
