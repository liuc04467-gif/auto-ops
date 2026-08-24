#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/init_master.sh
# 描述：初始化 k8s-master 控制平面（kubeadm init + Flannel CNI + join 命令生成）
# 运行节点：k8s-master (10.0.0.18)
# 说明：脚本内多处命令允许失败并显式判断退出码，故不启用 set -e，
#       仅启用 -u（未定义变量报错）与 -o pipefail（管道失败可捕获）。
# =============================================================================
set -uo pipefail
LOG=/root/init_master.log
FLAG_DONE=/root/init_master.done
FLAG_FAIL=/root/init_master.failed
rm -f $FLAG_DONE $FLAG_FAIL
exec > >(tee -i $LOG) 2>&1

export KUBECONFIG=/root/.kube/config
export CONTAINER_RUNTIME_ENDPOINT=unix:///run/containerd/containerd.sock
CRI=unix:///run/containerd/containerd.sock
ALI="registry.aliyuncs.com/google_containers"
MASTER_IP="10.0.0.18"
POD_CIDR="10.244.0.0/16"
SVC_CIDR="10.96.0.0/12"
VER="v1.31.14"

# ---- 输入校验 ---------------------------------------------------------------
[[ "$VER" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "ERROR 非法 K8s 版本 '$VER'"; exit 2; }
[[ "$MASTER_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || { echo "ERROR 非法 master IP '$MASTER_IP'"; exit 2; }

echo "======== [T0] $(date '+%H:%M:%S') ========"
echo "host=$(hostname -s) CONTAINER_RUNTIME_ENDPOINT=$CONTAINER_RUNTIME_ENDPOINT"
crictl version
echo ""

echo "======== [T1] $(date '+%H:%M:%S') Cleanup previous state ========"
kubeadm reset -f 2>&1 | tail -5
rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /root/.kube /etc/cni/net.d /opt/cni
# 清理残留静态Pod容器
for c in $(crictl ps -aq 2>/dev/null); do
  crictl stop "$c" >/dev/null 2>&1
  crictl rm -f "$c" >/dev/null 2>&1
done

# --- 关键：kubeadm reset 会触发 containerd 重启，必须轮询等待 CRI socket 重新就绪 ---
echo "等待 containerd CRI socket 就绪 (最多 60 秒)..."
READY=0
for i in $(seq 1 30); do
  sleep 2
  if systemctl is-active --quiet containerd; then
    if crictl version >/dev/null 2>&1; then
      READY=1
      echo "  就绪 (${i}x2s 轮次). crictl 可达."
      break
    fi
  else
    echo "  containerd 未 active，尝试 systemctl start containerd ..."
    systemctl start containerd 2>/dev/null
  fi
done
if [ $READY -ne 1 ]; then
  echo "!!! containerd 60 秒内未就绪，退出"
  touch $FLAG_FAIL
  exit 3
fi

echo "cleanup done"
echo ""

echo "======== [T2] $(date '+%H:%M:%S') kubeadm config images list (aliyun) ========"
kubeadm config images list --kubernetes-version=$VER --image-repository=$ALI
echo ""

echo "======== [T3] $(date '+%H:%M:%S') kubeadm config images pull ========"
kubeadm config images pull \
  --kubernetes-version=$VER \
  --cri-socket=$CRI \
  --image-repository=$ALI
echo "images pulled"
crictl images
echo ""

echo "======== [T4] $(date '+%H:%M:%S') kubeadm init ========"
kubeadm init \
  --apiserver-advertise-address=${MASTER_IP} \
  --apiserver-bind-port=6443 \
  --control-plane-endpoint=${MASTER_IP}:6443 \
  --kubernetes-version=$VER \
  --pod-network-cidr=$POD_CIDR \
  --service-cidr=$SVC_CIDR \
  --image-repository=$ALI \
  --cri-socket=$CRI \
  --node-name=k8s-master \
  --upload-certs 2>&1 | tail -80
INIT_RC=${PIPESTATUS[0]}
if [ $INIT_RC -ne 0 ]; then
  echo "!!! kubeadm init FAILED (rc=$INIT_RC)"
  touch $FLAG_FAIL
  exit 1
fi
echo ""

echo "======== [T5] $(date '+%H:%M:%S') 配置 kubeconfig ========"
mkdir -p $HOME/.kube
\cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown 0:0 $HOME/.kube/config
chmod 600 $HOME/.kube/config
grep -q 'KUBECONFIG=/root/.kube/config' /root/.bashrc || echo 'export KUBECONFIG=/root/.kube/config' >> /root/.bashrc
kubectl cluster-info | head -8
echo ""

echo "======== [T6] $(date '+%H:%M:%S') 安装 Flannel CNI ========"
CNI_OK=0
# 方案1: 尝试 daocloud/github 下载 kube-flannel.yml
for DL_URL in \
  "https://ghfast.top/https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml" \
  "https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml" \
  "https://kgithub.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"; do
  echo "  -> 尝试下载: $DL_URL"
  curl -sSL --connect-timeout 15 --max-time 90 "$DL_URL" -o /tmp/kube-flannel.yml 2>&1 | tail -2
  if [ -s /tmp/kube-flannel.yml ] && grep -q 'kube-flannel-cfg' /tmp/kube-flannel.yml; then
    echo "     下载成功，确保 --iface=ens33"
    # 确保 flanneld 绑定 ens33
    if grep -q -- '--iface=' /tmp/kube-flannel.yml; then
      sed -i -E 's|--iface=[a-zA-Z0-9._-]+|--iface=ens33|g' /tmp/kube-flannel.yml
    else
      sed -i 's|--kube-subnet-mgr|--kube-subnet-mgr\n        - --iface=ens33|g' /tmp/kube-flannel.yml
    fi
    kubectl apply -f /tmp/kube-flannel.yml 2>&1 | tail -10
    if [ ${PIPESTATUS[0]} -eq 0 ]; then CNI_OK=1; break; fi
  fi
done

# 方案2: 直接内联 YAML（用 docker.io 镜像，之前containerd已经配置了daocloud加速）
if [ $CNI_OK -ne 1 ]; then
  echo "  -> 使用内联 Flannel v0.25.5 YAML"
  cat > /tmp/kube-flannel.yml << 'FLANNEL_EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: kube-flannel
  labels:
    k8s-app: flannel
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flannel
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["list", "watch"]
  - apiGroups: [""]
    resources: ["nodes/status"]
    verbs: ["patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-flannel
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-flannel
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-flannel
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      },
      "Interface": "ens33"
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-flannel
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/os
                    operator: In
                    values: [linux]
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
        - operator: Exists
          effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni-plugin
        image: docker.io/flannel/flannel-cni-plugin:v1.6.0-flannel1
        command: ["cp", "-f", "/flannel", "/opt/cni/bin/flannel"]
        volumeMounts:
        - name: cni-plugin
          mountPath: /opt/cni/bin
      - name: install-cni
        image: docker.io/flannel/flannel:v0.25.5
        command: ["cp", "-f", "/etc/kube-flannel/cni-conf.json", "/etc/cni/net.d/10-flannel.conflist"]
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: docker.io/flannel/flannel:v0.25.5
        command: ["/opt/bin/flanneld"]
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=ens33
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
        - name: xtables-lock
          mountPath: /run/xtables.lock
      volumes:
      - name: run
        hostPath: { path: /run/flannel }
      - name: cni-plugin
        hostPath: { path: /opt/cni/bin }
      - name: cni
        hostPath: { path: /etc/cni/net.d }
      - name: flannel-cfg
        configMap: { name: kube-flannel-cfg }
      - name: xtables-lock
        hostPath: { path: /run/xtables.lock, type: FileOrCreate }
FLANNEL_EOF
  kubectl apply -f /tmp/kube-flannel.yml 2>&1 | tail -10
  CNI_OK=$?
fi

echo "CNI_OK=$CNI_OK"
echo ""

echo "======== [T7] $(date '+%H:%M:%S') Join command ========"
kubeadm token create --print-join-command | tee /root/kubeadm_join.sh
chmod 700 /root/kubeadm_join.sh
echo ""

echo "======== [T8] $(date '+%H:%M:%S') 初步状态 ========"
echo "--- nodes ---"
kubectl get nodes -o wide
echo "--- pods -A (前30行) ---"
kubectl get pods -A | head -30

echo ""
echo "======== [DONE] $(date '+%H:%M:%S') ========"
touch $FLAG_DONE
