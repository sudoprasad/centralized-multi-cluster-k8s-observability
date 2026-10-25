#!/usr/bin/env bash
# =============================================================================
# CMCKO — System 2 (Windows WSL2 with k3s)
# Edge Cluster: cluster-02
# Zero-Instrumentation eBPF Observability (4 L4 + 4 L7 Metrics)
#
# USAGE:
#   chmod +x scripts/setup-system2-wsl.sh
#   ./scripts/setup-system2-wsl.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)] $*${NC}"; }
pass() { echo -e "${GREEN}✅ $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log "Checking k3s / Kubernetes context..."
kubectl get nodes || fail "Kubernetes is not responding. Ensure k3s is running."
pass "Kubernetes node is active on WSL2"

log "Deploying target microservices (frontend on NodePort 30080)..."
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$ROOT/target-app/"
kubectl rollout status deployment/frontend -n demo --timeout=120s
kubectl rollout status deployment/backend -n demo --timeout=120s
kubectl rollout status deployment/auth -n demo --timeout=120s
pass "Target microservices deployed on WSL2"

log "Deploying Grafana Beyla on WSL2 k3s..."
kubectl create namespace beyla --dry-run=client -o yaml | kubectl apply -f -
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update grafana

helm upgrade --install beyla grafana/beyla \
  --namespace beyla \
  --values "$ROOT/beyla/values.yaml" \
  --set env.BEYLA_KUBE_CLUSTER_NAME="cluster-02" \
  --wait --timeout 3m

kubectl apply -f "$ROOT/beyla/beyla-nodeport.yaml"
pass "Beyla eBPF active with L4 & L7 metrics exposed on NodePort 30090"

WSL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  CMCKO System 2 (WSL2 k3s) is fully deployed!"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Cluster:                 cluster-02 (WSL2)"
echo "  WSL2 IP:                 $WSL_IP"
echo ""
echo "  [EXTERNAL INGRESS - JMeter Load Target]:"
echo "  Target URL for JMeter:   http://$WSL_IP:30080/"
echo ""
echo "  [METRICS EGRESS - For System 3 Central Scraper]:"
echo "  Beyla NodePort:          http://$WSL_IP:30090/metrics"
echo "═══════════════════════════════════════════════════════════════════"
