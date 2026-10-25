#!/usr/bin/env bash
# =============================================================================
# Optional Local Learning Monitoring for System 1 (macOS)
# Deploys Prometheus (:30001) and Grafana (:30000) locally on cluster-01
# (Completely separated from the main Option A architecture flow)
#
# USAGE:
#   chmod +x extras/local-learning-monitoring/install.sh
#   ./extras/local-learning-monitoring/install.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)] $*${NC}"; }
pass() { echo -e "${GREEN}✅ $*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log "Deploying local learning monitoring on cluster-01..."
kubectl config use-context kind-cluster-01
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy local Prometheus
log "Deploying Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update prometheus-community

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values "$SCRIPT_DIR/values-prometheus.yaml" \
  --wait --timeout 5m

# Deploy local Grafana
log "Deploying Grafana with CMCKO Unified Dashboards..."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update grafana

kubectl create configmap grafana-dashboards-cmcko \
  --from-file=cluster-overview.json="$ROOT/grafana/dashboards/cluster-overview.json" \
  --from-file=application-traffic.json="$ROOT/grafana/dashboards/application-traffic.json" \
  -n monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values "$SCRIPT_DIR/values-grafana.yaml" \
  --wait --timeout 5m

pass "Local learning monitoring is live!"
echo ""
echo "  Grafana Dashboard:  http://localhost:30000  (admin / admin)"
echo "  Local Prometheus:   http://localhost:30001"
echo ""
echo "  To remove and revert to pure Option A edge node:"
echo "    ./extras/local-learning-monitoring/uninstall.sh"
echo "═══════════════════════════════════════════════════════════════════"
