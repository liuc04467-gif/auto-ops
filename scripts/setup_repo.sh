#!/bin/bash
# ============================================================
# OpsLab - GitHub repo structure generator
# Run on m1: bash setup_repo.sh
# ============================================================

REPO="/test-ops"
cd $REPO || exit 1

# ---- create directory structure ----
mkdir -p docs/01-foundation
mkdir -p docs/02-data-layer
mkdir -p docs/03-web-layer
mkdir -p docs/04-monitoring
mkdir -p docs/05-containerization
mkdir -p docs/06-kubernetes
mkdir -p docs/07-cicd
mkdir -p docs/troubleshooting
mkdir -p ansible
mkdir -p scripts
mkdir -p configs/nginx
mkdir -p configs/keepalived
mkdir -p configs/haproxy
mkdir -p configs/mysql
mkdir -p configs/prometheus
mkdir -p configs/php-fpm
mkdir -p docker
mkdir -p k8s
mkdir -p cicd
mkdir -p screenshots

# ============================================================
# README.md
# ============================================================
cat > README.md << 'READMEEOF'
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
READMEEOF

# ============================================================
# .gitignore
# ============================================================
cat > .gitignore << 'GITEOF'
# Secrets
*.key
*.pem
*.crt
.env
*credentials*

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
.idea/
.vscode/

