#!/bin/bash
# OpsLab - Health check script
# Checks all services across the cluster

echo "=== OpsLab Health Check ==="
echo ""

# 1. HAProxy VIP
echo -n "VIP 10.0.0.100: "
if curl -s -o /dev/null -w "%{http_code}" http://10.0.0.100/health | grep -q 200; then
  echo "OK"
else
  echo "FAIL"
fi

# 2. Web servers
for ip in 10.0.0.13 10.0.0.14; do
  echo -n "Web $ip: "
  if curl -s -o /dev/null -w "%{http_code}" http://$ip/health | grep -q 200; then
    echo "OK"
  else
    echo "FAIL"
  fi
done

# 3. MySQL replication
echo -n "MySQL replication: "
REPL=$(mysql -u root -p'<REDACTED>' -h 10.0.0.16 -e "SHOW REPLICA STATUS\G" 2>/dev/null | grep -E "Running|Behind")
if echo "$REPL" | grep -q "Yes"; then
  echo "OK"
else
  echo "FAIL"
fi

# 4. Prometheus targets
echo -n "Prometheus: "
if curl -s http://10.0.0.17:9090/-/healthy | grep -q "OK"; then
  echo "OK"
else
  echo "FAIL"
fi

# 5. Grafana
echo -n "Grafana: "
if curl -s -o /dev/null -w "%{http_code}" http://10.0.0.17:3000/api/health | grep -q 200; then
  echo "OK"
else
  echo "FAIL"
fi

# 6. Node exporters
echo "Node Exporters:"
for ip in 10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.13 10.0.0.14 10.0.0.15 10.0.0.16 10.0.0.17; do
  echo -n "  $ip:9100: "
  if curl -s -o /dev/null -w "%{http_code}" http://$ip:9100/metrics | grep -q 200; then
    echo "OK"
  else
    echo "FAIL"
  fi
done

echo ""
echo "=== Check complete ==="
