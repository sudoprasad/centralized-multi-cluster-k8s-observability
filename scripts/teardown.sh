#!/usr/bin/env bash
# =============================================================================
# teardown.sh — Remove everything created by setup-phase0.sh
# =============================================================================
# WARNING: This deletes the entire kind cluster and all data.
# Only run this when you want a completely clean reset.
# =============================================================================

set -euo pipefail

CLUSTER_NAME="${1:-cluster-01}"
echo "Deleting kind cluster: $CLUSTER_NAME"
kind delete cluster --name "$CLUSTER_NAME" && echo "Done."
