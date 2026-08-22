# Architecture Evolution

## Phase 1: Traditional Architecture (Current)

```
                    VIP 10.0.0.100
                         |
          +--------------+--------------+
          |  Keepalived VRRP (unicast) |
          |  lb01 (MASTER, pri=100)    |
          |  lb02 (BACKUP, pri=90)     |
          +--------------+--------------+
                         |  HAProxy :80
          +--------------+--------------+
          |  roundrobin polling         |
          |  web01:80    web02:80      |
          +-------------+--------------+
               |              |
            Nginx+PHP      Nginx+PHP
               |              |
          +----+----+   +----+----+
          |  NFS   |   |  NFS   |  (shared /data/web from m1)
          +--------+   +--------+
               |              |
          +----+----+   +----+----+
          | db01    |   | db02    |
          | (master)|   | (slave) |
          +---------+   +---------+
               |
          monitor (10.0.0.17)
          Prometheus :9090 + Grafana :3000
          Node Exporter :9100 (all 8 nodes)
          MySQL Exporter :9104 (db01/db02)
          HAProxy Exporter :9101 (lb01/lb02)
```

**Design decisions:**
- VRRP unicast instead of multicast (VMware NAT doesn't support multicast)
- NFS shared storage for web root (simpler than rsync, consistent content)
- MySQL read/write split at application level (PHP connects master for writes, slave for reads)

## Phase 2: Containerized Architecture (Planned)

```
User → HAProxy (existing) → Docker containers (web01/web02)
                                |
                        Harbor private registry (on monitor)
                                |
                    Docker Compose for multi-container orchestration
```

**Goals:**
- Containerize PHP application (Dockerfile with multi-stage build)
- Set up Harbor as private image registry with high availability
- Optimize image layers (reduce from 800MB to <200MB)
- Docker Compose for local development parity

## Phase 3: Kubernetes Cloud-Native (Planned)

```
User → Ingress Controller → K8s Services → Pods
                                           |
                    +------+------+------+
                    |      |      |      |
                  web    db    redis   monitoring
               (HPA)  (StatefulSet)  (StatefulSet)  (Prometheus Operator)
```

**Goals:**
- kubeadm bootstrap (3 nodes: 1 master + 2 workers)
- Calico CNI for pod networking
- Deploy app as Deployment + HPA (auto-scaling)
- MySQL as StatefulSet with persistent volumes
- Ingress for external access
- ConfigMap + Secrets for configuration
- RBAC for security
- Helm Chart packaging
