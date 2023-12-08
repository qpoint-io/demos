#!/bin/sh

set -e

bin/helm uninstall newrelic-bundle -n newrelic --ignore-not-found
bin/helm repo add newrelic https://helm-charts.newrelic.com
bin/helm repo update
bin/helm install newrelic-bundle newrelic/nri-bundle -f "$1"/values.yaml -n newrelic
