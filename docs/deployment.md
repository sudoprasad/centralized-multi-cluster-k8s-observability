# Deployment Guide

## Prerequisites

- macOS (M1/M2/M3/M4) or Linux/WSL2
- Docker Desktop (running)
- Homebrew (macOS)

## Install tools (one time)

```bash
brew install kind kubectl helm
```

## Phase 0 — Single Cluster

### Option A: Automated (recommended)

```bash
cd /path/to/CMCKO
bash scripts/setup-phase0.sh
```

### Option B: Manual step-by-step

#### 1. Create cluster
```bash
kind create cluster --name cluster-01 --config clusters/cluster-01/kind-config.yaml
kubectl config use-context kind-cluster-01
kubectl get nodes  # should show Ready
```

#### 2. Deploy demo application
```bash
kubectl apply -f demo-app/namespace.yaml
kubectl apply -f demo-app/frontend.yaml
kubectl apply -f demo-app/backend.yaml
kubectl apply -f demo-app/auth.yaml
kubectl apply -f demo-app/traffic-gen.yaml
kubectl get pods -n demo  # wait for Running
```

#### 3. Install Prometheus
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  -n monitoring --create-namespace \
  -f prometheus/values.yaml
```

#### 4. Install Grafana
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  -n monitoring \
  -f grafana/values.yaml
```

#### 5. Install Beyla
```bash
helm install beyla grafana/beyla \
  -n beyla --create-namespace \
  -f beyla/values.yaml
```

#### 6. Access UIs
```bash
# Grafana — http://localhost:30000 (admin/admin)
# Prometheus — http://localhost:30001

# Alternative: use port-forward if NodePort doesn't work
kubectl port-forward svc/grafana 3000:80 -n monitoring
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

## Verify everything is working

```bash
bash scripts/verify-phase0.sh
```

## Tear down

```bash
bash scripts/teardown.sh
```
