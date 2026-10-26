#!/usr/bin/env bash
# =============================================================================
# CMCKO — System 1 (macOS OrbStack / Kind)
# Edge Cluster Deployment: cluster-01
# Zero-code eBPF telemetry with Beyla (4 L4 + 4 L7 metrics)
#
# Usage:
#   ./scripts/deploy.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)] $*${NC}"; }
pass() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# -----------------------------------------------------------------------------
# STEP 1: Verify docker context and single cluster-01
# -----------------------------------------------------------------------------
log "STEP 1: Initializing cluster-01 on OrbStack..."
docker context use orbstack 2>/dev/null || true
if ! kind get clusters 2>/dev/null | grep -q "^cluster-01$"; then
  kind create cluster --config "$ROOT/clusters/cluster-01/kind-config.yaml"
  # Prevent Kind container from auto-starting when OrbStack opens
  docker update --restart=no cluster-01-control-plane 2>/dev/null || true
  pass "cluster-01 created (auto-start disabled)"
else
  # Ensure auto-restart remains disabled
  docker update --restart=no cluster-01-control-plane 2>/dev/null || true
  pass "cluster-01 already exists"
fi

kubectl config use-context kind-cluster-01
kubectl wait --for=condition=Ready node --all --timeout=120s
pass "cluster-01 node is Ready"

# -----------------------------------------------------------------------------
# STEP 2: Deploy target microservices (frontend NodePort 30080)
# -----------------------------------------------------------------------------
log "STEP 2: Deploying target microservices (frontend on NodePort 30080)..."
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$ROOT/target-app/"
kubectl rollout status deployment/frontend -n demo --timeout=120s
kubectl rollout status deployment/backend -n demo --timeout=120s
kubectl rollout status deployment/auth -n demo --timeout=120s
pass "Target microservices deployed (Traffic driven exclusively by external JMeter)"

# -----------------------------------------------------------------------------
# STEP 3: Deploy Beyla eBPF DaemonSet (4 L4 + 4 L7 Metrics)
# -----------------------------------------------------------------------------
log "STEP 3: Deploying Grafana Beyla eBPF DaemonSet on cluster-01..."
kubectl create namespace beyla --dry-run=client -o yaml | kubectl apply -f -
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update grafana

helm upgrade --install beyla grafana/beyla \
  --namespace beyla \
  --values "$ROOT/beyla/values.yaml" \
  --wait --timeout 3m

# Expose metrics on NodePort 30090 for Prometheus scraping
kubectl apply -f "$ROOT/beyla/beyla-nodeport.yaml"
pass "Beyla eBPF active with L4 & L7 metrics exposed on NodePort 30090"

# -----------------------------------------------------------------------------
# Output status and connection info
# -----------------------------------------------------------------------------
MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  CMCKO System 1 (macOS OrbStack) Edge Cluster is Ready"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Cluster:                 cluster-01"
echo "  Host LAN IP:             $MAC_IP"
echo ""
echo "  [TRAFFIC INGRESS - JMeter Load Target]:"
echo "  Target URL:              http://$MAC_IP:30080/"
echo "                           http://localhost:30080/"
echo ""
echo "  [METRICS SCRAPE ENDPOINT]:"
echo "  Beyla NodePort:          http://$MAC_IP:30090/metrics"
echo ""
echo "  [LOCAL PROMETHEUS & GRAFANA MONITORING]:"
echo "  To inspect metrics locally on this Mac, run:"
echo "    ./monitoring/install.sh"
echo "  (Starts local Grafana at http://localhost:30000 and Prom at :30001)"
echo "═══════════════════════════════════════════════════════════════════"
