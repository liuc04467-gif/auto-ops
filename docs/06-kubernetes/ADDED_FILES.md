# 06-kubernetes 目录 - 本次新增 / 修改文件清单

> GitHub 仓库: liuc04467-gif/auto-ops
> 生成时间: 2026-08-22

## 已存在 (unchanged 或 minor copy)
- ansible/k8s_setup.yml        ✔ 已存在（K8s 基础预配置 playbook）
- ansible/lb_setup.yml         ✔ 已存在
- ansible/db_setup.yml         ✔ 已存在
- ansible/web_setup.yml        ✔ 已存在
- k8s/deployment.yaml          ✔ 通用 sample
- k8s/service.yaml / hpa.yaml / ingress.yaml / namespace.yaml ✔ 通用 sample

## 本次新增文件

### Ansible/scripts
- ansible/hosts.ini                           ★ 新增（Ansible inventory，含 m1/lb01-02/web01-02/db01-02/k8s-master+node1+node2）
- scripts/init_master.sh                      ★ 新增（k8s-master kubeadm init 脚本，含镜像加速、socket 轮询）
- scripts/join_worker.sh                      ★ 新增（worker kubeadm join 脚本，含 containerd 就绪等待）
- scripts/fix_cni_plugins.sh                  ★ 新增（从 containernetworking/plugins v1.5.1 tarball 恢复 CNI 插件）
- scripts/setup_repo.sh                       ★ 新增（一键 git 提交部署脚本）

### K8s 部署 YAML（helm values + 原生 YAML）
- k8s/harbor-values.yaml                      ★ 新增（Harbor 最小资源 values：关闭 trivy/notary/chartmuseum，TLS off，NodePort 30080）
- k8s/redis_master_slave.yaml                 ★ 新增（Redis 主→node1、从→node2，StatefulSet + ConfigMap，密码 Redis12345）
- k8s/jenkins.yaml                            ★ 新增（Jenkins 部署到 node1，NodePort 30081，10G PVC，JVM -Xms512m -Xmx768m）
- k8s/es_kibana.yaml                          ★ 新增（Elasticsearch 单节点 + Kibana 部署到 node2，vm.max_map_count init container，ES_HEAP 512M，Kibana NODE_OPTIONS max-old-space-size 768）
- k8s/fix_kibana.yaml                         ★ 新增（Kibana OOM 补丁版本，含内存升级与 NODE_OPTIONS）

### 文档
- docs/06-kubernetes/README.md                ★ 新增（K8s 集群 + 中间件部署总览 + 节点分配 + 端口 + 内存评估）
- docs/troubleshooting/06-k8s-middleware-troubleshooting.md  ★ 新增（关键词检索索引：setup/teardown、pods/log/events RBAC、Harbor DB 等待、Kibana OOM、jobservice PVC 删除、socket 未就绪）

## 建议后续补充（尚未入库）

1. README.md / docs/architecture.md 末尾增加 06-kubernetes 目录链接
2. k8s/README.md 从通用 sample 变成"本仓库使用的实际清单 + 一键 apply 顺序"
3. Jenkins Pipeline 示例（cicd/Jenkinsfile 已有，建议增加 k8s agent 模板）
4. Harbor 证书 + TLS 配置 / ingress 暴露（当前使用 NodePort + HTTP，生产建议 Ingress + cert-manager）
5. ES snapshot / 备份脚本
6. 各组件的 liveness/readiness probe 调优参数

## 一键 apply 顺序

```bash
export KUBECONFIG=/root/.kube/config
kubectl apply -f k8s/redis_master_slave.yaml
kubectl apply -f k8s/jenkins.yaml
kubectl apply -f k8s/es_kibana.yaml
helm install harbor harbor/harbor -n harbor --create-namespace -f k8s/harbor-values.yaml
```
