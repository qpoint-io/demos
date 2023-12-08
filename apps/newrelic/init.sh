#!/bin/sh

set -e

helm uninstall newrelic-bundle -n newrelic --ignore-not-found
helm repo add newrelic https://helm-charts.newrelic.com
helm repo update
helm install newrelic-bundle newrelic/nri-bundle -f "$1"/values.yaml -n newrelic
