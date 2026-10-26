# CMCKO Deployment & Operations Guide

This guide covers deployment, daily operation workflows, and architecture for the **Centralized Multi-Cluster Kubernetes Observability (CMCKO)** platform across a distributed 3-system environment.

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

## ⚡ System 1: macOS (OrbStack) — Single Cluster

### Prerequisites:
- **OrbStack** running with Docker engine enabled.
- In OrbStack Settings: **Kubernetes turned OFF** (avoids duplicate cluster overhead and port conflicts with Kind).
- Installed CLI tools: `brew install kind kubectl helm`.

### Deployment:
```bash
# Deploys single cluster-01, target app, and Beyla eBPF (with NodePort 30080 & 30090)
./scripts/deploy.sh
```

### Daily Routine (Pause & Resume):
#### 🛑 To Stop (Freeze & Free RAM):
```bash
docker stop cluster-01-control-plane
orbctl stop
```

#### ▶️ To Start (Resume where you left off):
```bash
open -a OrbStack
docker start cluster-01-control-plane
kubectl get nodes
```

---

## ⚡ System 2: Windows (WSL2 k3s) — Edge Cluster

### Prerequisites:
- Windows 10/11 with WSL2 Ubuntu (kernel >= 5.15 for eBPF).
- k3s installed (`curl -sfL https://get.k3s.io | sh -`).

### Deployment:
```bash
chmod +x scripts/setup-system2-wsl.sh
./scripts/setup-system2-wsl.sh
```

---

## ⚡ Prometheus & Grafana Monitoring (System 1 Local Stack)

### Deployment:
1. Deploy Prometheus (:30001) and Grafana (:30000) directly on cluster-01:
   ```bash
   ./extras/local-learning-monitoring/install.sh
   ```
   *(Or optionally pass `<SYSTEM_2_IP>` to also scrape System 2 over Tailscale)*:
   ```bash
   ./extras/local-learning-monitoring/install.sh 100.x.y.z
   ```
2. Access Local Observability:
   - **Grafana Dashboard**: `http://localhost:30000` (Login: `admin` / `admin`)
   - **Prometheus UI**: `http://localhost:30001`
   - Pre-loaded with: **`CMCKO — Unified Multi-Cluster eBPF Observability (L4 + L7 + HPA)`**

### External Scrapers (System 3):
Any external Prometheus scraper (such as System 3) can pull your Beyla eBPF metrics directly from:
`http://<YOUR_TAILSCALE_IP>:30090/metrics`

---

## 🚀 External Traffic Generation (Apache JMeter)

Internal mock generators (`traffic-gen`) are disabled (`replicas: 0`). Real HTTP and TCP traffic is generated externally.

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

## 📊 Monitored Metrics (4 L4 + 4 L7)

### Layer 4 (Network / Transport)
1. **Throughput**: Bytes transferred (sent / received) via `befa_network_flow_bytes_total`
2. **Connection Count**: Active microservice communication links
3. **Packet Count / Retransmissions**: Packets/s and packet loss indicators via `befa_network_flow_stats_tcp_retransmits_total`
4. **RTT**: Round-Trip Time / network-level latency via `befa_network_flow_stats_tcp_rtt_seconds`

### Layer 7 (Application)
1. **Request Rate**: Requests per second (req/s) per service/endpoint via `http_server_request_duration_seconds_count`
2. **Latency**: Request duration percentiles (p50 / p99) via `http_server_request_duration_seconds`
3. **Error Rate**: 4xx client and 5xx server HTTP response codes
4. **Request / Response Size**: Payload throughput (bytes/s) via `http_server_request_body_size_bytes`
