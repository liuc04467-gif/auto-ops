#!/bin/bash
# ============================================================
# Elasticsearch 快照备份（K8s logging 命名空间）
# 用法：bash scripts/es-snapshot.sh
# 定时：crontab -e 添加  0 2 * * * /root/scripts/es-snapshot.sh
# 前置：ES 需配置 path.repo 并挂载持久化卷（详见 docs/06-kubernetes/13-monitoring-k8s.md）
# ============================================================
set -euo pipefail

ES_URL="${ES_URL:-http://elasticsearch.logging.svc.cluster.local:9200}"
REPO="${REPO:-backup}"
SNAPSHOT="snapshot_$(date +%Y%m%d_%H%M%S)"
KEEP_DAYS="${KEEP_DAYS:-7}"

echo "[$(date '+%F %T')] 开始快照备份"

# 1. 注册快照仓库（已存在时忽略）
curl -sf -X PUT "${ES_URL}/_snapshot/${REPO}" \
  -H 'Content-Type: application/json' \
  -d '{"type":"fs","settings":{"location":"/usr/share/elasticsearch/data/backup","compress":true}}' \
  || echo "[WARN] 仓库注册失败或已存在（忽略）"

# 2. 创建快照（异步）
curl -sf -X PUT "${ES_URL}/_snapshot/${REPO}/${SNAPSHOT}?wait_for_completion=false" \
  -H 'Content-Type: application/json' \
  -d '{"indices":"k8s-logs-*","ignore_unavailable":true,"include_global_state":false}' \
  && echo "[INFO] 快照已提交: ${REPO}/${SNAPSHOT}"

# 3. 清理超过 KEEP_DAYS 天的旧快照
OLD_SNAPSHOTS=$(curl -sf "${ES_URL}/_snapshot/${REPO}/_all" | python3 -c "
import sys, json, time
d = json.load(sys.stdin)
now = time.time()
for s in d.get('snapshots', []):
    ts = s.get('end_time_in_millis', now * 1000) / 1000
    if now - ts > ${KEEP_DAYS} * 86400:
        print(s['snapshot'])
" 2>/dev/null)

for s in $OLD_SNAPSHOTS; do
  curl -sf -X DELETE "${ES_URL}/_snapshot/${REPO}/$s" && echo "[INFO] 已删除过期快照: $s"
done

echo "[$(date '+%F %T')] 备份任务完成"
