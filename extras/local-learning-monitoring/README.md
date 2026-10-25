# Optional Local Learning Monitoring (System 1)

> ⚠️ **Note**: In the main production architecture (**Option A**), all Prometheus scraping and Grafana dashboards live exclusively on **System 3 (Windows WSL2 Hub)**. System 1 and System 2 run as lightweight edge nodes running only the demo microservices and Beyla eBPF agents.

This directory is provided as an **isolated, optional tool for personal learning & quick local validation** on your Mac.

---

## 🚀 Usage

### To Install Local Grafana & Prometheus:
```bash
./extras/local-learning-monitoring/install.sh
```
- **Grafana Dashboard**: `http://localhost:30000` (Login: `admin` / `admin`)
- **Prometheus UI**: `http://localhost:30001`

### To Uninstall (Revert to Pure Option A Edge Node):
```bash
./extras/local-learning-monitoring/uninstall.sh
```
This frees ~500 MB RAM and ensures System 1 runs strictly as a telemetry producer.
