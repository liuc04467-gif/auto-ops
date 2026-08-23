<?php
// OpsLab 示例应用：展示容器身份 + Redis 读写分离 + MySQL 连通性
// 对应 configmap.yaml（Redis）与 mysql-statefulset.yaml 的 Secret（MySQL）
$host = gethostname();
$ip   = $_SERVER['SERVER_ADDR'] ?? 'unknown';

header('Content-Type: text/html; charset=utf-8');
echo "<h1>OpsLab Demo</h1>\n";
echo "<p>Pod: <b>$host</b> &nbsp;|&nbsp; IP: <b>$ip</b></p>\n";

// ---- Redis 读写分离 ----
$writeHost = getenv('REDIS_WRITE_HOST') ?: 'redis-master.cache.svc.cluster.local';
$readHost  = getenv('REDIS_READ_HOST')  ?: 'redis-slave.cache.svc.cluster.local';
$redisPass = getenv('REDIS_PASSWORD')   ?: 'Redis12345';

try {
    $w = new Redis();
    $w->connect($writeHost, 6379, 1);
    $w->auth($redisPass);
    $w->set('demo:test', 'ok-' . $host);
    echo "<p>Redis 写入 (master): <span style='color:green'>OK</span></p>\n";
} catch (Throwable $e) {
    echo "<p>Redis 写入失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

try {
    $r = new Redis();
    $r->connect($readHost, 6379, 1);
    $r->auth($redisPass);
    $val = $r->get('demo:test');
    echo "<p>Redis 读取 (slave): <span style='color:green'>$val</span></p>\n";
} catch (Throwable $e) {
    echo "<p>Redis 读取失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

// ---- MySQL 连接 ----
$dbHost = getenv('DB_HOST') ?: 'mysql.opslab.svc.cluster.local';
$dbName = getenv('DB_NAME') ?: 'opslab';
$dbUser = getenv('DB_USER') ?: 'webapp';
$dbPass = getenv('DB_PASSWORD') ?: '';

try {
    $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass);
    echo "<p>MySQL 连接: <span style='color:green'>OK</span></p>\n";
} catch (Throwable $e) {
    echo "<p>MySQL 连接失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}
