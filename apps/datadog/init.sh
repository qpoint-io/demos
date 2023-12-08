#!/bin/sh

set -e

bin/helm uninstall datadog-agent -n datadog --ignore-not-found
bin/helm repo add datadog https://helm.datadoghq.com
bin/helm repo update
bin/helm install datadog-agent -f "$1"/values.yaml datadog/datadog -n datadog
