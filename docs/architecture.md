# CMCKO Architecture

> 📖 **Full Architecture Flow & End-to-End Specification**: For the complete diagram, sequence diagrams, and PromQL metric breakdown across the 3 physical/virtual systems, see **[docs/architecture-flow.md](architecture-flow.md)**.

---

## 🏗️ 3-System Distributed Architecture (Option A)

The CMCKO platform operates in an **Option A Centralized Pull Model**:

```
                       ┌──────────────────────────────────────────────┐
                       │          EXTERNAL TRAFFIC GENERATOR          │
                       │          Apache JMeter (Client PC)           │
                       └───────┬──────────────────────────────┬───────┘
                               │                              │
                 HTTP GET /    │                              │ HTTP GET /
                 Port :30080   ▼                              ▼ Port :30080
   ┌─────────────────────────────────────────┐  ┌─────────────────────────────────────────┐
   │     SYSTEM 1: DATA PRODUCER (macOS)     │  │    SYSTEM 2: DATA PRODUCER (WSL2 k3s)   │
   │  • Cluster: cluster-01                  │  │  • Cluster: cluster-02                  │
   │  • Microservices: frontend, backend,    │  │  • Microservices: frontend, backend,    │
   │    auth (Zero-Instrumentation)          │  │    auth (Zero-Instrumentation)          │
   │  • Grafana Beyla eBPF DaemonSet         │  │  • Grafana Beyla eBPF DaemonSet         │
   │    (4 L4 + 4 L7 Metrics)                │  │    (4 L4 + 4 L7 Metrics)                │
   │  • NodePort :30090 (/metrics)           │  │  • NodePort :30090 (/metrics)           │
   └────────────────────┬────────────────────┘  └────────────────────┬────────────────────┘
                        │                                            │
                        │ HTTP GET /metrics                          │ HTTP GET /metrics
                        │ Port :30090 (Pull every 5s)                │ Port :30090 (Pull every 5s)
                        └──────────────────────┬─────────────────────┘
                                               │
                                               ▼
                       ┌──────────────────────────────────────────────┐
                       │      SYSTEM 3: CENTRAL MONITORING HUB        │
                       │           (Windows WSL2 Environment)         │
                       │  • Prometheus Server (:9090)                 │
                       │  • Grafana Dashboard (:3000)                 │
                       │    Unified 4 L4 + 4 L7 Multi-Cluster Board   │
                       └──────────────────────────────────────────────┘
```

---

## 🔑 Key Design Principles

1. **Zero Instrumentation**: Microservices (`frontend`, `backend`, `auth`) are stock Go containers with **no OpenTelemetry SDK**, **no bytecode agents**, and **zero code changes**.
2. **eBPF Kernel Passivity**: Grafana Beyla attaches non-intrusively to kernel tracepoints, socket operations, and userspace uprobes.
3. **Pure Edge Nodes**: Edge clusters run no Prometheus TSDB engines, minimizing CPU and RAM overhead.
4. **External Client Traffic**: In-cluster traffic generators are deactivated (`replicas: 0`). External load is injected via **Apache JMeter** hitting NodePort `30080`.
5. **Decoupled Local Learning**: An optional local Prometheus and Grafana instance can be installed on System 1 (`extras/local-learning-monitoring/`) for offline study without impacting the distributed pipeline.
