PARENT_DIR     := $(abspath $(CURDIR)/..)
IMAGE_BACKEND  := sgroups-backend:latest
IMAGE_MIGRATION := sgroups-migration:latest
IMAGE_APISERVER := sgroups-k8s-apiserver:latest
KIND_CLUSTER   := sgroups-dev
NAMESPACE      := sgroups-system

CERT_MANAGER_VERSION := v1.17.2

.PHONY: up down \
        kind-create kind-delete \
        cert-manager \
        build build-backend build-migration build-apiserver \
        load \
        deploy undeploy \
        redeploy-backend redeploy-apiserver remigrate \
        status logs-backend logs-apiserver \
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

build: build-backend build-migration build-apiserver

build-backend:
	docker build -f docker/backend.Dockerfile -t $(IMAGE_BACKEND) $(PARENT_DIR)

build-migration:
	docker build -f docker/migration.Dockerfile -t $(IMAGE_MIGRATION) $(PARENT_DIR)

build-apiserver:
	docker build -f docker/apiserver.Dockerfile -t $(IMAGE_APISERVER) $(PARENT_DIR)

# ─── Load images into Kind ────────────────────────────────────────

load:
	kind load docker-image $(IMAGE_BACKEND) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_MIGRATION) --name $(KIND_CLUSTER)
	kind load docker-image $(IMAGE_APISERVER) --name $(KIND_CLUSTER)

# ─── Deploy / Undeploy ────────────────────────────────────────────

deploy:
	kubectl apply -k config/
	@echo "Waiting for PostgreSQL..."
	kubectl wait --for=condition=Ready pod -l app=sgroups-postgres -n $(NAMESPACE) --timeout=120s
	@echo "Waiting for migration job..."
	kubectl wait --for=condition=Complete job/sgroups-migration -n $(NAMESPACE) --timeout=120s
	@echo "Waiting for backend rollout..."
	kubectl rollout status deployment/sgroups-backend -n $(NAMESPACE) --timeout=120s
	@echo "Waiting for apiserver rollout..."
	kubectl rollout status deployment/sgroups-k8s-apiserver -n $(NAMESPACE) --timeout=120s
	@echo "✓ All components deployed successfully."

undeploy:
	kubectl delete -k config/ --ignore-not-found

# ─── Selective redeploy ───────────────────────────────────────────

redeploy-backend: build-backend
	kind load docker-image $(IMAGE_BACKEND) --name $(KIND_CLUSTER)
	kubectl rollout restart deployment/sgroups-backend -n $(NAMESPACE)
	kubectl rollout status deployment/sgroups-backend -n $(NAMESPACE) --timeout=120s

redeploy-apiserver: build-apiserver
	kind load docker-image $(IMAGE_APISERVER) --name $(KIND_CLUSTER)
	kubectl rollout restart deployment/sgroups-k8s-apiserver -n $(NAMESPACE)
	kubectl rollout status deployment/sgroups-k8s-apiserver -n $(NAMESPACE) --timeout=120s

remigrate: build-migration
	kind load docker-image $(IMAGE_MIGRATION) --name $(KIND_CLUSTER)
	-kubectl delete job/sgroups-migration -n $(NAMESPACE)
	kubectl apply -k config/
	kubectl wait --for=condition=Complete job/sgroups-migration -n $(NAMESPACE) --timeout=120s

# ─── Observability ────────────────────────────────────────────────

status:
	kubectl -n $(NAMESPACE) get all

logs-backend:
	kubectl logs -f deployment/sgroups-backend -n $(NAMESPACE)

logs-apiserver:
	kubectl logs -f deployment/sgroups-k8s-apiserver -n $(NAMESPACE)

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
	kubectl port-forward svc/sgroups-backend 9006:9006 -n $(NAMESPACE)

port-forward-postgres:
	@echo "PostgreSQL on localhost:15432"
	kubectl port-forward svc/sgroups-postgres 15432:5432 -n $(NAMESPACE)

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
	@kubectl exec -n $(NAMESPACE) sgroups-postgres-0 -- \
		psql -U user_admin -d sgroups -c \
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
			--folder "Watch" \
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
			--folder "Watch" \
			--folder "Cleanup" \
			--delay-request 100 \
			--reporters cli; \
		RC=$$?; \
		kill $$PROXY_PID 2>/dev/null; \
		exit $$RC; \
	fi
