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

create-namespaces: kind ## Create the namespace for each app in apps directory
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		kubectl get namespace "$$ns" >/dev/null 2>&1 || kubectl create namespace "$$ns"; \
	done

label-namespaces-egress-service: kind ## Label the namespace for each app in apps directory with qpoint-egress=enabled
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-egress}' | grep -q 'enabled'; then \
			kubectl label namespace "$$ns" qpoint-egress=service --overwrite; \
		fi; \
	done

label-namespaces-egress-inject: kind ## Label the namespace for each app in apps directory with qpoint-injection=enabled
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-injection}' | grep -q 'enabled'; then \
			kubectl label namespace "$$ns" qpoint-egress=inject --overwrite; \
		fi; \
	done

label-namespaces-egress-disable: kind ## Label the namespace for each app in apps directory with qpoint-injection=enabled
	@for dir in apps/*/; do \
		ns=$$(basename "$$dir"); \
		if ! kubectl get namespace "$$ns" -o=jsonpath='{.metadata.labels.qpoint-injection}' | grep -q 'enabled'; then \
			kubectl label namespace "$$ns" qpoint-egress=disable --overwrite; \
		fi; \
	done

up: ensure-deps ensure-images cluster cert-manager upload-images create-namespaces ## Bring up the demo environment

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

simple: up ## Deploy the "simple" app for curl'ing external APIs
	@kubectl delete -f apps/simple/deployment.yaml --ignore-not-found
	@kubectl apply -f apps/simple/deployment.yaml

artillery: up ## Deploy the "artillery" app for hammering multiple APIs
	@kubectl delete -f apps/artillery/deployment.yaml --ignore-not-found
	@kubectl apply -f apps/artillery/deployment.yaml

datadog: up ## Deploy the "datadog" app for reporting to datadog
	@helm uninstall datadog-agent -n datadog --ignore-not-found
	@helm repo add datadog https://helm.datadoghq.com
	@helm repo update
	@helm install datadog-agent -f apps/datadog/values.yaml datadog/datadog -n datadog

newrelic: up ## Deploy the "newrelic" app for reporting to newrelic
	@helm uninstall newrelic-bundle -n newrelic --ignore-not-found
	@helm repo add newrelic https://helm-charts.newrelic.com
	@helm repo update
	@helm install newrelic-bundle newrelic/nri-bundle -f apps/newrelic/values.yaml -n newrelic

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

docker: ## Ensure docker is installed and running
	@docker info > /dev/null 2>&1 || (echo "Error: Docker must be installed and running" && exit 1 )

kubectl: ## Ensure kubectl is installed
	@which kubectl > /dev/null 2>&1 || (echo "Error: Kubectl must be installed" && exit 1)

kind: ## Ensure kind is installed
	@which kind > /dev/null 2>&1 || (echo "Error: KinD must be installed" && exit 1)

helm: ## Ensure helm is installed
	@which kind > /dev/null 2>&1 || (echo "Error: Helm must be installed" && exit 1)

ensure-deps: docker kubectl kind helm ## Ensure all dependencies are ready
