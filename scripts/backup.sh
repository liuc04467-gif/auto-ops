#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/backup.sh
# 描述：MySQL 逻辑备份（mysqldump），支持 gzip 压缩与过期备份自动清理
# 用法：./backup.sh [数据库名]
#   数据库名  可选，默认 opslab；仅允许字母/数字/下划线，杜绝注入
# 定时示例：crontab -e 添加  0 2 * * * /test-ops/scripts/backup.sh opslab
# 环境变量（均可选，有安全默认值）：
#   DB_USER     数据库用户          默认 root
#   DB_PASS     数据库密码          默认空（推荐用 ~/.my.cnf 注入）
#   BACKUP_DIR  备份目录            默认 /data/backup/mysql
#   KEEP_DAYS   保留天数            默认 7
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_DB="opslab"

# ---- 日志函数 ---------------------------------------------------------------
log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
warn() { log "WARN  $*" >&2; }
die()  { log "ERROR $*" >&2; exit 1; }

# ---- 通用校验函数 -----------------------------------------------------------
require_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令 '$1'，请先安装"
}

# 数据库名白名单：仅允许字母/数字/下划线，长度 1-64
validate_db_name() {
  local name="$1"
  [[ "$name" =~ ^[a-zA-Z0-9_]{1,64}$ ]] \
    || die "非法数据库名 '$name'：仅允许字母/数字/下划线（1-64 位）"
}

# 非负整数校验
validate_uint() {
  local val="$1" label="$2"
  [[ "$val" =~ ^[0-9]+$ ]] || die "$label 必须为非负整数，当前值：'$val'"
}

# ---- 参数解析与校验 ---------------------------------------------------------
DB_NAME="${1:-$DEFAULT_DB}"
validate_db_name "$DB_NAME"

# ---- 运行配置（环境变量优先，其次默认值）-------------------------------------
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-}"
BACKUP_DIR="${BACKUP_DIR:-/data/backup/mysql}"
KEEP_DAYS="${KEEP_DAYS:-7}"
validate_uint "$KEEP_DAYS" "KEEP_DAYS"

# mysqldump 参数：密码优先走 ~/.my.cnf，避免出现在进程列表
MYSQLDUMP_ARGS=(-u"$DB_USER")
if [[ -n "$DB_PASS" ]]; then
  warn "检测到命令行传密码，生产环境建议改用 ~/.my.cnf（权限 600）"
  MYSQLDUMP_ARGS+=(-p"$DB_PASS")
fi

# ---- 依赖检查 ---------------------------------------------------------------
require_command mysqldump
require_command gzip
require_command find

# ---- 备份目录准备 -----------------------------------------------------------
mkdir -p "$BACKUP_DIR" || die "无法创建备份目录 '$BACKUP_DIR'"
[[ -d "$BACKUP_DIR" && -w "$BACKUP_DIR" ]] || die "备份目录不存在或不可写：'$BACKUP_DIR'"

DATE="$(date +%Y%m%d_%H%M%S)"
DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"
GZIP_FILE="${DUMP_FILE}.gz"

# 失败时清理半成品文件，避免残留损坏备份
cleanup_failed() {
  warn "备份失败，清理临时文件：$DUMP_FILE / $GZIP_FILE"
  rm -f "$DUMP_FILE" "$GZIP_FILE"
}
trap cleanup_failed ERR

# ---- 执行备份 ---------------------------------------------------------------
info "开始备份数据库 '$DB_NAME' → $GZIP_FILE"
mysqldump "${MYSQLDUMP_ARGS[@]}" \
  --single-transaction \
  --routines \
  --triggers \
  --set-gtid-purged=OFF \
  "$DB_NAME" > "$DUMP_FILE"

# 校验 dump 非空，避免把空文件误判为成功
[[ -s "$DUMP_FILE" ]] || die "备份文件为空：数据库 '$DB_NAME' 可能不存在或权限不足"

info "压缩备份文件 ..."
gzip -f "$DUMP_FILE"

# 备份成功，解除失败清理钩子
trap - ERR

# ---- 清理过期备份 -----------------------------------------------------------
info "清理 ${KEEP_DAYS} 天前的旧备份 ..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime "+${KEEP_DAYS}" -print -delete

info "备份完成：$GZIP_FILE"
