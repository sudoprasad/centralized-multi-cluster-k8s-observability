# Centralized Multi-Cluster Kubernetes Observability (CMCKO)

> ME Cloud Computing Mini-Project

A lightweight centralized multi-cluster Kubernetes observability platform that uses
eBPF-based Grafana Beyla agents for zero-instrumentation L4/L7 telemetry collection
and centrally aggregates Kubernetes-aware metrics in Prometheus for unified Grafana
visualization and cross-cluster comparison.

## Architecture Overview

```
Demo App → Beyla (eBPF) → Prometheus → Grafana
```

## Development Phases

| Phase | Goal | Status |
|-------|------|--------|
| 0 | Single cluster: K3s + Beyla + Prometheus + Grafana | 🚧 In Progress |
| 1 | Cluster identity labels | ⏳ Pending |
| 2 | Second cluster | ⏳ Pending |
| 3 | Centralized Prometheus | ⏳ Pending |
| 4 | Multi-cluster Grafana dashboards | ⏳ Pending |
| 5 | Service relationship visualization | ⏳ Pending |

## Quick Start (Phase 0)

```bash
# 1. Create local cluster
kind create cluster --config clusters/cluster-01/kind-config.yaml --name cluster-01

# 2. Deploy demo app
kubectl apply -f demo-app/

# 3. Install Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/prometheus -f prometheus/values.yaml -n monitoring --create-namespace
helm install grafana grafana/grafana -f grafana/values.yaml -n monitoring

# 4. Install Beyla
helm repo add grafana https://grafana.github.io/helm-charts
helm install beyla grafana/beyla -f beyla/values.yaml -n beyla --create-namespace

# 5. Access Grafana
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Open http://localhost:3000  admin/admin
```

## Key Design Decisions

- **No application instrumentation** — Beyla uses eBPF to observe traffic passively
- **No sidecars** — Beyla runs as a DaemonSet
- **Minimal dependencies** — Only K3s/kind, Beyla, Prometheus, Grafana
- **Incremental** — Each phase builds on the previous working state

## Repository Structure

```
CMCKO/
├── clusters/cluster-01/     # kind cluster config
├── demo-app/                # Demo microservices (frontend, backend, auth)
├── beyla/                   # Beyla Helm values + ServiceMonitor
├── prometheus/              # Prometheus Helm values + rules
├── grafana/                 # Grafana dashboards + provisioning
├── scripts/                 # Setup and utility scripts
└── docs/                    # Architecture, deployment, troubleshooting
```