# Ansible
*.retry
ansible/*.retry

# Screenshots (selective upload)
screenshots/*.raw
screenshots/*.tmp

# Large files
*.rpm
*.tar.gz
*.iso
GITEOF

# ============================================================
# docs/architecture.md
# ============================================================
cat > docs/architecture.md << 'ARCHEOF'
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
ARCHEOF

# ============================================================
# docs/01-foundation/
# ============================================================
cat > docs/01-foundation/README.md << 'F1EOF'
# Stage 1: Foundation — VM Provisioning & Ansible Init

## Goal
Provision 11 Rocky Linux 9 VMs via kickstart, configure Ansible control node on m1.

## What was done
1. Created kickstart ISO for each VM with static IP, hostname, root password
2. Deployed 11 VMs in batches (memory-aware, max 8GB per batch)
3. Configured Ansible inventory with 7 active nodes
4. Set up SSH key-based authentication from m1 to all nodes
5. Disabled SELinux, configured firewalld, installed common tools

## Playbook
- `ansible/init_servers.yml` — installs EPEL, common tools, chrony, disables SELinux

## Verification
```bash
ansible all -m ping
# All nodes return SUCCESS
```

## Troubleshooting
- VM boot loop: kickstart `poweroff` + disconnect CD-ROM after install
- Black screen at "Basic System": removed `crashkernel=auto` (1G RAM too small)
- Root SSH denied: Rocky 9 defaults to `PermitRootLogin prohibit-password`, fixed in kickstart `%post`
- `missing packages: vim`: added `--ignoremissing` to `%packages`

## Key files changed
- `/etc/ansible/hosts` — Ansible inventory
- `/root/.ssh/authorized_keys` — SSH trust
- `/etc/selinux/config` — SELINUX=disabled
- `/etc/chrony.conf` — time sync
F1EOF

# ============================================================
# docs/02-data-layer/
# ============================================================
cat > docs/02-data-layer/README.md << 'D2EOF'
# Stage 2: Data Layer — MySQL Master-Slave Replication

## Goal
Set up MySQL 8.0 master-slave replication with read/write split.

## What was done
1. Installed MySQL 8.0 on db01 (master) and db02 (slave)
2. Configured binlog on master (server-id=1, binlog-do-db=opslab)
3. Created replication user `repl` with REPLICATION SLAVE privilege
4. Configured slave to replicate from master
5. Created application database `opslab` and user `webapp`
6. Deployed PHP test page demonstrating read/write split

## Architecture
```
PHP app (web01/web02)
  ├── Write (INSERT/UPDATE/DELETE) → db01 (10.0.0.15) master
  └── Read (SELECT)               → db02 (10.0.0.16) slave
```

## Verification
```bash
# Replication status
mysql -u root -p -e "SHOW REPLICA STATUS\G"  # on db02
# Replica_IO_Running: Yes
# Replica_SQL_Running: Yes
# Seconds_Behind_Source: 0

# Application test
curl http://10.0.0.100/db_test.php
# Master: CONNECTED, Slave: CONNECTED, data replicates
```

## Playbook
- `ansible/db_setup.yml`

## Troubleshooting
- Replication error (data already exists): `SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE`
- Temporary password not found in log: fallback to `mysql -u root` (Rocky 9 default)
- MySQL exporter auth: created `exporter` user with PROCESS + REPLICATION CLIENT

## Planned
- Redis Sentinel for caching layer
- ProxySQL or MHA for automatic failover
- mysqldump + binlog backup strategy
D2EOF

# ============================================================
# docs/03-web-layer/
# ============================================================
cat > docs/03-web-layer/README.md << 'W3EOF'
# Stage 3: Web Layer — Nginx + PHP-FPM + NFS

## Goal
Deploy Nginx + PHP-FPM with NFS shared storage across web01/web02.

## What was done
1. Configured m1 as NFS server (export /data/web to 10.0.0.0/24)
2. Mounted NFS on web01/web02 at /data/web
3. Installed Nginx + PHP-FPM 8.0
4. Configured PHP-FPM to run as nginx user
5. Deployed test pages: index.php (hostname/IP), db_test.php (MySQL), health (OK)
6. HAProxy load balances traffic to web01/web02 via roundrobin

## Architecture
```
m1 (NFS server) /data/web ←──── web01, web02 (NFS clients)
                                    |
                              Nginx :80 → PHP-FPM (unix socket)
                                    |
                              /data/web/html/ (shared)
```

## Verification
```bash
# Round-robin test
curl http://10.0.0.100/index.php  # → web01.opslab.local
curl http://10.0.0.100/index.php  # → web02.opslab.local

# NFS sync test
# Write file on web01, read on web02 → same content

# Health check
curl http://10.0.0.100/health  # → OK
```

## Playbook
- `ansible/web_setup.yml`

## Troubleshooting
- PHP-FPM socket permission: changed user/group to nginx in www.conf
- NFS mount fails: firewalld needs nfs, rpc-bind, mountd services
- PHP session dir: /var/lib/php/session must be owned by nginx
W3EOF

# ============================================================
# docs/04-monitoring/
# ============================================================
cat > docs/04-monitoring/README.md << 'M4EOF'
# Stage 4: Monitoring — Prometheus + Grafana + Exporters

## Goal
Full-stack monitoring: Node, MySQL, HAProxy exporters → Prometheus → Grafana.

## What was done
1. Deployed Node Exporter on all 8 active nodes (:9100)
2. Deployed MySQL Exporter on db01/db02 (:9104)
3. Deployed HAProxy Exporter on lb01/lb02 (:9101)
4. Installed Prometheus on monitor (:9090, 15s scrape interval)
5. Installed Grafana on monitor (:3000)

## Scrape targets
| Job | Targets | Port |
|-----|---------|------|
| node | 10.0.0.10-17 | 9100 |
| mysql | 10.0.0.15, 10.0.0.16 | 9104 |
| haproxy | 10.0.0.11, 10.0.0.12 | 9101 |

## Verification
```bash
# Prometheus targets
curl http://10.0.0.17:9090/api/v1/targets | jq '.data.activeTargets[].health'
# All "up"

# Grafana
# http://10.0.0.17:3000 (admin/admin)
# Data source: http://10.0.0.17:9090
# Dashboard: Node Exporter Full (ID: 1860)
```

## Playbook
- `ansible/monitor_setup.yml`

## Grafana setup steps
1. Login admin/admin, change password
2. Add data source → Prometheus → URL: http://10.0.0.17:9090
3. Import dashboard ID 1860 (Node Exporter Full)
4. Create custom dashboard for MySQL + HAProxy

## Planned
- Alertmanager with webhook to Feishu
- Custom Grafana dashboards
- Long-term storage with Thanos
M4EOF

# ============================================================
# docs/05-containerization/
# ============================================================
cat > docs/05-containerization/README.md << 'C5EOF'
# Stage 5: Containerization (Planned)

## Goal
Containerize the web application, set up Harbor private registry.

## Planned steps
1. Write multi-stage Dockerfile for PHP app
2. Optimize image layers (target: <200MB from 800MB)
3. Deploy Harbor on monitor (or dedicated VM)
4. Docker Compose for multi-container local dev
5. Push images to Harbor, pull on web nodes

## Interview points
- Multi-stage build: builder stage compiles, runtime stage is slim
- Layer caching: COPY requirements first, install deps, then COPY app code
- Image scanning: Trivy for CVE detection
- Harbor: replication, vulnerability scanning, RBAC

## Key files
- `docker/Dockerfile` — multi-stage PHP build
- `docker/docker-compose.yml` — local development stack
C5EOF

# ============================================================
# docs/06-kubernetes/
# ============================================================
cat > docs/06-kubernetes/README.md << 'K6EOF'
# Stage 6: Kubernetes Cluster (Planned)

## Goal
Bootstrap K8s cluster with kubeadm, deploy application with auto-scaling.

## Planned steps
1. kubeadm init on k8s-master (10.0.0.18)
2. Join k8s-node1/2 (10.0.0.19-20) as workers
3. Install Calico CNI (VXLANCrossSubnet)
4. Deploy app as Deployment + HPA
5. MySQL as StatefulSet with PVC
6. Ingress Controller for external access
7. ConfigMap + Secrets for configuration
8. Helm Chart packaging

## Ansible playbook
- `ansible/k8s_setup.yml` — full cluster bootstrap (5 steps)
  - STEP 1: System prep (modules, sysctl, swap off)
  - STEP 2: containerd installation
  - STEP 3: kubeadm/kubelet/kubectl install
  - STEP 4: Master init + Calico
  - STEP 5: Worker join

## Interview points
- kubeadm vs k3s vs RKE: why kubeadm (closest to production)
- Calico vs Flannel: Calico for network policy + BGP support
- StatefulSet for MySQL: stable identity, persistent storage
- HPA: CPU/memory-based auto-scaling
- RBAC: least privilege for service accounts

## Key files
- `k8s/deployment.yaml` — app deployment
- `k8s/service.yaml` — ClusterIP/NodePort
- `k8s/ingress.yaml` — ingress rules
- `k8s/hpa.yaml` — horizontal pod autoscaler
K6EOF

# ============================================================
# docs/07-cicd/
# ============================================================
cat > docs/07-cicd/README.md << 'CI7EOF'
# Stage 7: CI/CD Pipeline (Planned)

## Goal
GitLab + Jenkins Pipeline: code commit → build → test → deploy to K8s.

## Planned pipeline
```
Developer push → GitLab webhook → Jenkins pipeline:
  1. Checkout code
  2. Build Docker image (multi-stage)
  3. Run unit tests
  4. Push to Harbor registry
  5. kubectl apply to K8s (rolling update)
  6. Smoke test (curl 200 + keyword)
  7. Feishu notification (success/failure)
```

## Jenkinsfile evolution
- v1: Freestyle project (manual)
- v2: Scripted Pipeline
- v3: Declarative Pipeline with stages
- v4: Multibranch Pipeline (auto-trigger on PR)

## Interview points
- Pipeline as code: Jenkinsfile in repo
- Blue-green deployment: zero downtime
- Rollback: `kubectl rollout undo`
- Webhook: push-triggered, not polling

## Key files
- `cicd/Jenkinsfile` — declarative pipeline
CI7EOF

# ============================================================
# docs/troubleshooting/
# ============================================================
cat > docs/troubleshooting/01-vm-boot-loop.md << 'T1EOF'
# VM Boot Loop After Installation

## Symptom
After kickstart installation completes, VM reboots and enters installation again.

## Root cause
- CD-ROM still connected
- BIOS boot order set to `cdrom`
- VM boots from ISO instead of disk

## Fix
1. After kickstart `poweroff`, disconnect CD-ROM in .vmx:
   ```
   sata0:0.present = "FALSE"
   sata0:1.present = "FALSE"
   ```
2. Boot again → boots from disk

## Prevention
Always disconnect CD-ROM after installation in automation scripts.
T1EOF

cat > docs/troubleshooting/02-black-screen-basic-system.md << 'T2EOF'
# Black Screen at "Reached target Basic System"

## Symptom
VM boots, shows `Reached target Basic System.`, then black screen with blinking cursor.

## Root cause
- `crashkernel=auto` in bootloader config
- On 1G RAM VMs, kernel crash dump reservation fails
- `quiet` parameter hides the error messages

## Fix
- Remove `crashkernel` from kickstart `bootloader` line
- Remove `quiet` to see boot logs
```kickstart
bootloader --location=mbr
```

## Verification
- Boot logs scroll visible
- System reaches `login:` prompt
T2EOF

cat > docs/troubleshooting/03-vrrp-unicast-nat.md << 'T3EOF'
# VRRP Multicast Fails on VMware NAT

## Symptom
Keepalived MASTER/BACKUP both claim MASTER, VIP not stable.

## Root cause
- VMware NAT network doesn't forward multicast packets
- Default VRRP uses multicast (224.0.0.18)

## Fix
Configure Keepalived to use unicast:
```
vrrp_instance VI_1 {
    unicast_src_ip 10.0.0.11
    unicast_peer {
        10.0.0.12
    }
}
```

## Verification
```bash
# On lb01
ip addr show ens33 | grep 10.0.0.100
# VIP present on MASTER only

# Failover test: stop haproxy on lb01
systemctl stop haproxy  # on lb01
# VIP moves to lb02 within 2 seconds
```
T3EOF

cat > docs/troubleshooting/04-mysql-replication-error.md << 'T4EOF'
# MySQL Replication Sync Error

## Symptom
`SHOW REPLICA STATUS\G` shows `Last_Error` with duplicate key or data exists.

## Root cause
Test data inserted on slave directly, causing conflict with master binlog replay.

## Fix
```sql
-- On slave (db02)
STOP REPLICA;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
START REPLICA;

-- Verify
SHOW REPLICA STATUS\G;
-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
```

## Prevention
- Never write to slave directly
- Use `read_only=1` in my.cnf on slave
- Application-level read/write split
T4EOF

cat > docs/troubleshooting/05-root-ssh-denied.md << 'T5EOF'
# Root SSH Login Denied

## Symptom
SSH connection to VM succeeds, but root password is rejected.

## Root cause
Rocky Linux 9 defaults to `PermitRootLogin prohibit-password` in sshd_config,
which means root can only login with SSH keys, not passwords.

## Fix
In kickstart `%post`:
```bash
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
```

## Alternative (more secure)
- Create `opsuser` in wheel group
- `echo "opsuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ops`
- Use `opsuser` for SSH, `sudo -i` for root
T5EOF

# ============================================================
# ansible/ (copy existing playbooks)
# ============================================================
cp /root/init_servers.yml ansible/init_servers.yml 2>/dev/null || true
cp /root/lb_setup.yml ansible/lb_setup.yml 2>/dev/null || true
cp /root/web_setup.yml ansible/web_setup.yml 2>/dev/null || true
cp /root/db_setup.yml ansible/db_setup.yml 2>/dev/null || true
cp /root/monitor_setup.yml ansible/monitor_setup.yml 2>/dev/null || true
cp /root/k8s_setup.yml ansible/k8s_setup.yml 2>/dev/null || true

# inventory
cat > ansible/inventory.ini << 'INVEOF'
[all]
m1       ansible_connection=local ansible_user=root
lb01     ansible_host=10.0.0.11 ansible_user=root
lb02     ansible_host=10.0.0.12 ansible_user=root
web01    ansible_host=10.0.0.13 ansible_user=root
web02    ansible_host=10.0.0.14 ansible_user=root
db01     ansible_host=10.0.0.15 ansible_user=root
db02     ansible_host=10.0.0.16 ansible_user=root
monitor  ansible_host=10.0.0.17 ansible_user=root

[lb]
lb01
lb02

[web]
web01
web02

[db]
db01
db02

[monitoring]
monitor

[servers:children]
lb
web
db
monitoring
INVEOF

# ============================================================
# configs/
# ============================================================
cat > configs/haproxy/haproxy.cfg << 'HAPROXYEOF'
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s

frontend http-in
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /
    server web01 10.0.0.13:80 check inter 2000 rise 2 fall 3
    server web02 10.0.0.14:80 check inter 2000 rise 2 fall 3

listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats auth admin:admin123
HAPROXYEOF

cat > configs/keepalived/keepalived-lb01.conf << 'KLB1EOF'
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight -20
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100
    advert_int 1
    unicast_src_ip 10.0.0.11
    unicast_peer {
        10.0.0.12
    }

    authentication {
        auth_type PASS
        auth_pass opslab123
    }

    virtual_ipaddress {
        10.0.0.100/24 dev ens33
    }

    track_script {
        chk_haproxy
    }
}
KLB1EOF

cat > configs/keepalived/keepalived-lb02.conf << 'KLB2EOF'
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight -20
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 90
    advert_int 1
    unicast_src_ip 10.0.0.12
    unicast_peer {
        10.0.0.11
    }

    authentication {
        auth_type PASS
        auth_pass opslab123
    }

    virtual_ipaddress {
        10.0.0.100/24 dev ens33
    }

    track_script {
        chk_haproxy
    }
}
KLB2EOF

cat > configs/nginx/default.conf << 'NGINXEOF'
server {
    listen       80;
    server_name  _;
    root         /data/web/html;

    index index.php index.html index.htm;

    access_log  /var/log/nginx/access.log  main;
    error_log   /var/log/nginx/error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass   unix:/run/php-fpm/www.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINXEOF

cat > configs/mysql/my-master.cnf << 'MYMEOF'
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-do-db = opslab
bind-address = 0.0.0.0
MYMEOF

cat > configs/mysql/my-slave.cnf << 'MYSEOF'
[mysqld]
server-id = 2
bind-address = 0.0.0.0
read_only = 1
MYSEOF

cat > configs/php-fpm/www.conf << 'PHPEOF'
; PHP-FPM pool configuration (extracted key settings)
user = nginx
group = nginx
listen.owner = nginx
listen.group = nginx
listen = /run/php-fpm/www.sock
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
PHPEOF

cat > configs/prometheus/prometheus.yml << 'PROMEOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  - job_name: "node"
    static_configs:
      - targets:
          - "10.0.0.10:9100"
          - "10.0.0.11:9100"
          - "10.0.0.12:9100"
          - "10.0.0.13:9100"
          - "10.0.0.14:9100"
          - "10.0.0.15:9100"
          - "10.0.0.16:9100"
          - "10.0.0.17:9100"

  - job_name: "haproxy"
    static_configs:
      - targets:
          - "10.0.0.11:9101"
          - "10.0.0.12:9101"

  - job_name: "mysql"
    static_configs:
      - targets:
          - "10.0.0.15:9104"
          - "10.0.0.16:9104"
PROMEOF

# ============================================================
# scripts/
# ============================================================
cat > scripts/backup.sh << 'BKPEOF'
#!/bin/bash
# OpsLab - MySQL backup script
# Usage: ./backup.sh [database_name]
# Crontab: 0 2 * * * /root/scripts/backup.sh opslab

DB_NAME="${1:-opslab}"
DB_USER="root"
DB_PASS="<REDACTED>"
BACKUP_DIR="/data/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

mysqldump -u"$DB_USER" -p"$DB_PASS" \
  --single-transaction \
  --routines \
  --triggers \
  "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

# Compress
gzip "$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

# Cleanup old backups
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$KEEP_DAYS -delete

echo "[$(date)] Backup complete: ${DB_NAME}_${DATE}.sql.gz"
BKPEOF

cat > scripts/deploy.sh << 'DEPEOF'
#!/bin/bash
# OpsLab - Ansible playbook runner
# Usage: ./deploy.sh [stage]
# Stages: init, lb, web, db, monitor, k8s, all

STAGE="${1:-all}"
PLAYBOOK_DIR="/test-ops/ansible"

case $STAGE in
  init)    ansible-playbook "$PLAYBOOK_DIR/init_servers.yml" ;;
  lb)      ansible-playbook "$PLAYBOOK_DIR/lb_setup.yml" ;;
  web)     ansible-playbook "$PLAYBOOK_DIR/web_setup.yml" ;;
  db)      ansible-playbook "$PLAYBOOK_DIR/db_setup.yml" ;;
  monitor) ansible-playbook "$PLAYBOOK_DIR/monitor_setup.yml" ;;
  k8s)     ansible-playbook "$PLAYBOOK_DIR/k8s_setup.yml" ;;
  all)
    ansible-playbook "$PLAYBOOK_DIR/init_servers.yml"
    ansible-playbook "$PLAYBOOK_DIR/lb_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/web_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/db_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/monitor_setup.yml"
    ;;
  *)
    echo "Usage: $0 {init|lb|web|db|monitor|k8s|all}"
    exit 1
    ;;
esac
DEPEOF

cat > scripts/check.sh << 'CHKEOF'
#!/bin/bash
# OpsLab - Health check script
# Checks all services across the cluster

echo "=== OpsLab Health Check ==="
echo ""

# 1. HAProxy VIP
echo -n "VIP 10.0.0.100: "
if curl -s -o /dev/null -w "%{http_code}" http://10.0.0.100/health | grep -q 200; then
  echo "OK"
else
  echo "FAIL"
fi

# 2. Web servers
for ip in 10.0.0.13 10.0.0.14; do
  echo -n "Web $ip: "
  if curl -s -o /dev/null -w "%{http_code}" http://$ip/health | grep -q 200; then
    echo "OK"
  else
    echo "FAIL"
  fi
done

# 3. MySQL replication
echo -n "MySQL replication: "
REPL=$(mysql -u root -p'<REDACTED>' -h 10.0.0.16 -e "SHOW REPLICA STATUS\G" 2>/dev/null | grep -E "Running|Behind")
if echo "$REPL" | grep -q "Yes"; then
  echo "OK"
else
  echo "FAIL"
fi

# 4. Prometheus targets
echo -n "Prometheus: "
if curl -s http://10.0.0.17:9090/-/healthy | grep -q "OK"; then
  echo "OK"
else
  echo "FAIL"
fi

# 5. Grafana
echo -n "Grafana: "
if curl -s -o /dev/null -w "%{http_code}" http://10.0.0.17:3000/api/health | grep -q 200; then
  echo "OK"
else
  echo "FAIL"
fi

# 6. Node exporters
echo "Node Exporters:"
for ip in 10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.13 10.0.0.14 10.0.0.15 10.0.0.16 10.0.0.17; do
  echo -n "  $ip:9100: "
  if curl -s -o /dev/null -w "%{http_code}" http://$ip:9100/metrics | grep -q 200; then
    echo "OK"
  else
    echo "FAIL"
  fi
done

echo ""
echo "=== Check complete ==="
CHKEOF

# ============================================================
# docker/
# ============================================================
cat > docker/Dockerfile << 'DOCKEOF'
# OpsLab - PHP application Dockerfile
# Multi-stage build: builder → runtime
#
# Stage 1: Builder (compile PHP extensions)
FROM php:8.0-fpm-alpine AS builder

RUN docker-php-ext-install pdo_mysql mysqli && \
    docker-php-ext-enable opcache

# Stage 2: Runtime (slim image)
FROM php:8.0-fpm-alpine AS runtime

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy application code
COPY . /var/www/html

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/health || exit 1

# Image size optimization:
# - Alpine base: ~40MB (vs Debian ~150MB)
# - Multi-stage: no build tools in runtime
# - .dockerignore: exclude tests, docs, .git
DOCKEOF

cat > docker/docker-compose.yml << 'DCEOF'
# OpsLab - Local development with Docker Compose
# Usage: docker-compose up -d

version: "3.8"

services:
  web:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: <REDACTED>
      MYSQL_DATABASE: opslab
      MYSQL_USER: webapp
      MYSQL_PASSWORD: <REDACTED>
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3306:3306"

  prometheus:
    image: prom/prometheus:v2.55.1
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: <REDACTED>
    depends_on:
      - prometheus

volumes:
  db_data:
DCEOF

# ============================================================
# k8s/
# ============================================================
cat > k8s/namespace.yaml << 'K8NSEOF'
apiVersion: v1
kind: Namespace
metadata:
  name: opslab
  labels:
    name: opslab
K8NSEOF

cat > k8s/deployment.yaml << 'K8DEPEOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: opslab
  labels:
    app: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: php-app
        image: harbor.opslab.local/opslab/web-app:v1.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
K8DEPEOF

cat > k8s/service.yaml << 'K8SVEOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: opslab
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
K8SVEOF

cat > k8s/ingress.yaml << 'K8INEOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opslab-ingress
  namespace: opslab
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.opslab.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
K8INEOF

cat > k8s/hpa.yaml << 'K8HPAEOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
  namespace: opslab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
K8HPAEOF

cat > k8s/README.md << 'K8REOF'
# K8s Manifests

## Files
- `namespace.yaml` — opslab namespace
- `deployment.yaml` — PHP web app (2 replicas, liveness/readiness probes)
- `service.yaml` — ClusterIP service
- `ingress.yaml` — Nginx Ingress for external access
- `hpa.yaml` — Auto-scaling (2-10 pods, CPU>70% or memory>80%)

## Planned
- `mysql-statefulset.yaml` — MySQL with PVC
- `configmap.yaml` — App configuration
- `secret.yaml` — Database credentials (base64 encoded)
- `helm/` — Helm Chart for one-command deploy

## Usage
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Check
kubectl get pods -n opslab
kubectl get hpa -n opslab
```
K8REOF

# ============================================================
# cicd/
# ============================================================
cat > cicd/Jenkinsfile << 'JENEOF'
// OpsLab CI/CD Pipeline
// Stages: Build → Test → Push → Deploy → Verify

pipeline {
    agent any

    environment {
        HARBOR_URL = 'harbor.opslab.local'
        IMAGE_NAME = 'opslab/web-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker build \
                      -f docker/Dockerfile \
                      -t ${HARBOR_URL}/${IMAGE_NAME}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Test') {
            steps {
                sh 'echo "Running unit tests..."'
                // Add actual test commands here
            }
        }

        stage('Push to Harbor') {
            steps {
                sh '''
                    docker login ${HARBOR_URL} -u $HARBOR_USER -p $HARBOR_PASS
                    docker push ${HARBOR_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to K8s') {
            steps {
                sh '''
                    kubectl set image deployment/web-app \
                      web-app=${HARBOR_URL}/${IMAGE_NAME}:${IMAGE_TAG} \
                      -n opslab
                    kubectl rollout status deployment/web-app -n opslab
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    sleep 5
                    kubectl get pods -n opslab
                    curl -s -o /dev/null -w "%{http_code}" http://app.opslab.local/health
                '''
            }
        }
    }

    post {
        success {
            echo "Deploy successful: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Deploy failed"
        }
    }
}
JENEOF

# ============================================================
# screenshots/
# ============================================================
touch screenshots/.gitkeep

# ============================================================
# git add and commit
# ============================================================
git add -A
git status

echo ""
echo "==== Repository structure created ===="
echo "Review with: git status"
echo "Push with:   git commit -m 'restructure: full repo layout' && git push"
