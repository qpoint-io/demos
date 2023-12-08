#!/bin/sh

set -e

helm uninstall datadog-agent -n datadog --ignore-not-found
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install datadog-agent -f "$1"/values.yaml datadog/datadog -n datadog
