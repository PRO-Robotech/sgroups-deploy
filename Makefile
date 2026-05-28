PARENT_DIR     := $(abspath $(CURDIR)/..)

# Helm releases (also used as the in-cluster service / fullname for each chart)
SGROUPS_RELEASE     := sgroups
APISERVER_RELEASE   := sgroups-k8s-api
AGENT_RELEASE       := sgroups-agent
INCLOUD_WEB_RELEASE := incloud-web
RBAC_ENGINE_RELEASE := k8s-rbac-engine

SGROUPS_CHART       := deploy/charts/sgroups
APISERVER_CHART     := deploy/charts/sgroups-k8s-api
AGENT_CHART         := deploy/charts/sgroups-agent
INCLOUD_WEB_CHART   := oci://registry-1.docker.io/prorobotech/incloud-web-chart
RBAC_ENGINE_CHART   := oci://registry-1.docker.io/prorobotech/k8s-rbac-engine-chart

SGROUPS_VALUES      := deploy/values/sgroups.local.yaml
APISERVER_VALUES    := deploy/values/sgroups-k8s-api.local.yaml
AGENT_VALUES        := deploy/values/agent.local.yaml
INCLOUD_WEB_VALUES  := deploy/values/in-cloud-web.local.yaml
RBAC_ENGINE_VALUES  := deploy/values/k8s-rbac-engine.local.yaml

INCLOUD_WEB_VERSION := 1.5.0-rc1-3e32b82
RBAC_ENGINE_VERSION := 0.1.0-7833907

# Local image tags loaded into kind
IMAGE_BACKEND   := sgroups-backend:latest
IMAGE_MIGRATION := sgroups-migration:latest
IMAGE_APISERVER := sgroups-k8s-apiserver:latest
IMAGE_CONTROLLER := sgroups-k8s-controller:latest
IMAGE_AGENT     := sgroups-agent:latest

KIND_CLUSTER 		:= sgroups-dev
NAMESPACE    		:= sgroups-system
NAMESPACE_AGENT := sgroups-agent

CERT_MANAGER_VERSION := v1.17.2

.PHONY: up down \
        kind-create kind-delete \
        cert-manager \
        build build-backend build-migration build-apiserver build-controller build-agent \
        load \
        deploy undeploy \
        deploy-sgroups deploy-apiserver deploy-agent deploy-incloud-web deploy-incloud-web-rbac deploy-rbac-engine \
        undeploy-sgroups undeploy-apiserver undeploy-agent undeploy-incloud-web undeploy-incloud-web-rbac undeploy-rbac-engine \
        redeploy-backend redeploy-apiserver redeploy-agent redeploy-rbac-engine \
        status logs-backend logs-apiserver logs-agent logs-incloud-web logs-rbac-engine \
        proxy port-forward-backend port-forward-postgres \
        check-proxy check-backend check-postgres \
        pg-connections \
        test

# ─── Full lifecycle ───────────────────────────────────────────────

up: kind-create cert-manager build load deploy
	@echo "✓ sgroups stack is up. Run 'make status' to check."

down: undeploy kind-delete
	@echo "✓ sgroups stack is down."

# ─── Kind cluster ─────────────────────────────────────────────────

kind-create:
	@if ! kind get clusters 2>/dev/null | grep -q '^$(KIND_CLUSTER)$$'; then \
		kind create cluster --name $(KIND_CLUSTER) --config kind-config.yaml; \
	else \
		echo "Kind cluster '$(KIND_CLUSTER)' already exists"; \
	fi

kind-delete:
	kind delete cluster --name $(KIND_CLUSTER)

# ─── cert-manager ─────────────────────────────────────────────────

cert-manager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
	@echo "Waiting for cert-manager to be ready..."
	kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
	kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s
	kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=120s

# ─── Docker build ─────────────────────────────────────────────────

build: build-backend build-migration build-apiserver build-controller build-agent

build-backend:
	docker buildx build --load \
		-f $(PARENT_DIR)/sgroups/Dockerfile.server \
		-t $(IMAGE_BACKEND) \
		$(PARENT_DIR)/sgroups

build-migration:
	docker buildx build --load \
		-f $(PARENT_DIR)/sgroups/Dockerfile.goose \
		-t $(IMAGE_MIGRATION) \
		$(PARENT_DIR)/sgroups

build-apiserver:
	docker buildx build --load \
		--build-context sgroups-proto=$(PARENT_DIR)/sgroups-proto \
		-f $(PARENT_DIR)/sgroups-k8s-api/apiserver.Dockerfile \
		-t $(IMAGE_APISERVER) \
		$(PARENT_DIR)/sgroups-k8s-api

build-controller:
	docker buildx build --load \
		--build-context sgroups-proto=$(PARENT_DIR)/sgroups-proto \
		-f $(PARENT_DIR)/sgroups-k8s-api/controller.Dockerfile \
		-t $(IMAGE_CONTROLLER) \
		$(PARENT_DIR)/sgroups-k8s-api

build-agent:
	docker buildx build --load \
		-f $(PARENT_DIR)/sgroups/Dockerfile.agent \
		-t $(IMAGE_AGENT) \
		$(PARENT_DIR)/sgroups

