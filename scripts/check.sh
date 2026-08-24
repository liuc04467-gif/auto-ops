#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/check.sh
# 描述：集群健康检查——VIP / Web / MySQL 复制 / Prometheus / Grafana / Node Exporter
# 用法：./check.sh
# 退出码：0 = 全部通过；1 = 存在失败项（可接入告警或 CI）
# 说明：检查项之间互相独立，单项失败不中断，最终汇总退出码
# 环境变量（均可覆盖默认拓扑）：
#   VIP / WEB_SERVERS / MYSQL_HOST / PROMETHEUS_HOST / GRAFANA_HOST / NODE_EXPORTERS
# =============================================================================
set -uo pipefail   # 故意不加 -e：健康检查需要逐项继续

readonly SCRIPT_NAME="$(basename "$0")"
readonly CURL_OPTS=(-s --connect-timeout 3 --max-time 5)

# ---- 拓扑配置（环境变量覆盖默认值）------------------------------------------
VIP="${VIP:-10.0.0.100}"
read -r -a WEB_SERVERS <<< "${WEB_SERVERS:-10.0.0.13 10.0.0.14}"
MYSQL_HOST="${MYSQL_HOST:-10.0.0.16}"
PROMETHEUS_HOST="${PROMETHEUS_HOST:-10.0.0.17}"
GRAFANA_HOST="${GRAFANA_HOST:-10.0.0.17}"
read -r -a NODE_EXPORTERS <<< "${NODE_EXPORTERS:-10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.13 10.0.0.14 10.0.0.15 10.0.0.16 10.0.0.17}"

# ---- 计数与输出 -------------------------------------------------------------
PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); printf '[ OK ] %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf '[FAIL] %s\n' "$*" >&2; }

# HTTP 状态码校验
check_http() {
  local label="$1" url="$2" expect="${3:-200}" code
  code="$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)"
  if [[ "$code" == "$expect" ]]; then
    ok "$label"
  else
    fail "$label（期望 HTTP $expect，实际 '$code'）"
  fi
}

# TCP 端口连通性校验（无 curl 场景的兜底）
check_port() {
  local label="$1" host="$2" port="$3"
  if timeout 3 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
    ok "$label"
  else
    fail "$label（$host:$port 不可达）"
  fi
}

echo "=== OpsLab 健康检查 $(date '+%F %T') ==="

# 1. VIP（HAProxy 健康端点）
check_http "VIP 负载均衡（$VIP）" "http://$VIP/health" 200

# 2. Web 服务器
for ip in "${WEB_SERVERS[@]}"; do
  check_http "Web 服务（$ip）" "http://$ip/health" 200
done

# 3. MySQL 复制状态
if command -v mysql >/dev/null 2>&1; then
  repl="$(mysql -h "$MYSQL_HOST" -N -e "SHOW REPLICA STATUS\G" 2>/dev/null || true)"
  io="$(printf '%s\n' "$repl" | sed -n 's/.*Replica_IO_Running: *//p' | tail -1)"
  sql="$(printf '%s\n' "$repl" | sed -n 's/.*Replica_SQL_Running: *//p' | tail -1)"
  if [[ "$io" == "Yes" && "$sql" == "Yes" ]]; then
    ok "MySQL 复制（$MYSQL_HOST）"
  else
    fail "MySQL 复制（$MYSQL_HOST，IO=$io SQL=$sql）"
  fi
else
  check_port "MySQL 端口（$MYSQL_HOST:3306）" "$MYSQL_HOST" 3306
fi

# 4. Prometheus
check_http "Prometheus（$PROMETHEUS_HOST:9090）" "http://$PROMETHEUS_HOST:9090/-/healthy" 200

# 5. Grafana
check_http "Grafana（$GRAFANA_HOST:3000）" "http://$GRAFANA_HOST:3000/api/health" 200

# 6. Node Exporters
for ip in "${NODE_EXPORTERS[@]}"; do
  check_http "Node Exporter（$ip:9100）" "http://$ip:9100/metrics" 200
done

echo ""
echo "=== 检查完成：通过 $PASS 项，失败 $FAIL 项 ==="

# 存在失败项时以非零退出（便于接入告警 / CI）
[[ "$FAIL" -eq 0 ]]
