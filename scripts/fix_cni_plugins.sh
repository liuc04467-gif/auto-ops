#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/fix_cni_plugins.sh
# 描述：修复 kubeadm reset 后删除 /opt/cni/bin 导致 CoreDNS 卡在 ContainerCreating
# 症状：CoreDNS / Flannel pods 报 failed to find plugin "loopback" in path [/opt/cni/bin]
# 适用：Rocky9 + K8s v1.31 + containerd 2.x
# 用法：./fix_cni_plugins.sh [CNI 版本]   （默认 v1.5.1）
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
die()  { log "ERROR $*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令 '$1'"
}

# ---- 参数与校验 -------------------------------------------------------------
CNI_VER="${1:-v1.5.1}"
[[ "$CNI_VER" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "非法 CNI 版本 '$CNI_VER'，格式如 v1.5.1"

PKG="cni-plugins-linux-amd64-${CNI_VER}.tgz"
URL="https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/${PKG}"
MIRROR="https://ghcr.m.daocloud.io/https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/${PKG}"

# 依赖检查
require_command curl
require_command tar

mkdir -p /opt/cni/bin

# ---- 1. 下载（主源失败自动切换镜像源）--------------------------------------
info "下载 containernetworking/plugins ${CNI_VER}"
DOWNLOADED=0
for u in "$URL" "$MIRROR"; do
  info "尝试下载：$u"
  if curl -fsSL -o "/tmp/$PKG" "$u" --connect-timeout 10 --max-time 180; then
    info "下载成功：$u"
    DOWNLOADED=1
    break
  fi
  warn "下载失败：$u"
done

[[ "$DOWNLOADED" -eq 1 ]] || die "所有下载源均失败"
[[ -s "/tmp/$PKG" ]] || die "下载文件为空：/tmp/$PKG"

# ---- 2. 解压 ----------------------------------------------------------------
info "解压到 /opt/cni/bin"
tar xzf "/tmp/$PKG" -C /opt/cni/bin

# 校验关键插件是否就位
if ls /opt/cni/bin | grep -qE 'loopback|bridge|flannel|host-local'; then
  info "关键 CNI 插件已安装"
else
  die "关键 CNI 插件缺失，解压可能不完整"
fi

# ---- 3. 重启服务 ------------------------------------------------------------
info "重启 containerd + kubelet（触发 flannel 重写 /etc/cni/net.d）"
systemctl restart containerd kubelet
sleep 5

info "完成。验证：kubectl -n kube-system get pods | grep coredns"
