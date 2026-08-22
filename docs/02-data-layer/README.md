# Stage 2: Data Layer — MySQL Master-Slave Replication

## Goal
Set up MySQL 8.0 master-slave replication with read/write split.

## What was done
1. Installed MySQL 8.0 on db01 (master) and db02 (slave)
2. Configured binlog on master (server-id=1, binlog-do-db=opslab)
3. Created replication user `repl` with REPLICATION SLAVE privilege
4. Configured slave to replicate from master
5. Created application database `opslab` and user `webapp`
6. Deployed PHP test page demonstrating read/write split

## Architecture
```
PHP app (web01/web02)
  ├── Write (INSERT/UPDATE/DELETE) → db01 (10.0.0.15) master
  └── Read (SELECT)               → db02 (10.0.0.16) slave
```

## Verification
```bash
# Replication status
mysql -u root -p -e "SHOW REPLICA STATUS\G"  # on db02
# Replica_IO_Running: Yes
# Replica_SQL_Running: Yes
# Seconds_Behind_Source: 0

# Application test
curl http://10.0.0.100/db_test.php
# Master: CONNECTED, Slave: CONNECTED, data replicates
```

## Playbook
- `ansible/db_setup.yml`

## Troubleshooting
- Replication error (data already exists): `SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE`
- Temporary password not found in log: fallback to `mysql -u root` (Rocky 9 default)
- MySQL exporter auth: created `exporter` user with PROCESS + REPLICATION CLIENT

## Planned
- Redis Sentinel for caching layer
- ProxySQL or MHA for automatic failover
- mysqldump + binlog backup strategy
