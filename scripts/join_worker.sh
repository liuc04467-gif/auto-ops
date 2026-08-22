#!/bin/bash
# ===========================================================================
# K8s Worker 加入集群脚本
# 使用节点: k8s-node1 (10.0.0.19), k8s-node2 (10.0.0.20)
# 前置依赖:
#   - ansible/k8s_setup.yml 已经执行完成 (containerd、kubelet、镜像加速就位)
#   - master 已完成 kubeadm init 且输出了 join token / discovery-token-ca-cert-hash
# ===========================================================================
set -e

# ---- 参数（执行前请从 master 端 kubeadm token create --print-join-command 获取）----
MASTER_ENDPOINT="10.0.0.18:6443"
TOKEN="xxx.xxxxxxxxxxxxxxxx"                 # FIXME 从 master `kubeadm token list` 获取
CA_HASH="sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # FIXME

# ---- containerd 就绪检查（kubeadm reset 后会重启 containerd，socket 需要等待）----
i=0
while ! crictl version >/dev/null 2>&1; do
  sleep 2; i=$((i+1))
  [ $i -ge 60 ] && echo "[FAIL] containerd socket not ready after 120s" && exit 1
done
echo "[OK] containerd socket ready (waited $((i*2))s)"

# ---- 防火墙（Rocky9 默认 firewalld 打开，保证 kube-proxy/VXLAN/NodePort 放行）----
for port in 6443/tcp 10250/tcp 10256/tcp 8472/udp 30000-32767/tcp; do
  firewall-cmd --permanent --add-port=$port 2>/dev/null || true
done
firewall-cmd --reload || true

# ---- 内核参数（ip_forward + bridge-nf-call-iptables）----
cat > /etc/sysctl.d/99-k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

# ---- 开始 join ----
kubeadm join $MASTER_ENDPOINT   --token $TOKEN   --discovery-token-ca-cert-hash $CA_HASH   --cri-socket=unix:///run/containerd/containerd.sock

echo "[DONE] join finished. Use 'kubectl get nodes -o wide' on master to confirm."
