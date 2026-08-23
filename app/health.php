<?php
// 健康检查端点：liveness / readiness / startup 探针统一使用
http_response_code(200);
header('Content-Type: text/plain');
echo "OK";
