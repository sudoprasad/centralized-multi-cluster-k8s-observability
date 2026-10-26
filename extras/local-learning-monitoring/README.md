# Local Prometheus & Grafana Monitoring (System 1)

This directory provides a **self-contained Prometheus and Grafana monitoring stack** running directly on your macOS cluster (`cluster-01`).

It scrapes eBPF Beyla metrics directly from your microservices and can also federate telemetry from **System 2 (Windows WSL2)** over Tailscale/LAN.

---

## 🚀 Quick Start

### 1. Deploy Monitoring Stack
```bash
# Monitor local System 1 (Mac):
./extras/local-learning-monitoring/install.sh

# Or monitor BOTH System 1 (Mac) and System 2 (WSL2):
./extras/local-learning-monitoring/install.sh <SYSTEM_2_IP>
```

### 2. Access UIs
- **Grafana Dashboard**: [http://localhost:30000](http://localhost:30000) (Login: `admin` / `admin`)
  - Auto-loaded with: **`CMCKO — Unified Multi-Cluster eBPF Observability`**
  - Features: Live Pods Inventory, HPA Autoscaling Curve, 4 L4 base metrics, 4 L7 RED metrics.
- **Prometheus UI**: [http://localhost:30001](http://localhost:30001)
- **Raw Beyla Metrics Egress**: [http://localhost:30090/metrics](http://localhost:30090/metrics)

---

## 🛑 Teardown / Uninstall

To remove Prometheus and Grafana and free ~400MB RAM:
```bash
./extras/local-learning-monitoring/uninstall.sh
```
