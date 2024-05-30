#!/bin/sh

set -e

bin/helm uninstall prometheus -n prometheus --ignore-not-found
bin/helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
bin/helm repo update
bin/helm install prometheus prometheus-community/prometheus -f "$1"/values.yaml -n prometheus
