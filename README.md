# OpsLab - DevOps Full-Stack Lab

> From bare metal to cloud-native: a complete high-availability web cluster built from scratch on 11 VMware VMs.

## Architecture

```
用户 → VIP 10.0.0.100 → HAProxy (lb01/lb02) → web01/web02 → db01(主) / db02(从)
                           |                        |           |
                     Keepalived VRRP          NFS 共享      MySQL binlog 复制
                     (unicast, VMware NAT)   (m1 服务端)
                           |
                    monitor: Prometheus + Grafana + Node/MySQL/HAProxy Exporters

K8s 集群 (k8s-master + node1 + node2):
  Redis 主从 + Jenkins + ES/Kibana + Harbor（NodePort 30080/30081/30082）
```

## VM Topology

| Node | IP | CPU | RAM | Role |
|------|------|-----|------|------|
| m1 | 10.0.0.10 | 1 | 1G | Management (Ansible, NFS server) |
| lb01 | 10.0.0.11 | 1 | 1G | Load Balancer (HAProxy + Keepalived MASTER) |
| lb02 | 10.0.0.12 | 1 | 1G | Load Balancer (HAProxy + Keepalived BACKUP) |
| web01 | 10.0.0.13 | 1 | 2G | Web Server (Nginx + PHP-FPM) |
| web02 | 10.0.0.14 | 1 | 2G | Web Server (Nginx + PHP-FPM) |
| db01 | 10.0.0.15 | 1 | 2G | MySQL Master |
| db02 | 10.0.0.16 | 1 | 2G | MySQL Slave |
| monitor | 10.0.0.17 | 2 | 4G | Prometheus + Grafana |
| k8s-master | 10.0.0.18 | 2 | 4G | K8s Control Plane |
| k8s-node1 | 10.0.0.19 | 2 | 4G | K8s Worker (Redis主+Jenkins+Harbor Core) |
| k8s-node2 | 10.0.0.20 | 2 | 4G | K8s Worker (Redis从+ES+Kibana+Harbor DB) |

## Tech Stack

- **OS**: Rocky Linux 9.8
- **LB**: HAProxy + Keepalived (VRRP unicast)
- **Web**: Nginx + PHP-FPM 8.0
- **Storage**: NFS v4 (shared web root) + local-path (K8s PVC)
- **DB**: MySQL 8.0 (master-slave replication)
- **Cache**: Redis 7 (K8s StatefulSet 主从)
- **Monitoring**: Prometheus + Grafana + Node/MySQL/HAProxy Exporters
- **Automation**: Ansible (all deployment via playbooks)
- **Container**: containerd 2.3 (K8s runtime) + Docker (CI build)
- **Orchestration**: Kubernetes 1.31 (kubeadm + Flannel CNI)
- **Middleware**: Harbor(镜像仓库) + Jenkins(CI) + Elasticsearch/Kibana(日志)
- **CI/CD**: Jenkins Pipeline (k8s agent)

## Repository Structure

```
auto-ops/
├── README.md                  # This file
├── GITHUB_RETRIEVAL_CONNECTIONS.md  # 文件检索直达连接
├── docs/                      # Documentation (resume-as-doc)
│   ├── architecture.md        # Architecture evolution: 传统 → 容器 → K8s
│   ├── 01-foundation/         # Stage 1: VM provisioning + Ansible init
│   ├── 02-data-layer/         # Stage 2: MySQL master-slave
│   ├── 03-web-layer/          # Stage 3: Nginx + PHP-FPM + NFS
│   ├── 04-monitoring/         # Stage 4: Prometheus + Grafana + Exporters
│   ├── 05-containerization/   # Stage 5: Docker + Harbor
│   ├── 06-kubernetes/         # Stage 6: K8s cluster + 中间件（已部署）
│   ├── 07-cicd/               # Stage 7: GitLab + Jenkins
│   └── troubleshooting/       # 真实故障记录（面试亮点）
├── ansible/                   # Ansible inventory + playbooks
├── scripts/                   # Shell scripts (init/join/fix/backup/deploy/check)
├── configs/                   # Service config files
├── docker/                    # Dockerfile + docker-compose
├── k8s/                       # K8s YAML + Helm values（含中间件）
└── cicd/                      # Jenkinsfile
```

## Quick Start

```bash
# 1. 克隆
git clone git@github.com:liuc04467-gif/auto-ops.git
cd auto-ops

# 2. 查看主机清单
cat ansible/hosts.ini

# 3. 传统架构部署（m1 上执行）
ansible-playbook ansible/init_servers.yml
ansible-playbook ansible/lb_setup.yml
ansible-playbook ansible/web_setup.yml
ansible-playbook ansible/db_setup.yml
ansible-playbook ansible/monitor_setup.yml

# 4. K8s 集群部署
ansible-playbook -i ansible/hosts.ini ansible/k8s_setup.yml
ssh root@10.0.0.18 'bash /root/init_master.sh'
ssh root@10.0.0.19 'bash /root/join_worker.sh'
ssh root@10.0.0.20 'bash /root/join_worker.sh'
# 中间件部署见 k8s/README.md 的一键 apply 顺序
```

## Service Access

| 服务 | 地址 | 账号 |
|---|---|---|
| Web 应用 | http://10.0.0.100/index.php | - |
| MySQL 读写测试 | http://10.0.0.100/db_test.php | - |
| HAProxy Stats | http://10.0.0.100:8404/stats | admin / admin123 |
| Prometheus | http://10.0.0.17:9090 | - |
| Grafana | http://10.0.0.17:3000 | admin / admin |
| Harbor（K8s） | http://10.0.0.18:30080 | admin / Harbor12345 |
| Jenkins（K8s） | http://10.0.0.18:30081 | admin / (见 k8s/README) |
| Kibana（K8s） | http://10.0.0.18:30082 | 无 |

## Verification

```bash
# HAProxy 轮询
curl http://10.0.0.100/index.php

# MySQL 主从
curl http://10.0.0.100/db_test.php

# Prometheus targets
curl http://10.0.0.17:9090/api/v1/targets

# K8s 节点状态
kubectl get nodes
kubectl get pods -A
```

## Skills Matrix

| Category | Technologies |
|----------|-------------|
| Linux | Rocky 9, systemd, firewalld, SELinux |
| Network | NAT, VRRP, VIP, unicast, TCP/IP |
| Automation | Ansible (playbook, roles, inventory) |
| Load Balancing | HAProxy, Keepalived, health checks |
| Web | Nginx, PHP-FPM, NFS |
| Database | MySQL 8.0, binlog replication, read/write split |
| Cache | Redis 主从 (StatefulSet) |
| Monitoring | Prometheus, Grafana, Node/MySQL/HAProxy Exporters |
| Container | containerd, Docker, Harbor registry |
| Orchestration | Kubernetes (kubeadm, Flannel CNI, local-path) |
| Middleware | Jenkins, Elasticsearch, Kibana |
| CI/CD | Jenkins Pipeline |

## License

MIT

## Author

**liuchongyang** — [GitHub](https://github.com/liuc04467-gif)
