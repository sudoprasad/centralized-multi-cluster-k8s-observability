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

### 4. Local Prometheus & Grafana Monitoring (System 1)
```bash
# Deploys Prometheus (:30001) & Grafana (:30000) with Live Pods, HPA & L4/L7 Dashboards:
./monitoring/install.sh

# Open Grafana: http://localhost:30000 (admin / admin)
# Open Prometheus: http://localhost:30001
# Any external system (e.g. System 3) can also scrape your Beyla metrics directly at:
# http://<YOUR_TAILSCALE_IP>:30090/metrics
```

---

## 📊 Monitored Metrics (Pod Lifecycle, HPA Autoscaling, 4 L4 + 4 L7)

| Category | Telemetry Metric | Scraped PromQL Query | Description / Purpose |
| :--- | :--- | :--- | :--- |
| **Autoscaling** | **HPA Controller State** | `kube_horizontalpodautoscaler_status_current_replicas{namespace="demo"}` | Desired vs Current replicas & Min/Max boundary tracking |
| **Pod Lifecycle** | **Deployment Readiness** | `sum by (deployment) (kube_deployment_status_replicas_ready{namespace="demo"})` | Ready vs unavailable pod transitions during traffic spikes |
| **L4 Transport** | **1. Network Throughput** | `sum by (cluster, k8s_src_owner_name) (rate(beyla_network_flow_bytes_total{direction="request"}[1m]))` | Real-time directional byte bandwidth (Sent vs Recv) |
| **L4 Transport** | **2. TCP Socket Table** | `sum(node_sockstat_TCP_inuse)` & `sum(node_sockstat_TCP_alloc)` | Kernel-level active TCP sockets and memory table under load |
| **L4 Transport** | **3. Service Mesh Flow Matrix** | `sum by (k8s_src_owner_name, k8s_dst_owner_name) (rate(beyla_network_flow_bytes_total[1m]))` | Directional traffic distribution matrix between microservices |
| **L4 Transport** | **4. Node Physical NIC I/O** | `sum by (device) (rate(node_network_receive_bytes_total{device="eth0"}[1m]))` | Real physical network interface bandwidth (RX/TX) |
| **L7 Application** | **1. Request Rate (RPS)** | `sum by (cluster, service_name) (rate(http_server_request_duration_seconds_count[1m]))` | Requests per second (RPS) per microservice via eBPF |
| **L7 Application** | **2. Request Latency** | `histogram_quantile(0.95, sum by (le, cluster, service_name) (rate(http_server_request_duration_seconds_bucket[1m])))` | p50, p95, and p99 response duration distributions |
| **L7 Application** | **3. Error Rate** | `sum by (cluster, service_name) (rate(http_server_request_duration_seconds_count{http_response_status_code=~"[45].."}[1m]))` | 4xx client and 5xx server HTTP error rates & status ratio |
| **L7 Application** | **4. Payload Volumes** | `sum by (cluster, service_name) (rate(http_server_request_body_size_bytes_sum[1m]))` | Inbound request and outbound response HTTP body transfer |

---

## 📖 Documentation
- [Deployment & Operations Guide](docs/deployment.md)
- [Architecture Manifesto](docs/architecture.md)
