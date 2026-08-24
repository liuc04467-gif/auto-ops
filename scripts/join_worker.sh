#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/join_worker.sh
# 描述：K8s Worker 节点加入集群
# 使用节点：k8s-node1 (10.0.0.19)、k8s-node2 (10.0.0.20)
# 前置依赖：
#   - ansible/k8s_setup.yml 已执行（containerd / kubelet / 镜像加速就位）
#   - master 已完成 kubeadm init 并生成 join token
# 用法：./join_worker.sh <master_ip> <token> <ca_hash>
#   也可通过环境变量 MASTER_IP / TOKEN / CA_HASH 传入
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
die()  { log "ERROR $*" >&2; exit 1; }

usage() {
  cat <<EOF
用法：$SCRIPT_NAME <master_ip> <token> <ca_hash>

参数（也可用环境变量 MASTER_IP / TOKEN / CA_HASH 传入）：
  master_ip  master 地址（如 10.0.0.18）
  token      kubeadm join token（kubeadm token create --print-join-command 获取）
  ca_hash    discovery-token-ca-cert-hash（形如 sha256:xxxx...）
EOF
}

# ---- 参数解析 ---------------------------------------------------------------
[[ "${1:-}" =~ ^(-h|--help|help)$ ]] && { usage; exit 0; }

MASTER_IP="${1:-${MASTER_IP:-}}"
TOKEN="${2:-${TOKEN:-}}"
CA_HASH="${3:-${CA_HASH:-}}"

# ---- 输入校验（拒绝占位符 / 非法格式）----------------------------------------
[[ -n "$MASTER_IP" ]] || { usage; die "缺少 master_ip"; }
[[ -n "$TOKEN" ]]    || { usage; die "缺少 token"; }
[[ -n "$CA_HASH" ]]  || { usage; die "缺少 ca_hash"; }

[[ "$MASTER_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || die "非法 master_ip '$MASTER_IP'"

# kubeadm token 形如 xxxxxx.xxxxxxxxxxxxxxxx（小写字母/数字）
[[ "$TOKEN" =~ ^[a-z0-9]{6}\.[a-z0-9]{16}$ ]] || die "非法 token '$TOKEN'（形如 abcdef.0123456789abcdef）"

# ca-cert-hash 形如 sha256:<64位十六进制>
[[ "$CA_HASH" =~ ^sha256:[a-f0-9]{64}$ ]] || die "非法 ca_hash（形如 sha256:<64位十六进制>）"

MASTER_ENDPOINT="${MASTER_IP}:6443"

# ---- containerd 就绪检查 ----------------------------------------------------
info "等待 containerd CRI socket 就绪（最多 120s）"
i=0
while ! crictl version >/dev/null 2>&1; do
  sleep 2; i=$((i + 1))
  [[ $i -ge 60 ]] && die "containerd socket 120s 未就绪"
done
info "containerd socket 就绪（等待 $((i * 2))s）"

# ---- 防火墙放行（Rocky9 默认 firewalld 打开）--------------------------------
info "放行 K8s 相关端口"
for port in 6443/tcp 10250/tcp 10256/tcp 8472/udp 30000-32767/tcp; do
  firewall-cmd --permanent --add-port="$port" 2>/dev/null || true
done
firewall-cmd --reload 2>/dev/null || true

# ---- 内核参数（ip_forward + bridge-nf-call-iptables）------------------------
cat > /etc/sysctl.d/99-k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1 || true

# ---- 加入集群 ---------------------------------------------------------------
info "执行 kubeadm join（$MASTER_ENDPOINT）"
kubeadm join "$MASTER_ENDPOINT" \
  --token "$TOKEN" \
  --discovery-token-ca-cert-hash "$CA_HASH" \
  --cri-socket=unix:///run/containerd/containerd.sock

info "join 完成。在 master 执行 'kubectl get nodes -o wide' 确认"
