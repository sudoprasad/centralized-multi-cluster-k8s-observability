# Troubleshooting

## Beyla not showing metrics in Prometheus

**Check 1** — Is Beyla running?
```bash
kubectl get pods -n beyla
kubectl logs -n beyla -l app.kubernetes.io/name=beyla --tail=50
```

**Check 2** — Is the /metrics endpoint responding?
```bash
kubectl port-forward -n beyla svc/beyla 9090:9090 &
curl http://localhost:9090/metrics | head -20
```

**Check 3** — Is Prometheus scraping Beyla?
```
Open: http://localhost:30001/targets
Look for beyla in the targets list. State should be UP.
```

**Check 4** — eBPF not loading (BTF issue)
```bash
kubectl logs -n beyla <beyla-pod> 2>&1 | grep -i "btf\|ebpf\|error"
```
On macOS/Docker Desktop, BTF may not be fully available. See the
"eBPF on macOS" section below.

---

## eBPF on macOS (Docker Desktop)

Docker Desktop runs Linux inside a VM (LinuxKit). eBPF availability
depends on the Docker Desktop kernel configuration.

To check if BTF is available inside the kind node:
```bash
# Get the kind node container name
CONTAINER=$(docker ps --format '{{.Names}}' | grep cluster-01-control-plane)

# Check for BTF
docker exec $CONTAINER ls /sys/kernel/btf/vmlinux
```

If BTF is missing, Beyla will fail to load its eBPF probes.
Workaround: Beyla falls back to uprobe-based tracing when BTF is absent.

---

## Pod stuck in Pending

```bash
kubectl describe pod <pod-name> -n <namespace>
# Check Events section for resource/scheduling issues
```

Common cause on kind: Not enough memory. Check Docker Desktop settings
and increase memory to at least 4GB.

---

## Grafana shows "No data"

1. Open Grafana → Explore → Select Prometheus datasource
2. Try query: `up`  — you should see Prometheus itself
3. Try query: `{job="beyla"}` — if empty, Beyla isn't being scraped yet
4. Wait 2-3 minutes after Beyla starts for first metrics to appear

---

## Reset everything

```bash
bash scripts/teardown.sh
bash scripts/deploy.sh
```

---

## Useful kubectl commands

```bash
# All pods across all namespaces
kubectl get pods -A

# Beyla logs
kubectl logs -n beyla -l app.kubernetes.io/name=beyla -f

# Target microservice logs
kubectl logs -n demo -l app=frontend -f

# Port-forward Prometheus locally (alternative to NodePort)
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Port-forward Grafana locally (alternative to NodePort)
kubectl port-forward -n monitoring svc/grafana 3000:80
```
