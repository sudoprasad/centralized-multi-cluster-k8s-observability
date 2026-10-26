#!/usr/bin/env bash
# =============================================================================
# CMCKO — Local Prometheus & Grafana Monitoring for System 1 (macOS)
# Deploys Prometheus (:30001) and Grafana (:30000) directly on cluster-01
# Scrapes local eBPF Beyla metrics and optionally federates System 2 (WSL2)
#
# USAGE:
#   # Deploy for local System 1 only:
#   ./extras/local-learning-monitoring/install.sh
#
#   # Deploy and also scrape System 2 (WSL2) over Tailscale:
#   ./extras/local-learning-monitoring/install.sh <SYSTEM_2_IP>
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)] $*${NC}"; }
pass() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }

SYSTEM_2_IP="${1:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log "Verifying Kubernetes context on cluster-01..."
kubectl config use-context kind-cluster-01
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Prepare Prometheus values
PROM_VALUES="$SCRIPT_DIR/values-prometheus.yaml"
TMP_PROM_VALUES=""
if [ -n "$SYSTEM_2_IP" ]; then
  log "Configuring Prometheus to also scrape System 2 at $SYSTEM_2_IP:30090..."
  TMP_PROM_VALUES=$(mktemp)
  sed "s/SYSTEM_2_IP/$SYSTEM_2_IP/g" "$PROM_VALUES" > "$TMP_PROM_VALUES"
  PROM_VALUES="$TMP_PROM_VALUES"
fi

# Deploy local Prometheus
log "Deploying Prometheus (v2.51+)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update prometheus-community

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values "$PROM_VALUES" \
  --wait --timeout 3m

if [ -n "$TMP_PROM_VALUES" ] && [ -f "$TMP_PROM_VALUES" ]; then
  rm -f "$TMP_PROM_VALUES"
fi
pass "Prometheus deployed on NodePort 30001"

# Prepare and apply Grafana dashboards ConfigMap
log "Provisioning CMCKO Unified Dashboard (L4 + L7 + HPA)..."
kubectl create configmap grafana-dashboards-cmcko \
  --from-file=application-traffic.json="$ROOT/grafana/dashboards/application-traffic.json" \
  -n monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy local Grafana
log "Deploying Grafana (v10.4+)..."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update grafana

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values "$SCRIPT_DIR/values-grafana.yaml" \
  --wait --timeout 3m

pass "Grafana deployed on NodePort 30000"

MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  CMCKO Local Monitoring Stack is Live on System 1!"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Grafana Dashboard:       http://localhost:30000"
echo "                           http://$MAC_IP:30000"
echo "  Credentials:             admin / admin"
echo ""
echo "  Prometheus UI:           http://localhost:30001"
echo "  Beyla eBPF Scrape URL:   http://localhost:30090/metrics"
echo ""
echo "  Dashboard included:      CMCKO — Unified Multi-Cluster eBPF Observability"
echo "                           (Live Pods, HPA Autoscaling, 4 L4, 4 L7 Metrics)"
echo ""
echo "  To uninstall and free resources:"
echo "    ./extras/local-learning-monitoring/uninstall.sh"
echo "═══════════════════════════════════════════════════════════════════"
