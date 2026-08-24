#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/harbor-tls.sh
# 描述：为 Harbor 生成自签证书，并写入 K8s TLS Secret
# 用法：./harbor-tls.sh [域名] [证书目录] [命名空间]
#   域名       默认 harbor.opslab.local
#   证书目录   默认 /root/harbor-certs
#   命名空间   默认 harbor
# 环境变量：DOMAIN / CERT_DIR / NAMESPACE / SECRET_NAME(默认 harbor-tls) / DAYS(默认 3650)
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
die()  { log "ERROR $*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令 '$1'"
}

usage() {
  cat <<EOF
用法：$SCRIPT_NAME [域名] [证书目录] [命名空间]

参数（均可省略，默认值见下）：
  域名        Harbor 域名（默认 harbor.opslab.local）
  证书目录    证书保存目录（默认 /root/harbor-certs）
  命名空间    K8s Secret 所在命名空间（默认 harbor）

环境变量：DOMAIN / CERT_DIR / NAMESPACE / SECRET_NAME / DAYS
EOF
}

# ---- 参数解析 ---------------------------------------------------------------
[[ "${1:-}" =~ ^(-h|--help|help)$ ]] && { usage; exit 0; }

DOMAIN="${1:-${DOMAIN:-harbor.opslab.local}}"
CERT_DIR="${2:-${CERT_DIR:-/root/harbor-certs}}"
NAMESPACE="${3:-${NAMESPACE:-harbor}}"
SECRET_NAME="${SECRET_NAME:-harbor-tls}"
DAYS="${DAYS:-3650}"

# ---- 输入校验 ---------------------------------------------------------------
[[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] || die "非法域名 '$DOMAIN'"
[[ "$NAMESPACE" =~ ^[a-z0-9-]+$ ]]        || die "非法命名空间 '$NAMESPACE'"
[[ "$SECRET_NAME" =~ ^[a-z0-9.-]+$ ]]      || die "非法 Secret 名 '$SECRET_NAME'"
[[ "$DAYS" =~ ^[0-9]+$ ]]                  || die "DAYS 必须为正整数"
[[ "$DAYS" -ge 1 && "$DAYS" -le 36500 ]]   || die "DAYS 超出合理范围（1-36500）"

# ---- 依赖检查 ---------------------------------------------------------------
require_command openssl
require_command kubectl

# ---- 生成证书 ---------------------------------------------------------------
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

info "生成自签证书（CN=$DOMAIN，有效期 $DAYS 天）"
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -days "$DAYS" \
  -keyout tls.key -out tls.crt \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN"

# ---- 写入 K8s Secret（幂等：先删后建）--------------------------------------
info "写入 K8s Secret：$NAMESPACE/$SECRET_NAME"
kubectl -n "$NAMESPACE" delete secret "$SECRET_NAME" --ignore-not-found
kubectl -n "$NAMESPACE" create secret tls "$SECRET_NAME" --cert=tls.crt --key=tls.key

info "完成"
info "证书：  $CERT_DIR/tls.crt"
info "私钥：  $CERT_DIR/tls.key"
info "Secret：$NAMESPACE/$SECRET_NAME"

# 提示：HTTPS 阶段需将证书分发到各节点供 containerd 信任
#   scp tls.crt root@10.0.0.19:/etc/containerd/certs.d/$DOMAIN/ca.crt
#   scp tls.crt root@10.0.0.20:/etc/containerd/certs.d/$DOMAIN/ca.crt
