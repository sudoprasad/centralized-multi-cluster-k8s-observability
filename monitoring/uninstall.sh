#!/usr/bin/env bash
# =============================================================================
# Uninstall Local Prometheus and Grafana Monitoring from System 1
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

pass "Local monitoring stack uninstalled successfully."
