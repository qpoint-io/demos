#!/bin/sh

set -e

kubectl delete -f "$1"/deployment.yaml --ignore-not-found
kubectl apply -f "$1"/deployment.yaml
