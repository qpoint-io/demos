#!/bin/sh

set -e

bin/helm uninstall jenkins -n jenkins --ignore-not-found
bin/helm repo add jenkins https://charts.jenkins.io
bin/helm repo update
bin/helm install jenkins jenkins/jenkins -n jenkins