# ─── Load images into Kind ────────────────────────────────────────

load:
	kind load docker-image $(IMAGE_BACKEND) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_MIGRATION) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_APISERVER) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_CONTROLLER) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_AGENT) --name $(KIND_CLUSTER)

# ─── Deploy / Undeploy (helm) ─────────────────────────────────────

deploy: deploy-sgroups deploy-apiserver deploy-agent deploy-incloud-web deploy-rbac-engine
	@echo "✓ All components deployed successfully."

undeploy: undeploy-rbac-engine undeploy-incloud-web undeploy-agent undeploy-apiserver undeploy-sgroups
	-kubectl delete namespace $(NAMESPACE) --ignore-not-found

deploy-sgroups:
	helm upgrade --install $(SGROUPS_RELEASE) $(SGROUPS_CHART) \
		-n $(NAMESPACE) --create-namespace \
		-f $(SGROUPS_VALUES) \
		--wait --timeout 300s
	@echo "✓ sgroups deployed."

deploy-apiserver:
	helm upgrade --install $(APISERVER_RELEASE) $(APISERVER_CHART) \
		-n $(NAMESPACE) --create-namespace \
		-f $(APISERVER_VALUES) \
		--wait --timeout 180s
	@echo "✓ sgroups-k8s-api deployed."

deploy-agent:
	helm upgrade --install $(AGENT_RELEASE) $(AGENT_CHART) \
		-n $(NAMESPACE_AGENT) --create-namespace \
		-f $(AGENT_VALUES) \
		--wait --timeout 180s
	@echo "✓ sgroups-agent deployed."

deploy-incloud-web: deploy-incloud-web-rbac
	helm upgrade --install $(INCLOUD_WEB_RELEASE) $(INCLOUD_WEB_CHART) \
		--version $(INCLOUD_WEB_VERSION) \
		-n $(NAMESPACE) --create-namespace \
		-f $(INCLOUD_WEB_VALUES) \
		--wait --timeout 180s
	@echo "✓ incloud-web deployed."

deploy-incloud-web-rbac:
	kubectl apply -f deploy/k8s/incloud-web-rbac.yaml

deploy-rbac-engine:
	helm upgrade --install $(RBAC_ENGINE_RELEASE) $(RBAC_ENGINE_CHART) \
		--version $(RBAC_ENGINE_VERSION) \
		-n $(NAMESPACE) --create-namespace \
		-f $(RBAC_ENGINE_VALUES) \
		--wait --timeout 180s
	@echo "✓ k8s-rbac-engine deployed."

undeploy-sgroups:
	-helm uninstall $(SGROUPS_RELEASE) -n $(NAMESPACE)

undeploy-apiserver:
	-helm uninstall $(APISERVER_RELEASE) -n $(NAMESPACE)

undeploy-agent:
	-helm uninstall $(AGENT_RELEASE) -n $(NAMESPACE)

undeploy-incloud-web:
	-helm uninstall $(INCLOUD_WEB_RELEASE) -n $(NAMESPACE)
	-$(MAKE) undeploy-incloud-web-rbac

undeploy-incloud-web-rbac:
	-kubectl delete -f deploy/k8s/incloud-web-rbac.yaml --ignore-not-found

undeploy-rbac-engine:
	-helm uninstall $(RBAC_ENGINE_RELEASE) -n $(NAMESPACE)

# ─── Selective redeploy ───────────────────────────────────────────

redeploy-backend: build-backend
	kind load docker-image $(IMAGE_BACKEND) --name $(KIND_CLUSTER)
	$(MAKE) deploy-sgroups
	kubectl rollout restart deployment/$(SGROUPS_RELEASE) -n $(NAMESPACE)
	kubectl rollout status deployment/$(SGROUPS_RELEASE) -n $(NAMESPACE) --timeout=180s

redeploy-apiserver: build-apiserver build-controller
	kind load docker-image $(IMAGE_APISERVER) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_CONTROLLER) --name $(KIND_CLUSTER)
	$(MAKE) deploy-apiserver
	kubectl rollout restart deployment/$(APISERVER_RELEASE) -n $(NAMESPACE)
	kubectl rollout status deployment/$(APISERVER_RELEASE) -n $(NAMESPACE) --timeout=180s

redeploy-agent: build-agent
	kind load docker-image $(IMAGE_AGENT) --name $(KIND_CLUSTER)
	$(MAKE) deploy-agent
	kubectl rollout restart daemonset/$(AGENT_RELEASE) -n $(NAMESPACE)
	kubectl rollout status daemonset/$(AGENT_RELEASE) -n $(NAMESPACE) --timeout=180s

redeploy-rbac-engine: build-rbac-engine
	kind load docker-image $(IMAGE_RBAC_ENGINE) --name $(KIND_CLUSTER)
	$(MAKE) deploy-rbac-engine
	kubectl rollout restart deployment/$(RBAC_ENGINE_RELEASE) -n $(NAMESPACE)
	kubectl rollout status deployment/$(RBAC_ENGINE_RELEASE) -n $(NAMESPACE) --timeout=180s

