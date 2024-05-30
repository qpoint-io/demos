#!/bin/sh

set -e

bin/helm uninstall grafana -n grafana --ignore-not-found
bin/helm repo add grafana https://grafana.github.io/helm-charts
bin/helm repo update
bin/helm install grafana grafana/grafana -n grafana
