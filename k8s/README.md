# K8s 中间件部署清单

> 集群：K8s v1.31.14 + containerd 2.3.3 + Flannel v0.28.9 + local-path-provisioner v0.0.28

## 一、已部署中间件 & apply 顺序

在 k8s-master 上执行（先 `export KUBECONFIG=/root/.kube/config`）：

```bash
kubectl apply -f k8s/redis_master_slave.yaml   # Redis 主从（node1 主 / node2 从）
kubectl apply -f k8s/jenkins.yaml              # Jenkins（node1）
kubectl apply -f k8s/es_kibana.yaml            # Elasticsearch + Kibana（node2）
helm install harbor harbor/harbor -n harbor --create-namespace -f k8s/harbor-values.yaml
```

## 二、文件清单（已部署）

| 文件 | 组件 | 命名空间 | 部署节点 | 说明 |
|---|---|---|---|---|
| `redis_master_slave.yaml` | Redis 主从 | cache | 主 node1 / 从 node2 | StatefulSet + ConfigMap，密码 Redis12345 |
| `jenkins.yaml` | Jenkins | devops | node1 | Deployment + NodePort 30081 + 10G PVC，JVM -Xms512m -Xmx768m |
| `es_kibana.yaml` | Elasticsearch + Kibana | logging | node2 | 单节点 ES + Kibana，init 设 vm.max_map_count，xpack.security=false |
| `harbor-values.yaml` | Harbor（Helm） | harbor | node1 + node2 | 最小资源，关 trivy/notary/chartmuseum，TLS off，NodePort 30080 |
| `fix_kibana.yaml` | Kibana OOM 补丁 | logging | node2 | 内存升 512M/1Gi + NODE_OPTIONS=--max-old-space-size=768 |

## 三、NodePort 访问入口

| 组件 | 地址 | 账号 |
|---|---|---|
| Harbor | http://10.0.0.18:30080 | admin / Harbor12345 |
| Jenkins | http://10.0.0.18:30081 | admin / 5c61f261a3c746e29fff2225f8be6b50 |
| Kibana | http://10.0.0.18:30082 | 无（xpack.security=false） |

> NodePort 特性：任意节点 IP:端口均可访问（kube-proxy 全节点转发）。

## 四、应用层通用模板（待业务接入）

以下为部署自研应用（PHP Web）的通用模板，尚未绑定实际业务：

| 文件 | 用途 |
|---|---|
| `namespace.yaml` | 创建 opslab 命名空间 |
| `deployment.yaml` | PHP 应用 Deployment（2 副本 + liveness/readiness 探针） |
| `service.yaml` | ClusterIP Service |
| `ingress.yaml` | Nginx Ingress 外部访问 |
| `hpa.yaml` | 自动伸缩（2-10 副本，CPU>70% 或内存>80%） |

## 五、相关文档

- 部署总览：[docs/06-kubernetes/README.md](../docs/06-kubernetes/README.md)
- 故障排查：[docs/troubleshooting/06-k8s-middleware-troubleshooting.md](../docs/troubleshooting/06-k8s-middleware-troubleshooting.md)
- 新增文件清单：[docs/06-kubernetes/ADDED_FILES.md](../docs/06-kubernetes/ADDED_FILES.md)
