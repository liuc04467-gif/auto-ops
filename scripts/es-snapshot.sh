#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/es-snapshot.sh
# 描述：Elasticsearch 快照备份（K8s logging 命名空间）
# 用法：./es-snapshot.sh
# 定时：crontab -e 添加  0 2 * * * /test-ops/scripts/es-snapshot.sh
# 前置：ES 需配置 path.repo 并挂载持久化卷（见 docs/06-kubernetes/13-monitoring-k8s.md）
# 环境变量：
#   ES_URL     ES 地址          默认 http://elasticsearch.logging.svc.cluster.local:9200
#   REPO       快照仓库名        默认 backup
#   KEEP_DAYS  快照保留天数      默认 7
#   INDICES    备份索引表达式    默认 k8s-logs-*
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
warn() { log "WARN  $*" >&2; }
die()  { log "ERROR $*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令 '$1'"
}

validate_uint() {
  local val="$1" label="$2"
  [[ "$val" =~ ^[0-9]+$ ]] || die "$label 必须为非负整数，当前值：'$val'"
}

# ---- 运行配置 ---------------------------------------------------------------
ES_URL="${ES_URL:-http://elasticsearch.logging.svc.cluster.local:9200}"
REPO="${REPO:-backup}"
KEEP_DAYS="${KEEP_DAYS:-7}"
INDICES="${INDICES:-k8s-logs-*}"

# 输入校验
[[ "$REPO" =~ ^[a-zA-Z0-9_-]+$ ]] || die "非法仓库名 '$REPO'"
validate_uint "$KEEP_DAYS" "KEEP_DAYS"

# 依赖检查
require_command curl
require_command python3

SNAPSHOT="snapshot_$(date +%Y%m%d_%H%M%S)"

# ---- 1. 注册快照仓库（已存在时忽略）----------------------------------------
info "注册快照仓库 '$REPO' ..."
if ! curl -sf -X PUT "${ES_URL}/_snapshot/${REPO}" \
  -H 'Content-Type: application/json' \
  -d '{"type":"fs","settings":{"location":"/usr/share/elasticsearch/data/backup","compress":true}}'; then
  warn "仓库注册失败或已存在（忽略，继续）"
fi

# ---- 2. 创建快照（异步）----------------------------------------------------
info "提交快照任务：${REPO}/${SNAPSHOT}"
curl -sf -X PUT "${ES_URL}/_snapshot/${REPO}/${SNAPSHOT}?wait_for_completion=false" \
  -H 'Content-Type: application/json' \
  -d "{\"indices\":\"${INDICES}\",\"ignore_unavailable\":true,\"include_global_state\":false}" \
  || die "快照提交失败"

# ---- 3. 清理超过 KEEP_DAYS 天的旧快照 --------------------------------------
info "清理 ${KEEP_DAYS} 天前的旧快照 ..."
# 通过环境变量把 KEEP_DAYS 传给 python，避免字符串拼接注入
SNAP_JSON="$(curl -sf "${ES_URL}/_snapshot/${REPO}/_all" || echo '{}')"
OLD_SNAPSHOTS="$(printf '%s' "$SNAP_JSON" | KEEP_DAYS="$KEEP_DAYS" python3 -c '
import os, sys, json, time
keep = int(os.environ["KEEP_DAYS"])
d = json.load(sys.stdin)
now = time.time()
for s in d.get("snapshots", []):
    ts = s.get("end_time_in_millis", now * 1000) / 1000
    if now - ts > keep * 86400:
        print(s["snapshot"])
')"

for s in $OLD_SNAPSHOTS; do
  if curl -sf -X DELETE "${ES_URL}/_snapshot/${REPO}/$s"; then
    info "已删除过期快照：$s"
  else
    warn "删除快照失败：$s"
  fi
done

info "备份任务完成"
