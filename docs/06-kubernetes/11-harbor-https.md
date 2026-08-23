# Harbor HTTPS（Ingress + 自签证书）

## 目标
用 `https://harbor.opslab.local` 替代 `http://10.0.0.18:30080`，采用信任自签证书的最小方案（无 cert-manager）。

## 1. DNS 解析

内网 DNS 或本机 hosts 添加：

```
10.0.0.18  harbor.opslab.local
```

## 2. 生成自签证书

```bash
bash scripts/harbor-tls.sh
```

脚本会生成 `/root/harbor-certs/tls.crt + tls.key`，并创建 Secret `harbor/harbor-tls`。

## 3. 安装 Ingress Controller

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.https=30443
```

## 4. 切换 Harbor 为 Ingress + TLS

```bash
helm upgrade harbor harbor/harbor -n harbor -f k8s/harbor-values-ingress.yaml
```

values 见 [k8s/harbor-values-ingress.yaml](../../k8s/harbor-values-ingress.yaml)。

## 5. containerd 信任自签证书（所有节点）

```bash
# 拷贝 tls.crt 到每个节点作为 CA
scp /root/harbor-certs/tls.crt root@10.0.0.19:/etc/containerd/certs.d/harbor.opslab.local/ca.crt
scp /root/harbor-certs/tls.crt root@10.0.0.20:/etc/containerd/certs.d/harbor.opslab.local/ca.crt
systemctl restart containerd
```

并在各节点 `/etc/containerd/certs.d/harbor.opslab.local/hosts.toml` 配置：

```toml
server = "https://harbor.opslab.local"
[host."https://harbor.opslab.local"]
  capabilities = ["pull", "resolve"]
  ca = ["/etc/containerd/certs.d/harbor.opslab.local/ca.crt"]
```

## 6. 验证

```bash
curl -k https://harbor.opslab.local/api/v2.0/health

# node 上拉镜像测试
crictl pull harbor.opslab.local/ops-app/webapp:1
```
