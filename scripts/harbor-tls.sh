#!/bin/bash
# 为 Harbor 生成自签证书，并创建 K8s TLS Secret
# 用法：bash scripts/harbor-tls.sh
set -e

DOMAIN="harbor.opslab.local"
CERT_DIR="/root/harbor-certs"

mkdir -p "$CERT_DIR" && cd "$CERT_DIR"

# 生成 10 年自签证书（含 SAN）
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -days 3650 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN"

# 创建 K8s Secret（harbor 命名空间）
kubectl -n harbor create secret tls harbor-tls \
  --cert=tls.crt --key=tls.key 2>/dev/null \
  || kubectl -n harbor delete secret harbor-tls

echo "[OK] 证书:   $CERT_DIR/tls.crt"
echo "[OK] 密钥:   $CERT_DIR/tls.key"
echo "[OK] Secret: harbor/harbor-tls"

# 将证书分发到各节点供 containerd 信任（HTTPS 阶段需要）
# scp tls.crt root@10.0.0.19:/etc/containerd/certs.d/harbor.opslab.local/ca.crt
# scp tls.crt root@10.0.0.20:/etc/containerd/certs.d/harbor.opslab.local/ca.crt