# ─── Observability ────────────────────────────────────────────────

status:
	kubectl -n $(NAMESPACE) get all

logs-backend:
	kubectl logs -f deployment/$(SGROUPS_RELEASE) -n $(NAMESPACE)

logs-apiserver:
	kubectl logs -f deployment/$(APISERVER_RELEASE) -n $(NAMESPACE)

logs-agent:
	kubectl logs -f daemonset/$(AGENT_RELEASE) -n $(NAMESPACE) -c agent

logs-incloud-web:
	kubectl logs -f deployment/$(INCLOUD_WEB_RELEASE) -n $(NAMESPACE)

logs-rbac-engine:
	kubectl logs -f deployment/$(RBAC_ENGINE_RELEASE) -n $(NAMESPACE)

# ─── Access ───────────────────────────────────────────────────────
#
# For Postman GUI:  make proxy  (leave running in a terminal)
# For direct gRPC:  make port-forward-backend
# For psql:         make port-forward-postgres

PROXY_PORT := 8001

proxy:
	@echo "K8s API proxy on http://localhost:$(PROXY_PORT)"
	@echo "  Tenants: http://localhost:$(PROXY_PORT)/apis/sgroups.io/v1alpha1/tenants"
	@echo "  Import tests/kind-proxy.postman_environment.json into Postman"
	kubectl proxy --port=$(PROXY_PORT)

port-forward-backend:
	@echo "gRPC/HTTP backend on localhost:9006"
	kubectl port-forward svc/$(SGROUPS_RELEASE) 9006:9006 -n $(NAMESPACE)

port-forward-postgres:
	@echo "PostgreSQL on localhost:15432"
	kubectl port-forward svc/$(SGROUPS_RELEASE)-postgresql 15432:5432 -n $(NAMESPACE)

# ─── Connection checks (run in a separate terminal while port-forward is active)

check-proxy:
	@curl -sf http://localhost:$(PROXY_PORT)/apis/sgroups.io/v1alpha1/tenants | \
		python3 -c "import sys,json; d=json.load(sys.stdin); print('✓ proxy OK — %d tenant(s)' % len(d.get('items',[])))" \
		|| echo "✗ proxy not reachable on port $(PROXY_PORT)"

check-backend:
	@curl -sf http://localhost:9006/healthcheck | \
		python3 -c "import sys,json; d=json.load(sys.stdin); print('✓ backend OK — healthy=%s, go=%s' % (d.get('healthy'), d.get('app',{}).get('go_version','?')))" \
		|| echo "✗ backend not reachable on port 9006"

check-postgres:
	@nc -z localhost 15432 2>/dev/null \
		&& echo "✓ postgres OK — port 15432 is open" \
		|| echo "✗ postgres not reachable on port 15432"

pg-connections:
	@kubectl exec -n $(NAMESPACE) $(SGROUPS_RELEASE)-postgresql-0 -- \
		env PGPASSWORD=sgroups psql -U sgroups -d sgroups -c \
		"SELECT pid, state, left(query,60) AS query, age(now(), backend_start) AS uptime FROM pg_stat_activity WHERE datname = 'sgroups' AND pid <> pg_backend_pid() ORDER BY backend_start;"

# ─── Tests ────────────────────────────────────────────────────────
#
# Runs tenant smoke tests via newman.
# Starts its own kubectl proxy if port $(PROXY_PORT) is free;
# reuses an existing one (from 'make proxy') if already running.

test:
	@if curl -sf http://localhost:$(PROXY_PORT)/api >/dev/null 2>&1 \
	   && curl -sf http://localhost:$(PROXY_PORT)/apis/sgroups.io/v1alpha1 >/dev/null 2>&1; then \
		echo "Using existing proxy on port $(PROXY_PORT)"; \
		npx newman run tests/sgroups-tenants.postman_collection.json \
			-e tests/kind-proxy.postman_environment.json \
			--folder "Pre-cleanup" \
			--folder "Setup" \
			--folder "Tenant CRUD" \
			--folder "Selectors" \
			--folder "Error Handling" \
			--folder "Immutability" \
			--folder "Cleanup" \
			--delay-request 100 \
			--reporters cli; \
	else \
		pkill -f "kubectl proxy.*--port=$(PROXY_PORT)" 2>/dev/null; sleep 0.5; \
		echo "Starting kubectl proxy on port $(PROXY_PORT)..."; \
		kubectl proxy --port=$(PROXY_PORT) &>/dev/null & PROXY_PID=$$!; \
		sleep 1; \
		npx newman run tests/sgroups-tenants.postman_collection.json \
			-e tests/kind-proxy.postman_environment.json \
			--folder "Pre-cleanup" \
			--folder "Setup" \
			--folder "Tenant CRUD" \
			--folder "Selectors" \
			--folder "Error Handling" \
			--folder "Immutability" \
			--folder "Cleanup" \
			--delay-request 100 \
			--reporters cli; \
		RC=$$?; \
		kill $$PROXY_PID 2>/dev/null; \
		exit $$RC; \
	fi
