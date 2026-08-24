<?php
/**
 * 健康检查端点
 *
 * 供 Kubernetes liveness / readiness / startup 探针及 HAProxy health check 使用。
 * 仅返回 200 + "OK"，保持最轻量，避免健康检查本身引入外部依赖或延长响应时间。
 */

declare(strict_types=1);

http_response_code(200);
header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');

echo "OK";
