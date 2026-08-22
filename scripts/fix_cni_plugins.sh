#!/bin/bash
# ===========================================================================
# 修复 kubeadm reset 后删除 /opt/cni/bin 导致 CoreDNS 卡在 ContainerCreating
# 症状：CoreDNS / Flannel pods 报 failed to find plugin "loopback" in path [/opt/cni/bin]
# 适用：Rocky9 + K8s v1.31 + containerd 2.x
# ===========================================================================
set -e

CNI_VER="v1.5.1"
PKG="cni-plugins-linux-amd64-${CNI_VER}.tgz"
URL="https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/${PKG}"
MIRROR="https://ghcr.m.daocloud.io/https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/${PKG}"

mkdir -p /opt/cni/bin

echo "[1/3] download containernetworking/plugins $CNI_VER"
for u in "$URL" "$MIRROR"; do
  echo "trying $u ..."
  if curl -fsSL -o "/tmp/$PKG" "$u" --connect-timeout 10 --max-time 180 2>/dev/null; then
    echo "[OK] downloaded from $u"
    break
  fi
done

[ -s "/tmp/$PKG" ] || { echo "[FAIL] download failed"; exit 1; }

echo "[2/3] extract to /opt/cni/bin"
tar xzf "/tmp/$PKG" -C /opt/cni/bin
ls /opt/cni/bin | grep -E 'loopback|bridge|flannel|host-local' && echo "[OK] plugins installed" || echo "[WARN] some plugins missing"

echo "[3/3] restart containerd + kubelet (触发 flannel 重新写 /etc/cni/net.d)"
systemctl restart containerd kubelet
sleep 5
echo "[DONE] fix_cni_plugins completed. Check: kubectl -n kube-system get pods | grep coredns"
