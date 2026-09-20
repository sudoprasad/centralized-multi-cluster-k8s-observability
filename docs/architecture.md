# Architecture

## Phase 0 — Single Cluster (Current)

```
┌─────────────────────────────────────────────────────────┐
│                    kind cluster-01                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │              namespace: demo                     │   │
│  │   frontend  ──→  backend  ──→  auth              │   │
│  │      ↑                                           │   │
│  │  traffic-gen (continuous HTTP requests)          │   │
│  └──────────────────────────────────────────────────┘   │
│                         │                               │
│           HTTP traffic observed via eBPF                │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │              namespace: beyla                    │   │
│  │         Grafana Beyla (DaemonSet)                │   │
│  │         eBPF → /metrics (port 9090)              │   │
│  └──────────────────────────────────────────────────┘   │
│                         │                               │
│                  Prometheus scrape                      │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │            namespace: monitoring                 │   │
│  │   Prometheus ──PromQL──→ Grafana                 │   │
│  │   :30001 (NodePort)     :30000 (NodePort)        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
          │                              │
   localhost:30001               localhost:30000
    Prometheus UI                 Grafana UI


## Key Design Principles

1. **Zero instrumentation**: Applications (frontend/backend/auth) are standard
   containers with NO OpenTelemetry SDK, NO agents injected, NO code changes.

2. **eBPF passivity**: Beyla hooks into the Linux kernel via eBPF to observe
   all HTTP/TCP traffic without touching the application process.

3. **Kubernetes-aware**: Beyla enriches every metric with pod, namespace,
   deployment, and node labels from the Kubernetes API.

4. **Prometheus-native**: Beyla exposes standard Prometheus metrics.
   No custom storage, no Kafka, no custom backend.

## Component Roles

| Component | Role | Why |
|-----------|------|-----|
| kind | Local Kubernetes cluster | Works on macOS M4, no VM overhead |
| demo-app | Generates observable HTTP traffic | 3 microservices, no instrumentation |
| Grafana Beyla | eBPF telemetry collector | Zero-instrumentation L4/L7 metrics |
| Prometheus | Metrics storage + query | Standard, lightweight, PromQL |
| Grafana | Visualization | Standard, connects to Prometheus |

## Future Phases

```
Phase 0: Single cluster (current)
Phase 1: Add cluster="cluster-01" label to all metrics
Phase 2: Create cluster-02 with same stack
Phase 3: Central Prometheus with federation/remote-write
Phase 4: Multi-cluster Grafana dashboards (cluster variable)
Phase 5: Service relationship visualization
Phase 6: Optional — anomaly detection OR topology graph
```
