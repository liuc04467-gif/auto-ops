# K8s Middleware 故障与修复检索日志

> 部署日期 2026-08-22 ｜ 集群版本 K8s v1.31.14 ｜ 容器运行时 containerd 2.3.3

本文件提供"关键词 → 根因 → 修复命令"的**检索式索引**，便于在 GitHub / 本地快速定位对应问题。

---

### 关键词: local-path, helper pod, setup, teardown, ConfigMap

```text
症状: helper pod 卡在 ContainerCreating，describe 报
      MountVolume.SetUp failed for volume "script" :
      configmap references non-existent config key: setup
根因: 官方 local-path YAML 默认只提供了 helperPod.yaml 片段，但新版 helm apply 时
      必须同时具备 setup / teardown 两个脚本 key 才允许挂载 script ConfigMap。
修复:
  kubectl -n local-path-storage patch configmap local-path-config --type merge -p '{
    "data":{
      "setup":    "#!/bin/sh\nset -eu\nmkdir -m 0777 -p "$VOL_DIR"\n",
      "teardown": "#!/bin/sh\nset -eu\nrm -rf "$VOL_DIR"\n"
    }
  }'
  kubectl -n local-path-storage delete pod -l app=local-path-provisioner   # 重启 provisioner
  kubectl -n harbor delete pvc --all   # 触发重新供应
```

---

### 关键词: events forbidden patch, pods/log forbidden, 120 seconds timeout

```text
症状: PVC 一直 Pending，provisioner 日志报
      cannot get resource "pods/log" in API group ""
      cannot patch resource "events" in API group ""
      最终  "create process timeout after 120 seconds"
根因: ClusterRole 缺少两个关键 verbs: pods/log → get/list 与 events → patch/update。
修复:
  cat > /tmp/lp-role-full.yaml << 'EOF'
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: local-path-provisioner-role
  rules:
    - apiGroups: [""]
      resources: ["nodes","persistentvolumeclaims","configmaps","pods","pods/log","services"]
      verbs: ["get","list","watch","create","delete","patch","update"]
    - apiGroups: [""]
      resources: ["persistentvolumes"]
      verbs: ["get","list","watch","create","delete","patch","update"]
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["create","patch","update"]
    - apiGroups: ["storage.k8s.io"]
      resources: ["storageclasses"]
      verbs: ["get","list","watch"]
  EOF
  kubectl apply -f /tmp/lp-role-full.yaml
```

---

### 关键词: Harbor core CrashLoopBackOff, harbor-database:5432 connection refused

```text
症状: harbor-core 启动日志持续 dial tcp ...:5432: connection refused，
      60s 后 FATAL failed to initialize database。
根因: Harbor 初始化顺序没有依赖。core 启动时 PostgreSQL 实例虽已 Running 但尚未监听。
修复:
  # 等 PG Ready（数据库日志出现 "database system is ready to accept connections"）
  kubectl -n harbor logs harbor-database-0 | tail -5
  # 然后重启 core / jobservice
  kubectl -n harbor delete pod -l component=core --force --grace-period=0
  kubectl -n harbor delete pod -l component=jobservice --force --grace-period=0
```

---

### 关键词: Kibana OOM, FatalProcessOutOfMemory, NODE_OPTIONS

```text
症状: kibana pod restarts >= 3，describe 显示 OOMKilled；
      日志尾部出现 v8::Utils::ReportOOMFailure / FatalProcessOutOfMemory。
根因: Kibana 默认 req=256M/lim=512M 太小，Node.js V8 老年代默认堆受 cgroup limit 挤压。
修复:
  kubectl -n logging patch deploy kibana --type merge -p '
  spec:
    template:
      spec:
        containers:
        - name: kibana
          env:
          - name: NODE_OPTIONS
            value: "--max-old-space-size=768"
          resources:
            requests: {cpu: 200m, memory: 512Mi}
            limits:   {cpu: "1",  memory: 1Gi}
  '
  # 等待 rollout 后验证 "Kibana is now available"
  kubectl -n logging logs -l app=kibana --tail=5 | grep available
```

---

### 关键词: harbor-jobservice, persistentvolumeclaim being deleted

```text
症状: jobservice deployment 的 pod 一直 Pending，describe event:
      persistentvolumeclaim "harbor-jobservice" not found。
根因: 清理过程中 harbor-jobservice PVC 与它关联的 PV 已被 Delete 策略回收，而
      Jobservice Deployment 是 volumeClaimTemplates 之外通过 PVC 引用的，
      需手动重建同名 PVC。
修复:
  cat > /tmp/hjs-pvc.yaml << 'EOF'
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: harbor-jobservice
    namespace: harbor
  spec:
    accessModes: [ReadWriteOnce]
    storageClassName: local-path
    resources:
      requests: {storage: 1Gi}
  EOF
  kubectl apply -f /tmp/hjs-pvc.yaml
```

---

### 关键词: K8s join socket refused, crictl version not ready

```text
症状: kubeadm reset 后立即 kubeadm init/join，报
      [ERROR CRI]: container runtime is not running: rpc error ... connection refused
根因: reset 触发 containerd restart，socket 重建需要几秒到十几秒。
修复:
  i=0
  while ! crictl version >/dev/null 2>&1; do
    sleep 2; i=$((i+1))
    [ $i -ge 60 ] && echo "containerd socket not ready after 120s, abort" && exit 1
  done
  kubeadm init/join ...
```
