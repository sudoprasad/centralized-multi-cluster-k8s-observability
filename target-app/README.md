# Target Workload Application (Microservices)

This directory contains the microservices being passively observed by **Grafana Beyla eBPF**.

---

## 🔍 Why We Need This Application

eBPF is not an abstract telemetry simulator—it inspects **live Linux kernel sockets and userspace memory**. 
To extract our **4 L4 Network metrics** and **4 L7 Application metrics**, real microservice processes must be running in the cluster:
* **Frontend (`:8080`)**: Entrypoint for external traffic. Intercepted by eBPF uprobes on `net/http` handlers.
* **Backend (`:5678`)**: Internal microservice called by frontend.
* **Auth (`:7070`)**: Authentication service called during request handling.

> 💡 **Zero Instrumentation**: These containers run standard, unmodified Go binaries (`hashicorp/http-echo`). No OpenTelemetry SDKs, libraries, or code modifications exist.

---

## 🚦 Traffic Ingestion: External JMeter Load (No Mock Traffic)

* **No internal traffic generator pod**: Previous mock traffic generator scripts (`traffic-gen`) have been completely deleted.
* **External Ingress**: The `frontend` service is exposed as a Kubernetes **NodePort on port `30080`**.
* **Traffic Driver**: Real HTTP traffic is sent externally from outside the cluster using **Apache JMeter** (`jmeter/cmcko-traffic-test.jmx`).
