# CMCKO Deployment & Operations Guide

This guide covers deployment, daily operation workflows, and architecture for the **Centralized Multi-Cluster Kubernetes Observability (CMCKO)** platform across a distributed 3-system environment.

---

## 1. Architecture Overview

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
                       │ Central Metrics Display Hub │
                       │ • Prometheus Server (:9090) │
                       │ • Grafana Dashboard (:3000) │
                       │   (Unified L4 & L7 4+4)     │
                       └─────────────────────────────┘
```

---

## 2. System 1: macOS Edge Cluster

### Prerequisites:
- **OrbStack** running with Docker engine enabled.
- In OrbStack Settings: **Kubernetes turned OFF** (avoids duplicate cluster overhead and port conflicts with Kind).
- Installed CLI tools: `brew install kind kubectl helm`.

### Deployment:
```bash
# Deploys single cluster-01, target app, and Beyla eBPF (with NodePort 30080 & 30090)
./scripts/deploy.sh
```

### Daily Operations (Pause & Resume):
#### Stop Cluster (Free RAM):
```bash
docker stop cluster-01-control-plane
orbctl stop
```

#### Start Cluster (Resume):
```bash
open -a OrbStack
docker start cluster-01-control-plane
kubectl get nodes
```

---

## 3. System 2: Windows WSL2 Edge Cluster

### Prerequisites:
- Windows 10/11 with WSL2 Ubuntu (kernel >= 5.15 for eBPF).
- k3s installed (`curl -sfL https://get.k3s.io | sh -`).

### Deployment:
```bash
chmod +x scripts/setup-system2-wsl.sh
./scripts/setup-system2-wsl.sh
```

---

## 4. Local Prometheus & Grafana Stack (System 1)

### Deployment:
1. Deploy Prometheus (:30001) and Grafana (:30000) directly on cluster-01:
   ```bash
   ./monitoring/install.sh
   ```
   *(Or optionally pass `<SYSTEM_2_IP>` to also scrape System 2 over Tailscale)*:
   ```bash
   ./monitoring/install.sh 100.x.y.z
   ```
2. Access Local Observability:
   - **Grafana Dashboard**: `http://localhost:30000` (Login: `admin` / `admin`)
   - **Prometheus UI**: `http://localhost:30001`
   - Pre-loaded with: **`CMCKO — Unified Multi-Cluster eBPF Observability (L4 + L7 + HPA)`**

### Remote Metric Scrape Target:
External Prometheus instances can pull Beyla eBPF metrics directly from:
`http://<NODE_IP>:30090/metrics`

---

## 5. Traffic Generation (Apache JMeter)

Traffic is generated externally against the microservices:

### Run via Shell Script (macOS / Linux):
```bash
# High-Stress Load (0ms think time, default):
./jmeter/run-jmeter.sh localhost 30080 30 300 5 0

# Target over Tailscale / LAN:
./jmeter/run-jmeter.sh 100.110.71.94 30080 30 300 5 0

# Realistic user simulation (200ms think time):
./jmeter/run-jmeter.sh 100.110.71.94 30080 15 300 5 200
```

### Run via PowerShell (Windows):
```powershell
# High-stress load:
.\jmeter\run-jmeter.ps1 -TargetHost "100.110.71.94" -TargetPort 30080 -Threads 30 -Duration 300 -ThinkTime 0
```

### Run via Docker (No JMeter installation required):
```bash
docker run --rm -i -v "$PWD/jmeter":/jmeter justb4/jmeter:latest \
  -n -t /jmeter/cmcko-traffic-test.jmx \
  -Jtarget.host="100.110.71.94" -Jtarget.port="30080" -Jthreads=30 -Jduration=300 -Jthinktime=0
```

---

## Monitored Telemetry (4 L4 + 4 L7)

### Layer 4 (Network & Transport)
1. **Network Throughput**: Directional bytes sent and received via `beyla_network_flow_bytes_total`
2. **TCP Socket Table**: Active established and allocated kernel sockets via `node_sockstat_TCP_inuse`
3. **Service Mesh Flow Matrix**: Directional inter-service flow volume via `beyla_network_flow_bytes_total`
4. **Interface Bandwidth**: Node network card RX/TX byte rate via `node_network_receive_bytes_total`

### Layer 7 (Application RED)
1. **Request Rate (Rate)**: Requests per second per service via `http_server_request_duration_seconds_count`
2. **Request Latency (Duration)**: Response time percentiles (p50, p95, p99) via `http_server_request_duration_seconds_bucket`
3. **Error Rate (Errors)**: 4xx client and 5xx server failure rates via `http_server_request_duration_seconds_count`
4. **Payload Volumes**: HTTP request and response body transfer volume via `http_server_request_body_size_bytes_sum`
