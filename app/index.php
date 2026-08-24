<?php
/**
 * OpsLab 示例应用
 *
 * 功能：
 *   1. 展示容器身份（Pod 名 / IP）
 *   2. Redis 读写分离验证（写 master / 读 slave）
 *   3. MySQL 连通性验证
 *
 * 工程要点：
 *   - 依赖配置一律通过环境变量注入，读取时做白名单校验与类型检查
 *   - 所有动态输出统一经 e() 做 HTML 转义，避免 XSS
 *   - 依赖扩展缺失时给出明确提示，不直接致命错误
 *   - 连接异常统一 try/catch 捕获，错误信息脱敏输出
 *
 * 环境变量：
 *   REDIS_WRITE_HOST / REDIS_READ_HOST / REDIS_PASSWORD
 *   DB_HOST / DB_NAME / DB_USER / DB_PASSWORD
 */

declare(strict_types=1);

/**
 * HTML 输出转义，防止 XSS。
 */
function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * 读取环境变量，未设置或为空时返回默认值。
 */
function envOr(string $key, string $default): string
{
    $value = getenv($key);
    return ($value === false || $value === '') ? $default : $value;
}

/**
 * 校验主机名/服务名：仅允许字母、数字、点、连字符（K8s service DNS 命名规范）。
 */
function isValidHost(string $host): bool
{
    return preg_match('/^[a-zA-Z0-9][a-zA-Z0-9.-]{0,252}$/', $host) === 1;
}

/**
 * 校验数据库名：仅允许字母、数字、下划线。
 */
function isValidDbName(string $name): bool
{
    return preg_match('/^[a-zA-Z0-9_]{1,64}$/', $name) === 1;
}

// ---------------------------------------------------------------------------
// 配置读取与校验
// ---------------------------------------------------------------------------
$writeHost = envOr('REDIS_WRITE_HOST', 'redis-master.cache.svc.cluster.local');
$readHost  = envOr('REDIS_READ_HOST', 'redis-slave.cache.svc.cluster.local');
$redisPass = envOr('REDIS_PASSWORD', '');

$dbHost = envOr('DB_HOST', 'mysql.opslab.svc.cluster.local');
$dbName = envOr('DB_NAME', 'opslab');
$dbUser = envOr('DB_USER', 'webapp');
$dbPass = envOr('DB_PASSWORD', '');

// 白名单校验：非法主机名/库名直接拒绝，避免 DNS/DSN 注入
if (!isValidHost($writeHost) || !isValidHost($readHost) || !isValidHost($dbHost)) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    exit('配置错误：主机名非法');
}
if (!isValidDbName($dbName)) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    exit('配置错误：数据库名非法');
}

// 容器身份
$host = gethostname() ?: 'unknown';
$ip   = $_SERVER['SERVER_ADDR'] ?? 'unknown';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <title>OpsLab Demo</title>
</head>
<body>
<h1>OpsLab Demo</h1>
<p>Pod: <b><?= e($host) ?></b> &nbsp;|&nbsp; IP: <b><?= e($ip) ?></b></p>

<?php
// ---------------------------------------------------------------------------
// Redis 读写分离验证
// ---------------------------------------------------------------------------
if (!extension_loaded('redis')) {
    echo "<p>Redis: <span style='color:orange'>php-redis 扩展未加载</span></p>\n";
} else {
    // 写 master
    try {
        $w = new Redis();
        $w->connect($writeHost, 6379, 1.5);
        if ($redisPass !== '') {
            $w->auth($redisPass);
        }
        $w->set('demo:test', 'ok-' . $host);
        echo "<p>Redis 写入 (master): <span style='color:green'>OK</span></p>\n";
        $w->close();
    } catch (Throwable $e) {
        echo "<p>Redis 写入失败: " . e($e->getMessage()) . "</p>\n";
    }

    // 读 slave
    try {
        $r = new Redis();
        $r->connect($readHost, 6379, 1.5);
        if ($redisPass !== '') {
            $r->auth($redisPass);
        }
        $val = $r->get('demo:test');
        echo "<p>Redis 读取 (slave): <span style='color:green'>" . e((string) $val) . "</span></p>\n";
        $r->close();
    } catch (Throwable $e) {
        echo "<p>Redis 读取失败: " . e($e->getMessage()) . "</p>\n";
    }
}

// ---------------------------------------------------------------------------
// MySQL 连通性验证
// ---------------------------------------------------------------------------
if (!extension_loaded('pdo_mysql')) {
    echo "<p>MySQL: <span style='color:orange'>pdo_mysql 扩展未加载</span></p>\n";
} else {
    $dsn = "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4";
    try {
        $pdo = new PDO($dsn, $dbUser, $dbPass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_TIMEOUT => 3,
        ]);
        echo "<p>MySQL 连接: <span style='color:green'>OK</span></p>\n";
    } catch (Throwable $e) {
        // 仅输出精简错误，避免泄露主机/账号等敏感信息
        echo "<p>MySQL 连接失败: " . e($e->getMessage()) . "</p>\n";
    }
}
?>
</body>
</html>
