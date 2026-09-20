#!/usr/bin/env bash
# =============================================================================
# verify-phase0.sh — Verify all Phase 0 components are healthy
# =============================================================================
# Run this after setup-phase0.sh to confirm everything is working.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
PASS="✅"; FAIL="❌"; WARN="⚠️ "

pass() { echo -e "${GREEN}${PASS} $*${NC}"; }
fail() { echo -e "${RED}${FAIL} $*${NC}"; }
warn() { echo -e "${YELLOW}${WARN} $*${NC}"; }

echo ""
echo "═══════════════════════════════════════════════════"
echo "    CMCKO Phase 0 — Verification Report"
echo "═══════════════════════════════════════════════════"

# ── Cluster ────────────────────────────────────────────────────────────────────
echo -e "\n[1] Cluster"
if kubectl get nodes --no-headers 2>/dev/null | grep -q " Ready"; then
  NODES=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
  pass "Cluster is running ($NODES node(s))"
  kubectl get nodes
else
  fail "No Ready nodes found"
fi

# ── Demo App ───────────────────────────────────────────────────────────────────
echo -e "\n[2] Demo Application (namespace: demo)"
DEMO_RUNNING=$(kubectl get pods -n demo --no-headers 2>/dev/null | grep -c "Running" || echo 0)
DEMO_TOTAL=$(kubectl get pods -n demo --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEMO_RUNNING" -ge 3 ]; then
  pass "$DEMO_RUNNING/$DEMO_TOTAL demo pods Running"
  kubectl get pods -n demo
else
  fail "Only $DEMO_RUNNING/$DEMO_TOTAL demo pods Running"
  kubectl get pods -n demo
fi

# ── Prometheus ──────────────────────────────────────────────────────────────────
echo -e "\n[3] Prometheus (namespace: monitoring)"
PROM_RUNNING=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep "prometheus-server" | grep -c "Running" || echo 0)
if [ "$PROM_RUNNING" -ge 1 ]; then
  pass "Prometheus server is Running"
else
  fail "Prometheus server not Running"
fi
kubectl get pods -n monitoring

# ── Grafana ────────────────────────────────────────────────────────────────────
echo -e "\n[4] Grafana (namespace: monitoring)"
GRAFANA_RUNNING=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep "grafana" | grep -c "Running" || echo 0)
if [ "$GRAFANA_RUNNING" -ge 1 ]; then
  pass "Grafana is Running"
else
  fail "Grafana not Running"
fi

# ── Beyla ──────────────────────────────────────────────────────────────────────
echo -e "\n[5] Beyla (namespace: beyla)"
BEYLA_RUNNING=$(kubectl get pods -n beyla --no-headers 2>/dev/null | grep -c "Running" || echo 0)
if [ "$BEYLA_RUNNING" -ge 1 ]; then
  pass "$BEYLA_RUNNING Beyla DaemonSet pod(s) Running"
else
  fail "Beyla not Running"
fi
kubectl get pods -n beyla

# ── Beyla metrics endpoint ─────────────────────────────────────────────────────
echo -e "\n[6] Beyla Metrics Endpoint"
BEYLA_POD=$(kubectl get pods -n beyla -o name 2>/dev/null | head -1)
if [ -n "$BEYLA_POD" ]; then
  METRICS_CHECK=$(kubectl exec -n beyla "$BEYLA_POD" -- wget -q -O - http://localhost:9090/metrics 2>/dev/null | head -5 || echo "FAIL")
  if echo "$METRICS_CHECK" | grep -q "^#"; then
    pass "Beyla /metrics endpoint is responding"
    echo "  Sample output:"
    echo "$METRICS_CHECK" | head -3 | sed 's/^/  /'
  else
    warn "Beyla metrics not yet available (may need 1-2 more minutes)"
  fi
else
  fail "No Beyla pod found"
fi

# ── Prometheus scraping Beyla ──────────────────────────────────────────────────
echo -e "\n[7] Prometheus scraping Beyla"
warn "Check manually: http://localhost:30001/targets"
warn "Look for 'beyla' in the targets list with State=UP"

# ── Access URLs ────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Access URLs:"
echo "  Grafana:    http://localhost:30000  (admin/admin)"
echo "  Prometheus: http://localhost:30001"
echo "═══════════════════════════════════════════════════"
echo ""
warn "Tip: In Grafana → Explore → Prometheus → search:"
warn "     http_server_request_duration_seconds"
warn "     beyla_network_flow_bytes_total"
echo ""
