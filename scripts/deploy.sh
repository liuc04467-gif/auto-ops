#!/usr/bin/env bash
# =============================================================================
# 脚本：scripts/deploy.sh
# 描述：统一部署入口，按「阶段」运行对应 Ansible playbook
# 用法：./deploy.sh <阶段> [阶段...]
#   阶段：init | lb | web | db | monitor | k8s | all
# 示例：
#   ./deploy.sh web           # 只部署 Web 层
#   ./deploy.sh db monitor    # 部署数据层 + 监控层
#   ./deploy.sh all           # 按依赖顺序全量部署（init→lb→web→db→monitor）
# 环境变量：
#   INVENTORY   Ansible inventory 路径（默认 ansible/hosts.ini）
# =============================================================================
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
# 仓库根目录（脚本位于 scripts/ 下，向上取一级）
readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PLAYBOOK_DIR="${REPO_DIR}/ansible"
readonly INVENTORY="${INVENTORY:-${PLAYBOOK_DIR}/hosts.ini}"

# 阶段 → playbook 映射（声明式，避免散落的 case 分支）
declare -A STAGES=(
  [init]=init_servers.yml
  [lb]=lb_setup.yml
  [web]=web_setup.yml
  [db]=db_setup.yml
  [monitor]=monitor_setup.yml
  [k8s]=k8s_setup.yml
)
# 全量部署的固定顺序（保证依赖关系正确）
readonly FULL_ORDER=(init lb web db monitor)

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
info() { log "INFO  $*"; }
die()  { log "ERROR $*" >&2; exit 1; }

usage() {
  cat <<EOF
用法：$SCRIPT_NAME <阶段> [阶段...]

阶段：
  init     基础初始化（软件包 / 时间 / 防火墙）
  lb       负载均衡层（HAProxy + Keepalived）
  web      Web 应用层（Nginx + PHP-FPM + NFS）
  db       数据层（MySQL 主从复制）
  monitor  监控层（Prometheus + Grafana + Exporters）
  k8s      Kubernetes 集群（kubeadm + containerd + Calico）
  all      按顺序执行 init→lb→web→db→monitor

示例：
  $SCRIPT_NAME web
  $SCRIPT_NAME db monitor
  $SCRIPT_NAME all
EOF
}

# ---- 参数解析 ---------------------------------------------------------------
[[ $# -ge 1 ]] || { usage; die "缺少阶段参数"; }
for a in "$@"; do
  case "$a" in
    -h|--help|help) usage; exit 0 ;;
  esac
done

# ---- 阶段合法性校验 ---------------------------------------------------------
for stage in "$@"; do
  [[ "$stage" == "all" || -n "${STAGES[$stage]:-}" ]] \
    || die "未知阶段 '$stage'，可用：init lb web db monitor k8s all"
done

# ---- 依赖检查 ---------------------------------------------------------------
command -v ansible-playbook >/dev/null 2>&1 || die "缺少命令 ansible-playbook，请先安装 Ansible"
[[ -f "$INVENTORY" ]] || die "找不到 inventory 文件：$INVENTORY"

info "inventory：$INVENTORY"

# ---- 运行单个 playbook ------------------------------------------------------
run_playbook() {
  local stage="$1"
  local playbook="${STAGES[$stage]}"
  local path="${PLAYBOOK_DIR}/${playbook}"
  [[ -f "$path" ]] || die "找不到 playbook：$path"
  info "执行阶段 [$stage] → $playbook"
  ansible-playbook -i "$INVENTORY" "$path"
}

# ---- 展开执行列表（all 展开为固定顺序）--------------------------------------
STAGE_LIST=()
for stage in "$@"; do
  if [[ "$stage" == "all" ]]; then
    STAGE_LIST+=("${FULL_ORDER[@]}")
  else
    STAGE_LIST+=("$stage")
  fi
done

for stage in "${STAGE_LIST[@]}"; do
  run_playbook "$stage"
done

info "部署完成"
