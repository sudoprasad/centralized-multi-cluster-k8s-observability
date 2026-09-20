# Cluster 01 — README

Local kind cluster for Phase 0 (single-cluster proof of concept).

## Specs

| Property | Value |
|----------|-------|
| Name | `cluster-01` |
| Type | kind (Kubernetes IN Docker) |
| Nodes | 1 control-plane |
| Kubernetes | v1.37.0 |
| Grafana NodePort | :30000 |
| Prometheus NodePort | :30001 |

## Commands

```bash
# Create
kind create cluster --name cluster-01 --config kind-config.yaml

# Set context
kubectl config use-context kind-cluster-01

# Status
kubectl get nodes
kubectl get pods --all-namespaces

# Delete
kind delete cluster --name cluster-01
```

## Namespaces

| Namespace | Contents |
|-----------|---------|
| `demo` | frontend, backend, auth, traffic-gen |
| `beyla` | Grafana Beyla DaemonSet |
| `monitoring` | Prometheus, Grafana |
