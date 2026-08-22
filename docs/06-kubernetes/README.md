# Kubernetes 集群部署 (k8s-master + k8s-node1 + k8s-node2)

> 适用：Rocky Linux 9.8 + K8s v1.31.14 + containerd 2.3.3 + Flannel v0.28.9 + local-path StorageClass

## 一、节点

| 节点 | IP | 规格 | 角色 |
|---|---|---|---|
| k8s-master | 10.0.0.18 | 2C4G | control-plane (已 untaint，允许调度用户 Pod) |
| k8s-node1 | 10.0.0.19 | 2C4G | worker (Redis 主 + Jenkins + Harbor Core 组件) |
| k8s-node2 | 10.0.0.20 | 2C4G | worker (Redis 从 + ES + Kibana + Harbor DB/Registry 组件) |

## 二、部署步骤

```bash
# 1. 基础准备（m1 管理机执行）
ansible-playbook -i ansible/inventory.ini ansible/k8s_setup.yml

# 2. master 初始化
ssh root@10.0.0.18 'bash /root/init_master.sh'
# 完成后执行提示的两条命令
export KUBECONFIG=/root/.kube/config
kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.28.9/kube-flannel.yml
kubectl taint nodes k8s-master node-role.kubernetes.io/control-plane:NoSchedule-   # 解除 master 污点

# 3. 两个 worker 加入
ssh root@10.0.0.19 'bash /root/join_worker.sh'
ssh root@10.0.0.20 'bash /root/join_worker.sh'

# 4. StorageClass (local-path，配合各 PVC)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml
# ⚠ 需额外修复 ConfigMap 和 RBAC，见 故障排查.md

# 5. 中间件部署（k8s-master 上执行）
kubectl apply -f k8s/redis_master_slave.yaml   # Redis 主从
kubectl apply -f k8s/jenkins.yaml              # Jenkins
kubectl apply -f k8s/es_kibana.yaml            # ES + Kibana
helm install harbor harbor/harbor -n harbor --create-namespace -f k8s/harbor-values.yaml
```

## 三、组件清单 & NodePort 访问

| 命名空间 | 组件 | 访问地址 | 账号/密码 | 部署节点 |
|---|---|---|---|---|
| harbor | Harbor 镜像仓库 | http://10.0.0.18:30080 | admin / Harbor12345 | node1 + node2 |
| cache | Redis 主 | redis-master.cache.svc:6379 (集群内) | Redis12345 | node1 |
| cache | Redis 从 | redis-slave.cache.svc:6379 (集群内) | Redis12345 | node2 |
| devops | Jenkins | http://10.0.0.18:30081 | admin / 5c61f261a3c746e29fff2225f8be6b50 | node1 |
| logging | Elasticsearch (集群内) | elasticsearch.logging.svc:9200 | 无认证 | node2 |
| logging | Kibana | http://10.0.0.18:30082 | 无账号 (xpack.security=false) | node2 |
| kube-system | Flannel/CoreDNS/kube-proxy 等 | - | - | 全节点 |
| local-path-storage | local-path provisioner | - | - | node1 |

> 所有 NodePort（30080/30081/30082）在任意节点 IP (master/node1/node2) 上都能访问。

## 四、内存资源评估 (每节点 4GB VM，扣除系统可用≈2400MB)

```
k8s-master   Pod req  290M / 2400M   剩余 2110M ✓
k8s-node1    Pod req 1074M / 2400M   剩余 1326M ✓   Redis主256M + Jenkins512M + Harbor Core/Jobsvc/Redis
k8s-node2    Pod req 1746M / 2400M   剩余  654M ✓   Redis从256M + ES768M + Kibana512M + Harbor DB/Portal/Registry
```

## 五、镜像加速配置（containerd hosts.toml）

所有节点 `/etc/containerd/certs.d/` 下配置：

- `registry.k8s.io` → `registry.aliyuncs.com/google_containers`
- `ghcr.io` → `ghcr.m.daocloud.io`
- `docker.io` → `docker.m.daocloud.io`

containerd 必须启用 CRI (`disabled_plugins=[]`) 和 `SystemdCgroup = true`。

## 六、故障排查 (已解决)

| # | 问题 | 根因 | 修复 |
|---|---|---|---|
| 1 | `unknown service runtime.v1.RuntimeService` | Docker 版 containerd 默认禁 CRI | 重写 config.toml，启用 cri 插件 |
| 2 | kubeadm init 报 socket Connection Refused | kubeadm reset 触发 containerd 重启 | reset 后轮询 `crictl version` 最多 60 轮 |
| 3 | registry.k8s.io 拉取超时 | GCP 后端被墙 | `--image-repository=registry.aliyuncs.com/google_containers` |
| 4 | CoreDNS ContainerCreating，loopback 插件缺失 | kubeadm reset 删了 /opt/cni/bin | 重下 containernetworking/plugins v1.5.1 tarball |
| 5 | local-path ConfigMap helperPod.yaml 不存在 | Provisioner 初始化缺失 | kubectl -n local-path-storage patch cm/local-path-config 补 helperPod.yaml |
| 6 | **ConfigMap 缺失 setup/teardown** | helper pod 挂载 script 卷时报 `non-existent config key: setup` | **补丁**：`kubectl patch cm/local-path-config -n local-path-storage --type merge -p '{"data":{"setup":"#!/bin/sh\nmkdir -m 0777 -p $VOL_DIR","teardown":"#!/bin/sh\nrm -rf $VOL_DIR"}}'` |
| 7 | **ClusterRole 缺 pods/log get + events patch** | provisioner 无法读 helper 日志、写 event，helper pod 120s 超时 | **补丁**：重写 ClusterRole 加 `pods/log`(get/list/watch) 和 `events`(patch/update) |
| 8 | harbor-jobservice PVC 被误删后 Deployment Pending | PVC 与 Deployment 强关联 | 手动重建 1Gi local-path PVC |
| 9 | Harbor core 启动超时 CrashLoopBackOff | PostgreSQL 初始化期间 DB 尚未监听 5432 | DB Ready 后重启 core Deployment |
| 10 | **Kibana OOM (FatalProcessOutOfMemory)** | 初始 req=256M/lim=512M 太小，Node.js V8 堆不够 | **升级为 req=512M/lim=1Gi + NODE_OPTIONS=--max-old-space-size=768** |
