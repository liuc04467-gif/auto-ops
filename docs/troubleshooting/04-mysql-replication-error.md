# MySQL Replication Sync Error

## Symptom
`SHOW REPLICA STATUS\G` shows `Last_Error` with duplicate key or data exists.

## Root cause
Test data inserted on slave directly, causing conflict with master binlog replay.

## Fix
```sql
-- On slave (db02)
STOP REPLICA;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
START REPLICA;

-- Verify
SHOW REPLICA STATUS\G;
-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
```

## Prevention
- Never write to slave directly
- Use `read_only=1` in my.cnf on slave
- Application-level read/write split
