# K8s 监控补齐（node_exporter + kube-state-metrics）

## 1. node_exporter（节点主机指标）
```bash
kubectl apply -f k8s/node-exporter.yaml
```
- DaemonSet + hostNetwork，每个节点 9100 端口暴露
- VM 层 Prometheus（10.0.0.17）已配 `k8s-node` job，直接采集 10.0.0.18-20:9100

## 2. kube-state-metrics（K8s 对象状态指标）
```bash
kubectl apply -f k8s/kube-state-metrics.yaml
```
- 采集 Deployment/Pod/Service/PVC 等对象状态
- 采集地址：`kube-state-metrics.kube-system.svc:8080/metrics`

## 3. Prometheus 追加采集（VM 层 Prometheus）
```yaml
# configs/prometheus/prometheus.yml 追加
- job_name: kube-state-metrics
  static_configs:
    - targets: ['10.0.0.18:8080']   # kube-state-metrics 所在节点 + hostNetwork 或 nodePort
```

## 4. ES 快照前置配置
在 `k8s/es_kibana.yaml` 的 ES 容器追加：
```yaml
env:
  - name: path.repo
    value: /usr/share/elasticsearch/data/backup
```
并挂载持久化卷后，即可运行 `scripts/es-snapshot.sh`。

## 后续进阶（未落地）
- Prometheus Operator + ServiceMonitor 自动化发现（当前为静态配置）
- Alertmanager 告警规则、Grafana K8s 官方 dashboard
