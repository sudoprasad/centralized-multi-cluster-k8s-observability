# Cluster 01 (System 1 — macOS OrbStack Edge Cluster)

Single-node Kind cluster running on macOS Apple Silicon via OrbStack.

## Specs & Published Ports

| Port | Protocol | Target / Purpose |
|---|---|---|
| `:30080` | HTTP / TCP | **Frontend Ingress** (Apache JMeter external load target) |
| `:30090` | HTTP / TCP | **Beyla eBPF Metrics Exporter** (Remote Prometheus scrape endpoint) |
| `:30000` | HTTP / TCP | Local Grafana Dashboard (via `monitoring/`) |
| `:30001` | HTTP / TCP | Local Prometheus UI (via `monitoring/`) |

## Quick Commands

```bash
# Set context
kubectl config use-context kind-cluster-01

# Inspect Pods
kubectl get pods -A

# Test JMeter Ingress
curl http://localhost:30080/

# Test Beyla Metrics Exporter
curl http://localhost:30090/metrics | head -n 20
```
