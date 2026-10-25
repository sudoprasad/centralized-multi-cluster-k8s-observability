#!/usr/bin/env bash
# =============================================================================
# teardown.sh — Remove CMCKO System 1 (macOS OrbStack) Kind Cluster
# =============================================================================
# WARNING: Deletes the local kind cluster and all local telemetry data.
# =============================================================================

set -euo pipefail

echo "Tearing down CMCKO System 1 (cluster-01)..."
docker context use orbstack 2>/dev/null || true

if kind get clusters 2>/dev/null | grep -q "^cluster-01$"; then
  echo "Deleting kind cluster: cluster-01"
  kind delete cluster --name cluster-01
else
  echo "cluster-01 does not exist, skipping."
fi

echo "Teardown complete."
