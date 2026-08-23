# 日志接入：Fluent Bit → Elasticsearch → Kibana

## 目标
容器 stdout/stderr → Fluent Bit → Elasticsearch → Kibana 索引模式。

## 1. Fluent Bit DaemonSet

见 [k8s/fluentbit.yaml](../../k8s/fluentbit.yaml)。相比通用模板的三处修正：

1. **补 ClusterRoleBinding**（原方案遗漏，否则 RBAC 不生效）
2. **挂载 `/var/lib/containerd/containers`**（本项目运行时为 containerd，非 docker）
3. **使用 CRI 解析器**（containerd 日志为 CRI 格式）

## 2. Kibana 创建索引模式

1. 打开 `http://10.0.0.18:30082`
2. Stack Management → Index Patterns → Create
3. Pattern: `k8s-logs-*`，Time field: `@timestamp`
4. 回到 Discover 即可查看容器日志

## 3. 验证

```bash
kubectl -n kube-system get ds fluentbit
curl http://elasticsearch.logging.svc:9200/_cat/indices?v | grep k8s-logs
```

## 4. 说明
- ES 单节点、`xpack.security=false`（无认证），仅供内网教学演示
- 生产建议：ES 多节点 + TLS 认证 + 数据保留策略（Index Lifecycle Management）
