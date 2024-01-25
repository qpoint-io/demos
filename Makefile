# suppress change directory warnings
MAKEFLAGS += --no-print-directory

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

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

build-images: docker ## Build the app images
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			echo "Building app image: $$app_name"; \
			docker build -t "demo-$$app_name" "$$dir"; \
		fi; \
	done

ensure-images: docker ## Ensure all app images exist, build them if not
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			image_name="demo-$$app_name"; \
			if [ -z "$$(docker images -q $$image_name)" ]; then \
				echo "Building app image: $$app_name"; \
				docker build -t "$$image_name" "$$dir"; \
			else \
				echo "Image $$image_name already exists"; \
			fi; \
		fi; \
	done

build-node: docker ## Build the docker node image used to bootstrap KinD cluster
	docker build -t demo-kind-node:latest .

build: build-images ## Build the necessary resources for the environment

##@ Environment

cluster: kind ## Create the KinD cluster to run demo scenarios
	@$(KIND) get clusters | grep -qw "^demo$$" || $(KIND) create cluster --config kind-config.yaml --name demo

cert-manager: ## Install cert-manager on the KinD cluster
	@echo "Installing cert-manager..." && \
	($(HELM) repo list | grep -qw "jetstack" || \
		($(HELM) repo add jetstack https://charts.jetstack.io && $(HELM) repo update)) && \
	($(KUBECTL) get namespaces | grep -qw "cert-manager" || \
		$(HELM) install \
		cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--set installCRDs=true)

upload-images: kind ## Upload app images into the cluster
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			$(KIND) load docker-image "demo-$${app_name}:latest" --name demo; \
		fi; \
	done

label-namespaces-egress-service: kind ## Label the namespace for each app in apps directory with qpoint-egress=service
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! $(KUBECTL) get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'service'; then \
			$(KUBECTL) label namespace "$$ns" qpoint-egress=service --overwrite; \
		fi; \
	done

label-namespaces-egress-inject: kind ## Label the namespace for each app in apps directory with qpoint-egress=inject
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! $(KUBECTL) get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'inject'; then \
			$(KUBECTL) label namespace "$$ns" qpoint-egress=inject --overwrite; \
		fi; \
	done

label-namespaces-egress-disable: kind ## Label the namespace for each app in apps directory with qpoint-egress=disable
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! $(KUBECTL) get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'disable'; then \
			$(KUBECTL) label namespace "$$ns" qpoint-egress=disable --overwrite; \
		fi; \
	done

create-namespaces: kind ## Create a Kubernetes namespace for each app in the apps directory
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! $(KUBECTL) get namespace "$$ns" &>/dev/null; then \
			$(KUBECTL) create namespace "$$ns"; \
		else \
			echo "Namespace $$ns already exists"; \
		fi; \
	done

up: ensure-deps ensure-images cluster cert-manager upload-images create-namespaces ## Bring up the demo environment

down: ## Teardown the demo environment
	$(KIND) delete cluster --name demo

qpoint: ensure-deps ## Install qpoint gateway & operator
	@echo "Please ensure your Certificate has been placed in qpoint-qtap-ca.crt & Token has been placed in api_token.txt."
	$(eval API_KEY=$(shell cat api_token.txt))
	$(eval CERT_FILE=qpoint-qtap-ca.crt)

	@echo "Adding helm repo..."
	@$(HELM) repo add qpoint htts://qpoint-io.github.io/helm-charts/

	@echo "Updating helm repo..."
	@$(HELM) repo update

	@echo "Creating qpoint namespace..."
	@$(KUBECTL) create namespace qpoint

	@echo "Creating secret with API key..."
	@$(KUBECTL) create secret generic token --namespace qpoint --from-literal=token="${API_KEY}"

	@echo "Installing qtap-gateway..."
	@$(HELM) install qtap-gateway qpoint/qtap --namespace qpoint -f gateway-values.yaml

	@echo "Installing qtap-operator..."
	@$(HELM) install qtap-operator qpoint/qtap-operator --namespace qpoint

	@echo "Creating configmap with certificate..."
	@$(KUBECTL) create configmap qpoint-qtap-ca.crt --namespace qpoint --from-file=ca.crt=${CERT_FILE}

##@ Apps

%-app: ensure-deps cluster cert-manager ## Pattern rule for applications
	@$(MAKE) ensure-image APP=$* 
	@$(MAKE) ensure-namespace APP=$* 
	@$(MAKE) upload-image APP=$* 
	apps/$*/init.sh apps/$*

list-apps:
	@for dir in apps/*/; do \
		if [ -d "$$dir" ]; then \
			app_name=$$(basename "$$dir"); \
			echo "$$app_name"; \
		fi; \
	done

ensure-image: ## Rule to ensure the Docker image exists for app
	@dir=apps/$(APP); \
	if [ -f "$$dir/Dockerfile" ]; then \
		image_name="demo-$(APP)"; \
		if [ -z "$$(docker images -q $$image_name)" ]; then \
			echo "Building app image: $$image_name"; \
			docker build -t "$$image_name" "$$dir"; \
		else \
			echo "Image $$image_name already exists"; \
		fi; \
	fi

ensure-namespace: ## Create the namespace for app
	@$(KUBECTL) get namespace "$(APP)" >/dev/null 2>&1 || $(KUBECTL) create namespace "$(APP)";

upload-image: ## Upload app image into the cluster
	@dir=apps/$(APP); \
	if [ -f "$${dir}/Dockerfile" ]; then \
		image_name="demo-$(APP)"; \
		$(KIND) load docker-image "$$image_name:latest" --name demo; \
	fi;

##@ Demo

describe: ## Describe the app pod
	@namespace=$$($(KUBECTL) config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$($(KUBECTL) get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	$(KUBECTL) describe pod/$$pod_name -n $$namespace

exec: ## Exec into the app container
	@namespace=$$($(KUBECTL) config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$($(KUBECTL) get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	$(KUBECTL) exec -it $$pod_name -c $$namespace -- /bin/sh

restart: ## Rollout a restart on the deployment
	@namespace=$$($(KUBECTL) config view --minify --output 'jsonpath={..namespace}'); \
	$(KUBECTL) rollout restart deployment/$$namespace && \
	$(KUBECTL) rollout status deployment/$$namespace

init-logs: ## Show the qpoint-init logs
	@namespace=$$($(KUBECTL) config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$($(KUBECTL) get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	$(KUBECTL) logs $$pod_name -c qtap-init

gateway-proxy: ## Establish a port forward proxy
	@$(KUBECTL) port-forward -n qpoint $$($(KUBECTL) get pods -l app.kubernetes.io/name=qtap -o jsonpath="{.items[0].metadata.name}" -n qpoint) 9901:9901

gateway-logs: ## Stream the gateway logs
	@$(KUBECTL) logs -f -n qpoint pod/$$($(KUBECTL) get pods -l app.kubernetes.io/name=qtap -o jsonpath="{.items[0].metadata.name}" -n qpoint)

operator-logs: ## Stream the operator logs
	@$(KUBECTL) logs -f -n qpoint pod/$$($(KUBECTL) get pods -l app.kubernetes.io/name=qtap-operator -o jsonpath="{.items[0].metadata.name}" -n qpoint)

##@ Dependencies

## Location to install dependencies into
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

# Binaries
KUBECTL ?= $(LOCALBIN)/kubectl
KIND ?= $(LOCALBIN)/kind
HELM ?= $(LOCALBIN)/helm

docker: ## Ensure docker is installed and running
	@docker info > /dev/null 2>&1 || (echo "Error: Docker must be installed and running" && exit 1 )

kubectl: $(KUBECTL) ## Ensure kubectl is installed
$(KUBECTL): $(LOCALBIN)
	@test -s $(LOCALBIN)/kubectl || ./install.sh kubectl

kind: $(KIND) ## Ensure kind is installed
$(KIND): $(LOCALBIN)
	@test -s $(LOCALBIN)/kind || ./install.sh kind

helm: $(HELM) ## Ensure helm is installed
$(HELM): $(LOCALBIN)
	@test -s $(LOCALBIN)/helm || ./install.sh helm

install: # Install all necessary dependencies
	@./install.sh

ensure-deps: docker kubectl kind helm ## Ensure all dependencies are ready

qtap-gateway-tunnel: ## Starts up a local Qtap Proxy Tunnel on 10080 and 10443
	docker run -p 10080:10080 -p 10443:10443 us-docker.pkg.dev/qpoint-edge/public/qtap:v0.0.12 \
		gateway \
		--envoy-log-level=error --log-level=info --dns-lookup-family=V4_ONLY \
		--token=$$TOKEN \
		--egress-http-listen="0.0.0.0:10080" \
		--egress-https-listen="0.0.0.0:10443"

