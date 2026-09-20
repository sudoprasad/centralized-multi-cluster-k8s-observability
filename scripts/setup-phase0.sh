#!/usr/bin/env bash
# =============================================================================
# setup-phase0.sh — CMCKO Phase 0 Setup
# =============================================================================
# Deploys the complete Phase 0 stack on your local machine:
#   kind cluster → demo app → Prometheus → Grafana → Beyla
#
# Prerequisites:
#   - Docker Desktop running
#   - kind, kubectl, helm installed (brew install kind kubectl helm)
#
# Usage:
#   bash scripts/setup-phase0.sh
#
# After setup:
#   Grafana:    http://localhost:30000   (admin/admin)
#   Prometheus: http://localhost:30001
# =============================================================================

set -euo pipefail

CLUSTER_NAME="cluster-01"
MONITORING_NS="monitoring"
BEYLA_NS="beyla"
DEMO_NS="demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Color helpers ─────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${GREEN}══════════════════════════════════════════${NC}"; \
            echo -e "${GREEN}  STEP: $*${NC}"; \
            echo -e "${GREEN}══════════════════════════════════════════${NC}"; }

# ── Prerequisite checks ───────────────────────────────────────────────────────
step "Checking prerequisites"

command -v docker  >/dev/null 2>&1 || error "docker not found. Install Docker Desktop."
command -v kind    >/dev/null 2>&1 || error "kind not found. Run: brew install kind"
command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Run: brew install kubectl"
command -v helm    >/dev/null 2>&1 || error "helm not found. Run: brew install helm"

docker info >/dev/null 2>&1 || error "Docker Desktop is not running. Please start it."

info "All prerequisites satisfied ✓"
info "kind:    $(kind version)"
info "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
info "helm:    $(helm version --short)"

# ── Step 1: Create kind cluster ───────────────────────────────────────────────
step "Creating kind cluster: $CLUSTER_NAME"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  warn "Cluster '$CLUSTER_NAME' already exists — skipping creation"
else
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --config "$PROJECT_DIR/clusters/cluster-01/kind-config.yaml"
  info "Cluster '$CLUSTER_NAME' created ✓"
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"
info "kubectl context set to kind-${CLUSTER_NAME} ✓"

# Wait for node to be Ready
info "Waiting for cluster node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes

# ── Step 2: Add Helm repos ────────────────────────────────────────────────────
step "Adding Helm repositories"

helm repo add grafana              https://grafana.github.io/helm-charts         2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
info "Helm repos updated ✓"

# ── Step 3: Deploy demo application ──────────────────────────────────────────
step "Deploying demo application"

kubectl apply -f "$PROJECT_DIR/demo-app/namespace.yaml"
kubectl apply -f "$PROJECT_DIR/demo-app/frontend.yaml"
kubectl apply -f "$PROJECT_DIR/demo-app/backend.yaml"
kubectl apply -f "$PROJECT_DIR/demo-app/auth.yaml"
kubectl apply -f "$PROJECT_DIR/demo-app/traffic-gen.yaml"

info "Waiting for demo pods to be Running..."
kubectl wait --for=condition=Ready pod --all -n "$DEMO_NS" --timeout=120s
kubectl get pods -n "$DEMO_NS"
info "Demo application deployed ✓"

# ── Step 4: Install Prometheus ────────────────────────────────────────────────
step "Installing Prometheus"

kubectl create namespace "$MONITORING_NS" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace "$MONITORING_NS" \
  --values "$PROJECT_DIR/prometheus/values.yaml" \
  --wait \
  --timeout 5m

info "Waiting for Prometheus server to be Ready..."
kubectl wait --for=condition=Ready pod \
  --selector="app.kubernetes.io/component=server" \
  -n "$MONITORING_NS" --timeout=180s

kubectl get pods -n "$MONITORING_NS"
info "Prometheus installed ✓"

# ── Step 5: Install Grafana ───────────────────────────────────────────────────
step "Installing Grafana"

helm upgrade --install grafana grafana/grafana \
  --namespace "$MONITORING_NS" \
  --values "$PROJECT_DIR/grafana/values.yaml" \
  --wait \
  --timeout 5m

kubectl get pods -n "$MONITORING_NS"
info "Grafana installed ✓"

# ── Step 6: Install Beyla ─────────────────────────────────────────────────────
step "Installing Grafana Beyla (eBPF observer)"

kubectl create namespace "$BEYLA_NS" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install beyla grafana/beyla \
  --namespace "$BEYLA_NS" \
  --values "$PROJECT_DIR/beyla/values.yaml" \
  --wait \
  --timeout 5m

kubectl get pods -n "$BEYLA_NS"
info "Beyla installed ✓"

# ── Step 7: Final status ──────────────────────────────────────────────────────
step "Phase 0 Setup Complete!"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          CMCKO Phase 0 — All systems running         ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Grafana:    http://localhost:30000  (admin/admin)   ║${NC}"
echo -e "${GREEN}║  Prometheus: http://localhost:30001                  ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Quick checks:                                       ║${NC}"
echo -e "${GREEN}║  kubectl get pods --all-namespaces                   ║${NC}"
echo -e "${GREEN}║  kubectl get pods -n demo                            ║${NC}"
echo -e "${GREEN}║  kubectl get pods -n beyla                           ║${NC}"
echo -e "${GREEN}║  kubectl get pods -n monitoring                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
warn "NOTE: It may take 2-3 minutes for Beyla to start capturing metrics."
warn "      In Grafana, check Explore → Prometheus → search for 'http_server_request'"
