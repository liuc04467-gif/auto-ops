# GitHub 仓库日志检索连接

> 仓库地址:  https://github.com/liuc04467-gif/auto-ops
> 本地副本:  m1 管理机 /test-ops   (m1: 10.0.0.10)

## Web 端直达连接

说明：下列所有连接均可直接在浏览器打开查看对应文件。
如果你在 GitHub 搜索框想搜"关键词"，可用：`repo:liuc04467-gif/auto-ops <keyword>`。

### 一、K8s 集群部署

| 文件名 | GitHub 直达链接 |
|---|---|
| K8s 部署总览 README | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/06-kubernetes/README.md |
| 本次新增文件清单 / apply 顺序 | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/06-kubernetes/ADDED_FILES.md |
| Harbor values (最小资源版) | https://github.com/liuc04467-gif/auto-ops/blob/main/k8s/harbor-values.yaml |
| Redis 主从部署 YAML | https://github.com/liuc04467-gif/auto-ops/blob/main/k8s/redis_master_slave.yaml |
| Jenkins 部署 YAML | https://github.com/liuc04467-gif/auto-ops/blob/main/k8s/jenkins.yaml |
| ES + Kibana 部署 YAML | https://github.com/liuc04467-gif/auto-ops/blob/main/k8s/es_kibana.yaml |
| Kibana OOM 补丁版 | https://github.com/liuc04467-gif/auto-ops/blob/main/k8s/fix_kibana.yaml |

### 二、Ansible / Scripts 初始化

| 文件名 | GitHub 直达链接 |
|---|---|
| 基础初始化 Ansible playbook (主机名、SELinux、时区、firewalld) | https://github.com/liuc04467-gif/auto-ops/blob/main/ansible/init_servers.yml |
| K8s 节点预配置 (containerd、kubelet、镜像加速) | https://github.com/liuc04467-gif/auto-ops/blob/main/ansible/k8s_setup.yml |
| Ansible inventory (主机清单，含 LB/Web/DB/K8s 11 节点) | https://github.com/liuc04467-gif/auto-ops/blob/main/ansible/hosts.ini |
| K8s master 初始化 | https://github.com/liuc04467-gif/auto-ops/blob/main/scripts/init_master.sh |
| K8s worker 加入集群 | https://github.com/liuc04467-gif/auto-ops/blob/main/scripts/join_worker.sh |
| 修复 CNI 插件缺失 | https://github.com/liuc04467-gif/auto-ops/blob/main/scripts/fix_cni_plugins.sh |

### 三、故障排查（关键词搜索入口）

GitHub 全站搜索语法（直接复制到 GitHub 搜索框）：

- local-path setup/teardown 缺失
  `repo:liuc04467-gif/auto-ops "non-existent config key: setup"`
- RBAC pods/log events 权限不足
  `repo:liuc04467-gif/auto-ops "cannot get resource pods/log"`
- Harbor core 连接数据库超时
  `repo:liuc04467-gif/auto-ops "failed to connect to tcp://harbor-database:5432"`
- Kibana OOM / OutOfMemory
  `repo:liuc04467-gif/auto-ops "FatalProcessOutOfMemory"`
- jobservice PVC 被删
  `repo:liuc04467-gif/auto-ops "harbor-jobservice" pvc`
- containerd socket 未就绪
  `repo:liuc04467-gif/auto-ops "crictl version"` wait

直达文件链接：

| 故障文档 | GitHub 直达链接 |
|---|---|
| VM 启动循环 | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/01-vm-boot-loop.md |
| Basic System 黑屏 | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/02-black-screen-basic-system.md |
| VRRP 单播 NAT 问题 | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/03-vrrp-unicast-nat.md |
| MySQL 主从同步错误 | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/04-mysql-replication-error.md |
| Root SSH 被拒 (Rocky9) | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/05-root-ssh-denied.md |
| **K8s 中间件故障（本次）** | https://github.com/liuc04467-gif/auto-ops/blob/main/docs/troubleshooting/06-k8s-middleware-troubleshooting.md |

## 四、GitHub 仓库已存在但尚未更新的文件（需要人工 review）

| 路径 | 说明 | 建议 |
|---|---|---|
| k8s/README.md | 目前是通用 k8s yaml 介绍 | 更新为实际部署清单 + apply 顺序 |
| cicd/Jenkinsfile | 已有，但不包含 k8s agent 模板 | 参考 k8s/jenkins.yaml 追加 kubernetes cloud 示例 |
| docs/architecture.md | 尚未包含 K8s 3 节点分层 | 在末尾追加「第六阶段：容器/K8s 层」架构图 |
| README.md | 顶层未链接 06-kubernetes | 补充目录跳转 |
| configs/prometheus/prometheus.yml | 已存在监控配置 | 可考虑追加 K8s ServiceMonitor / 节点 exporters 条目 |

---

**注**：所有文件已在 m1 /test-ops 本地完成 copy + 创建。执行如下命令即可推送：

```bash
cd /test-ops
git status
git add -A
git commit -m "feat: add K8s cluster + middleware (Harbor/Redis/Jenkins/ES/Kibana) deployments + troubleshooting docs"
git push origin main
```
