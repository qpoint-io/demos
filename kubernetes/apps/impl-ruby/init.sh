#!/bin/sh

set -e

bin/kubectl delete -f "$1"/deployment.yaml --ignore-not-found
bin/kubectl apply -f "$1"/deployment.yaml
