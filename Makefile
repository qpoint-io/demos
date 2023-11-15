##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk command is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: build-images
build-images: docker ## Build the app images
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			echo "Building app image: $$app_name"; \
			docker build -t "demo-$$app_name" "$$dir"; \
		fi; \
	done

.PHONY: build-node
build-node: docker ## Build the docker node image used to bootstrap KinD cluster
	docker build -t demo-kind-node:latest .

.PHONY: build
build: build-images build-node ## Build the necessary resources for the environment

##@ Environment

.PHONY: cluster
cluster: kind ## Create the KinD cluster to run demo scenarios
	kind create cluster --config kind-config.yaml --name demo

.PHONY: cert-manager
cert-manager: ## Install cert-manager on the KinD cluster 
	helm install \
	cert-manager jetstack/cert-manager \
	--namespace cert-manager \
	--create-namespace \
	--set installCRDs=true

.PHONY: upload-images
upload-images: kind ## Upload app images into the cluster
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			kind load docker-image "demo-$${app_name}:latest" --name demo; \
		fi; \
	done

.PHONY: up
up: ensure-deps cluster cert-manager upload-images ## Bring up the demo environment

.PHONY: down
down: ## Teardown the demo environment
	kind delete cluster --name demo

##@ Apps

.PHONY: simple
simple: up ## Deploy the "simple" app for curl'ing external APIs
	kubectl apply -f apps/simple/deployment.yaml

##@ Dependencies

.PHONY: docker
docker: ## Ensure docker is installed and running
	@docker info > /dev/null 2>&1 || (echo "Error: Docker must be installed and running" && exit 1 )

.PHONY: kubectl
kubectl: ## Ensure kubectl is installed
	@which kubectl > /dev/null 2>&1 || (echo "Error: Kubectl must be installed" && exit 1)

.PHONY: kind
kind: ## Ensure kind is installed
	@which kind > /dev/null 2>&1 || (echo "Error: KinD must be installed" && exit 1)

.PHONY: helm
helm: ## Ensure helm is installed
	@which kind > /dev/null 2>&1 || (echo "Error: Helm must be installed" && exit 1)

.PHONY: ensure-deps
ensure-deps: docker kubectl kind helm ## Ensure all dependencies are ready
