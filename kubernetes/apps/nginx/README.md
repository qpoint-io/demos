# NGINX Deployment and Headless Service

## Overview

Makes use of <https://hub.docker.com/_/nginx> to build a minimal NGINX image to serve up a static site.


## Headless Service

A headless service (<https://kubernetes.io/docs/concepts/services-networking/service/#headless-services>) is used to get a DNS record for the NGINX pod.

The pod will be available at `nginx.nginx.svc.cluster.local`.
