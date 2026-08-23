# Redis 应用接入（主从读写分离）

## 目标
- 写操作 → `redis-master.cache.svc:6379`
- 读操作 → `redis-slave.cache.svc:6379`
- 认证密码：`Redis12345`

## 架构
应用 Pod（`opslab` 命名空间）跨命名空间访问 `cache` 命名空间的 Redis 主从，用 FQDN 定位。

## 1. 应用配置（ConfigMap）

见 [k8s/configmap.yaml](../../k8s/configmap.yaml)，关键项：

```yaml
data:
  REDIS_WRITE_HOST: "redis-master.cache.svc.cluster.local"
  REDIS_READ_HOST:  "redis-slave.cache.svc.cluster.local"
  REDIS_PORT:       "6379"
  REDIS_PASSWORD:   "Redis12345"
```

## 2. PHP 示例（web01/web02 应用）

```php
// config/redis.php
$write = new Redis();
$write->connect(getenv('REDIS_WRITE_HOST'), 6379);
$write->auth(getenv('REDIS_PASSWORD'));

$read = new Redis();
$read->connect(getenv('REDIS_READ_HOST'), 6379);
$read->auth(getenv('REDIS_PASSWORD'));
```

PHP Session 共享（php.ini）：

```ini
session.save_handler = redis
session.save_path = "tcp://redis-master.cache.svc:6379?auth=Redis12345"
```

## 3. Node.js (Koa) 示例

```javascript
const redis = require("redis");
const writer = redis.createClient({ url: "redis://:Redis12345@redis-master.cache.svc:6379" });
const reader = redis.createClient({ url: "redis://:Redis12345@redis-slave.cache.svc:6379" });
await Promise.all([writer.connect(), reader.connect()]);
```

## 4. 验证

```bash
# 写主 → 读从
kubectl -n cache exec redis-master-0 -- redis-cli -a Redis12345 SET test "ok"
kubectl -n cache exec redis-slave-0  -- redis-cli -a Redis12345 GET test
# 期望输出: "ok"
```

## 5. 生产建议
- 密码应移入 Secret（当前为教学演示放 ConfigMap）
- 同命名空间可用短名 `redis-master`；跨命名空间必须用 FQDN
- 主从切换后可配合 Redis Sentinel / 应用层探活提升可用性
