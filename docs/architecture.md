# Architecture Evolution

## Phase 1: Traditional Architecture (Deployed)

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
          Node Exporter :9100 (8 nodes)
          MySQL Exporter :9104 (db01/db02)
          HAProxy Exporter :9101 (lb01/lb02)
```

**Design decisions:**
- VRRP unicast instead of multicast (VMware NAT doesn't support multicast)
- NFS shared storage for web root (simpler than rsync, consistent content)
- MySQL read/write split at application level (PHP connects master for writes, slave for reads)

## Phase 2: Containerized Architecture (Harbor Deployed)

Harbor 镜像仓库已部署（运行在 K8s 集群，NodePort 30080）；应用容器化待推进。

```
Application (PHP) → Docker build (multi-stage) → push to Harbor (10.0.0.18:30080)
                                                         |
                                                          → pulled by K8s nodes
```

**完成项：**
- Harbor 私有镜像仓库（Helm 部署到 K8s，最小资源模式）
- containerd 镜像加速（aliyun / daocloud）

**待办：**
- PHP 应用多阶段 Dockerfile 落地（当前 docker/Dockerfile 为占位模板）
- 镜像层优化 + Trivy 漏洞扫描

## Phase 3: Kubernetes Cloud-Native (Deployed 2026-08-22)

```
                            K8s Cluster (Flannel 10.244.0.0/16)
          +-------------------------------------------------------+
          |  k8s-master (10.0.0.18)  2C4G                         |
          |    control-plane (api-server/controller/scheduler/etcd) |
          |    (已 untaint，允许调度用户 Pod)                       |
          +-------------------------------------------------------+
                 |                       |
          +--------------+        +--------------+
          | k8s-node1    |        | k8s-node2    |
          | (10.0.0.19)  |        | (10.0.0.20)  |
          |  2C4G        |        |  2C4G        |
          +--------------+        +--------------+
          | Redis 主 cache │        | Redis 从 cache│
          | Jenkins devops │        | ES+Kibana log │
          | Harbor Core/   │        | Harbor DB/    │
          |   Jobsvc/Redis │        |   Portal/Reg  │
          +--------------+        +--------------+

NodePort 暴露（任意节点 IP 可访问）:
  Harbor  :30080   Jenkins :30081   Kibana :30082
```

**完成项：**
- kubeadm 3 节点集群（1 master + 2 worker），Flannel CNI
- local-path StorageClass（修复 ConfigMap setup/teardown + RBAC）
- 中间件：Redis 主从、Jenkins、ES+Kibana、Harbor
- 全部通过 NodePort 暴露给 VM 网络

**待办：**
- 自研应用 Deployment + HPA 接入
- MySQL StatefulSet（当前 MySQL 仍留在 VM 层）
- Ingress + cert-manager 替代 NodePort
- Prometheus Operator 接入 K8s 监控

## 架构演进总结

| 阶段 | 状态 | 技术要点 |
|---|---|---|
| Phase 1 传统架构 | ✅ 已部署 | HAProxy+Keepalived、Nginx+PHP-FPM、MySQL 主从、Prometheus+Grafana |
| Phase 2 容器化 | 🔶 Harbor 已部署 | 私有镜像仓库，应用容器化待推进 |
| Phase 3 云原生 | ✅ 已部署 | kubeadm + Flannel + local-path，四件套中间件 |
