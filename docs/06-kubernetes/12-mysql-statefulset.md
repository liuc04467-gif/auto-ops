# MySQL StatefulSet 迁移（VM → K8s）

## 目标
将 VM 层 db01/db02 的 MySQL 主从，迁移到 K8s 的 MySQL StatefulSet（单副本起步）。

## VM 层 vs K8s 层对比
| 维度 | VM 层（传统） | K8s（StatefulSet） |
|---|---|---|
| 高可用 | GTID 主从 + 手动切换 | 稳定标识 `mysql-0` + PVC 持久化 |
| 数据 | /data/mysql 本地盘 | local-path PV 动态供给 |
| 访问 | 10.0.0.15/16:3306 | `mysql.opslab.svc.cluster.local:3306` |
| 扩展 | 需手动配从库 | 起步单副本，可加 replicas + 主从 Sidecar |

## 部署
```bash
kubectl apply -f k8s/mysql-statefulset.yaml
```

## 数据迁移（手动，一次性）
```bash
# 1. db01 导出全库
mysqldump -uroot -p123456 --single-transaction --all-databases > /tmp/opslab.sql

# 2. 拷贝到 K8s 的 MySQL pod 并导入
kubectl -n opslab cp /tmp/opslab.sql mysql-0:/tmp/opslab.sql
kubectl -n opslab exec -i mysql-0 -- mysql -uroot -p123456 < /tmp/opslab.sql
```

## 注意
- 密码存放在 Secret `mysql-secret`（`MYSQL_PASSWORD` 为 `<REDACTED>`，生产替换强密码）
- 应用连接配置见 `k8s/deployment.yaml` 的 `DB_*` 环境变量（引用该 Secret）
