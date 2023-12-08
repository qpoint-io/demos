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
	@kind get clusters | grep -qw "^demo$$" || kind create cluster --config kind-config.yaml --name demo

cert-manager: ## Install cert-manager on the KinD cluster
	@echo "Installing cert-manager..." && \
	(helm repo list | grep -qw "jetstack" || \
		(helm repo add jetstack https://charts.jetstack.io && helm repo update)) && \
	(kubectl get namespaces | grep -qw "cert-manager" || \
		helm install \
		cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--set installCRDs=true)

upload-images: kind ## Upload app images into the cluster
	@for dir in apps/*/; do \
		if [ -f "$${dir}Dockerfile" ]; then \
			app_name=$$(basename "$$dir"); \
			kind load docker-image "demo-$${app_name}:latest" --name demo; \
		fi; \
	done

label-namespaces-egress-service: kind ## Label the namespace for each app in apps directory with qpoint-egress=service
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'service'; then \
			kubectl label namespace "$$ns" qpoint-egress=service --overwrite; \
		fi; \
	done

label-namespaces-egress-inject: kind ## Label the namespace for each app in apps directory with qpoint-egress=inject
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'inject'; then \
			kubectl label namespace "$$ns" qpoint-egress=inject --overwrite; \
		fi; \
	done

label-namespaces-egress-disable: kind ## Label the namespace for each app in apps directory with qpoint-egress=disable
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'disable'; then \
			kubectl label namespace "$$ns" qpoint-egress=disable --overwrite; \
		fi; \
	done

up: ensure-deps ensure-images cluster cert-manager upload-images ## Bring up the demo environment

down: ## Teardown the demo environment
	kind delete cluster --name demo

qpoint: ensure-deps ## Install qpoint gateway & operator
	@echo "Please ensure your Certificate has been placed in qpoint-qtap-ca.crt & Token has been placed in api_token.txt."
	$(eval API_KEY=$(shell cat api_token.txt))
	$(eval CERT_FILE=qpoint-qtap-ca.crt)

	@echo "Adding helm repo..."
	@helm repo add qpoint htts://qpoint-io.github.io/helm-charts/

	@echo "Updating helm repo..."
	@helm repo update

	@echo "Creating qpoint namespace..."
	@kubectl create namespace qpoint

	@echo "Creating secret with API key..."
	@kubectl create secret generic token --namespace qpoint --from-literal=token="${API_KEY}"

	@echo "Installing qtap-gateway..."
	@helm install qtap-gateway qpoint/qtap --namespace qpoint -f gateway-values.yaml

	@echo "Installing qtap-operator..."
	@helm install qtap-operator qpoint/qtap-operator --namespace qpoint

	@echo "Creating configmap with certificate..."
	@kubectl create configmap qpoint-qtap-ca.crt --namespace qpoint --from-file=ca.crt=${CERT_FILE}

##@ Apps

%-app: ensure-deps cluster cert-manager ## Pattern rule for applications
	@$(MAKE) ensure-image APP=$* > /dev/null
	@$(MAKE) ensure-namespace APP=$* > /dev/null
	@$(MAKE) upload-image APP=$* > /dev/null
	apps/$*/init.sh apps/$*

ensure-image: ## Rule to ensure the Docker image exists for app
	dir=apps/$(APP)
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
	kubectl get namespace "$(APP)" >/dev/null 2>&1 || kubectl create namespace "$(APP)";

upload-image: ## Upload app image into the cluster
	dir=apps/$(APP)
	if [ -f "$${dir}/Dockerfile" ]; then \
		image_name="demo-$(APP)"; \
		kind load docker-image "$$image_name:latest" --name demo; \
	fi;

##@ Demo

describe: ## Describe the app pod
	@namespace=$$(kubectl config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$(kubectl get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	kubectl describe pod/$$pod_name -n $$namespace

exec: ## Exec into the app container
	@namespace=$$(kubectl config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$(kubectl get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	kubectl exec -it $$pod_name -- /bin/sh

restart: ## Rollout a restart on the deployment
	@namespace=$$(kubectl config view --minify --output 'jsonpath={..namespace}'); \
	kubectl rollout restart deployment/$$namespace && \
	kubectl rollout status deployment/$$namespace

init-logs: ## Show the qpoint-init logs
	@namespace=$$(kubectl config view --minify --output 'jsonpath={..namespace}'); \
	pod_name=$$(kubectl get pods -n $$namespace -l app=$$namespace -o jsonpath="{.items[0].metadata.name}"); \
	kubectl logs $$pod_name -c qtap-init

gateway-proxy: ## Establish a port forward proxy
	@kubectl port-forward -n qpoint $$(kubectl get pods -l app.kubernetes.io/name=qtap -o jsonpath="{.items[0].metadata.name}" -n qpoint) 9901:9901

gateway-logs: ## Stream the gateway logs
	@kubectl logs -f -n qpoint pod/$$(kubectl get pods -l app.kubernetes.io/name=qtap -o jsonpath="{.items[0].metadata.name}" -n qpoint)

operator-logs: ## Stream the operator logs
	@kubectl logs -f -n qpoint pod/$$(kubectl get pods -l app.kubernetes.io/name=qtap-operator -o jsonpath="{.items[0].metadata.name}" -n qpoint)

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
