# Centralized Multi-Cluster Kubernetes Observability (CMCKO)

> ME Cloud Computing Project

A lightweight centralized multi-cluster Kubernetes observability platform that uses
eBPF-based Grafana Beyla agents for zero-instrumentation L4/L7 telemetry collection
and centrally aggregates Kubernetes-aware metrics in Prometheus for unified Grafana
visualization and cross-cluster comparison.

---

## 🏗️ 3-System Distributed Architecture

```
  ┌─────────────────────────────────┐       ┌─────────────────────────────────┐
  │ System 1: macOS (OrbStack)      │       │ System 2: Windows (WSL2 k3s)    │
  │ • Cluster: cluster-01           │       │ • Cluster: cluster-02           │
  │ • Microservices (frontend/auth) │       │ • Microservices (frontend/auth) │
  │ • Beyla eBPF (4 L4 + 4 L7)      │       │ • Beyla eBPF (4 L4 + 4 L7)      │
  │ • NodePort :30080 (JMeter target)│      │ • NodePort :30080 (JMeter target)│
  │ • NodePort :30090 (Metrics)     │       │ • NodePort :30090 (Metrics)     │
  └────────────────┬────────────────┘       └────────────────┬────────────────┘
                   │                                         │
                   │ Scrape: <MAC_IP>:30090                  │ Scrape: <WSL_IP>:30090
                   └──────────────────┬──────────────────────┘
                                      │
                                      ▼
                       ┌─────────────────────────────┐
                       │ System 3: Windows (WSL2)    │
                       │ Central Metrics Display Hub │
                       │ • Prometheus Server (:9090) │
                       │ • Grafana Dashboard (:3000) │
                       │   (Unified L4 & L7 4+4)     │
                       └─────────────────────────────┘
```

---

## ⚡ Quick Start

### 1. System 1: macOS (OrbStack Single Cluster)
```bash
# Deploys single cluster-01 on OrbStack with 4 L4 + 4 L7 Beyla metrics:
./scripts/deploy.sh
```

### 2. External Traffic (Apache JMeter)
```bash
# Generate high-stress load (20-30 threads, 0ms think time, matching k6 throughput):
./jmeter/run-jmeter.sh localhost 30080 30 300 5 0

# Or run realistic user simulation (15 threads, 200ms think time):
./jmeter/run-jmeter.sh localhost 30080 15 300 5 200
```

### 3. System 2: Windows (WSL2 k3s Edge Cluster)
```bash
./scripts/setup-system2-wsl.sh
```

### 4. System 3: Windows (WSL2 Metrics Display Hub)
```bash
cd system3-hub
# Update SYSTEM_1_IP and SYSTEM_2_IP in prometheus.yml, then:
docker compose up -d
# Open Grafana: http://localhost:3000 (admin / admin)
```

---

## 📊 Monitored Metrics (4 L4 + 4 L7)

| Layer | Metric Name | eBPF PromQL / Telemetry |
| :--- | :--- | :--- |
| **L4** | **1. Network Throughput** | `sum(rate(befa_network_flow_bytes_total[1m])) by (k8s_cluster_name, transport)` |
| **L4** | **2. Connection Count** | `sum(rate(befa_network_flow_stats[1m])) by (k8s_cluster_name)` |
| **L4** | **3. Packets / Retransmissions** | `sum(rate(befa_network_flow_stats_tcp_retransmits_total[1m]))` |
| **L4** | **4. Network Latency (RTT)** | `histogram_quantile(0.95, sum(rate(befa_network_flow_stats_tcp_rtt_seconds_bucket[1m])) by (le, k8s_cluster_name))` |
| **L7** | **1. Request Rate** | `sum(rate(http_server_request_duration_seconds_count[1m])) by (k8s_cluster_name, service_name)` |
| **L7** | **2. Request Latency** | `histogram_quantile(0.95, sum(rate(http_server_request_duration_seconds_bucket[1m])) by (le, service_name))` |
| **L7** | **3. Error Rate (4xx / 5xx)** | `sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"[45].*"}[1m]))` |
| **L7** | **4. Payload Size (Req/Resp)** | `sum(rate(http_server_request_body_size_bytes_sum[1m])) by (service_name)` |

---

## 📖 Documentation
- [Deployment & Operations Guide](docs/deployment.md)
- [Architecture Manifesto](docs/architecture.md)
