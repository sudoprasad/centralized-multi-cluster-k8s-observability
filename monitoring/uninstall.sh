#!/usr/bin/env bash
# =============================================================================
# Uninstall Local Learning Monitoring from System 1
# Removes Prometheus and Grafana from cluster-01, reverting it to a pure edge node.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)] $*${NC}"; }
pass() { echo -e "${GREEN}✅ $*${NC}"; }

log "Removing local Prometheus and Grafana from cluster-01..."
kubectl config use-context kind-cluster-01

helm uninstall grafana -n monitoring 2>/dev/null || true
helm uninstall prometheus -n monitoring 2>/dev/null || true
kubectl delete configmap grafana-dashboards-cmcko -n monitoring 2>/dev/null || true
kubectl delete namespace monitoring 2>/dev/null || true

pass "Local monitoring uninstalled. cluster-01 is now a pure Option A edge node!"
