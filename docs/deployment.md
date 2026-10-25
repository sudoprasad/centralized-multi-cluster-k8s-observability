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

## ⚡ System 3: Windows (WSL2) — Metrics Display & Dashboard Hub

### Deployment:
1. Edit `system3-hub/prometheus.yml` and replace `SYSTEM_1_IP` and `SYSTEM_2_IP` with the LAN IPs of Systems 1 and 2.
2. Launch the monitoring hub via Docker Compose:
   ```bash
   cd system3-hub
   docker compose up -d
   ```
3. Open Grafana:
   - **URL**: `http://localhost:3000` (or `http://<SYSTEM3_IP>:3000`)
   - **Login**: `admin` / `admin`
   - Pre-loaded with the **CMCKO Unified L4 Network & L7 Application Observability** dashboard.

---

## 🚀 External Traffic Generation (Apache JMeter)

Internal mock generators (`traffic-gen`) are disabled (`replicas: 0`). Real HTTP and TCP traffic is generated externally.

### Run via Shell Script (macOS / Linux):
```bash
# Target macOS cluster locally:
./jmeter/run-jmeter.sh localhost 30080 15 300

# Target over LAN:
./jmeter/run-jmeter.sh 192.168.31.9 30080 20 300
```

### Run via PowerShell (Windows):
```powershell
.\jmeter\run-jmeter.ps1 -TargetHost "192.168.31.9" -TargetPort 30080 -Threads 20 -Duration 300
```

### Run via Docker (No JMeter installation required):
```bash
docker run --rm -i -v "$PWD/jmeter":/jmeter justb4/jmeter:latest \
  -n -t /jmeter/cmcko-traffic-test.jmx \
  -Jtarget.host="192.168.31.9" -Jtarget.port="30080" -Jthreads=20 -Jduration=300
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
