# OpsLab - DevOps Full-Stack Lab

> From bare metal to cloud-native: a complete high-availability web cluster built from scratch on 11 VMware VMs.

## Architecture

```
User → VIP 10.0.0.100 → HAProxy (lb01/lb02) → web01/web02 → db01(master) / db02(slave)
                           |                        |           |
                     Keepalived VRRP          NFS shared       MySQL binlog replication
                     (unicast, VMware NAT)   (m1 server)
                           |
                    monitor: Prometheus + Grafana + Node/MySQL/HAProxy Exporters
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
| k8s-master | 10.0.0.18 | 2 | 4G | K8s Control Plane (planned) |
| k8s-node1 | 10.0.0.19 | 2 | 4G | K8s Worker (planned) |
| k8s-node2 | 10.0.0.20 | 2 | 4G | K8s Worker (planned) |

## Tech Stack

- **OS**: Rocky Linux 9.8
- **LB**: HAProxy 2.4 + Keepalived (VRRP unicast)
- **Web**: Nginx 1.20 + PHP-FPM 8.0
- **Storage**: NFS v4 (shared web root)
- **DB**: MySQL 8.0 (GTID-based master-slave replication)
- **Monitoring**: Prometheus 2.55 + Grafana + Node/MySQL/HAProxy Exporters
- **Automation**: Ansible (all deployment via playbooks)
- **Container**: Docker + containerd (planned)
- **Orchestration**: Kubernetes 1.31 + Calico CNI (planned)
- **CI/CD**: GitLab + Jenkins Pipeline (planned)

## Repository Structure

```
auto-ops/
├── README.md                  # This file
├── docs/                      # Documentation (resume-as-doc)
│   ├── architecture.md        # Architecture evolution: traditional → container → K8s
│   ├── 01-foundation/         # Stage 1: VM provisioning + Ansible init
│   ├── 02-data-layer/         # Stage 2: MySQL master-slave + Redis (planned)
│   ├── 03-web-layer/          # Stage 3: Nginx + PHP-FPM + NFS
│   ├── 04-monitoring/         # Stage 4: Prometheus + Grafana + Exporters
│   ├── 05-containerization/   # Stage 5: Docker + Harbor (planned)
│   ├── 06-kubernetes/         # Stage 6: K8s cluster (planned)
│   ├── 07-cicd/               # Stage 7: GitLab + Jenkins (planned)
│   └── troubleshooting/      # Real fault records (interview gold)
├── ansible/                   # Ansible inventory + playbooks
├── scripts/                   # Shell scripts (backup, deploy, check)
├── configs/                   # Service config files
├── docker/                    # Dockerfile + docker-compose
├── k8s/                       # K8s YAML manifests + Helm
├── cicd/                      # Jenkinsfile versions
└── screenshots/               # Dashboard, alerts, architecture diagrams
```

## Quick Start

```bash
# 1. Clone
git clone git@github.com:liuc04467-gif/auto-ops.git
cd auto-ops

# 2. Review Ansible inventory
cat ansible/inventory.ini

# 3. Run deployment (from m1)
ansible-playbook ansible/init_servers.yml
ansible-playbook ansible/lb_setup.yml
ansible-playbook ansible/web_setup.yml
ansible-playbook ansible/db_setup.yml
ansible-playbook ansible/monitor_setup.yml
```

## Verification

```bash
# HAProxy round-robin
curl http://10.0.0.100/index.php

# MySQL replication
curl http://10.0.0.100/db_test.php

# Prometheus targets
curl http://10.0.0.17:9090/api/v1/targets

# Grafana dashboard
# http://10.0.0.17:3000  (admin/admin)
```

## Skills Matrix

| Category | Technologies |
|----------|-------------|
| Linux | Rocky 9, systemd, firewalld, SELinux, LVM |
| Network | NAT, VRRP, VIP, unicast, TCP/IP |
| Automation | Ansible (playbook, roles, inventory) |
| Load Balancing | HAProxy, Keepalived, health checks |
| Web | Nginx, PHP-FPM, NFS |
| Database | MySQL 8.0, binlog replication, read/write split |
| Monitoring | Prometheus, Grafana, Node/MySQL/HAProxy Exporters |
| Container | Docker, containerd (planned) |
| Orchestration | Kubernetes, kubeadm, Calico CNI (planned) |
| CI/CD | GitLab, Jenkins Pipeline (planned) |

## License

MIT

## Author

**liuchongyang** — [GitHub](https://github.com/liuc04467-gif)
