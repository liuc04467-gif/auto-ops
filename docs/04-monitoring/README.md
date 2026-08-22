# Stage 4: Monitoring — Prometheus + Grafana + Exporters

## Goal
Full-stack monitoring: Node, MySQL, HAProxy exporters → Prometheus → Grafana.

## What was done
1. Deployed Node Exporter on all 8 active nodes (:9100)
2. Deployed MySQL Exporter on db01/db02 (:9104)
3. Deployed HAProxy Exporter on lb01/lb02 (:9101)
4. Installed Prometheus on monitor (:9090, 15s scrape interval)
5. Installed Grafana on monitor (:3000)

## Scrape targets
| Job | Targets | Port |
|-----|---------|------|
| node | 10.0.0.10-17 | 9100 |
| mysql | 10.0.0.15, 10.0.0.16 | 9104 |
| haproxy | 10.0.0.11, 10.0.0.12 | 9101 |

## Verification
```bash
# Prometheus targets
curl http://10.0.0.17:9090/api/v1/targets | jq '.data.activeTargets[].health'
# All "up"

# Grafana
# http://10.0.0.17:3000 (admin/admin)
# Data source: http://10.0.0.17:9090
# Dashboard: Node Exporter Full (ID: 1860)
```

## Playbook
- `ansible/monitor_setup.yml`

## Grafana setup steps
1. Login admin/admin, change password
2. Add data source → Prometheus → URL: http://10.0.0.17:9090
3. Import dashboard ID 1860 (Node Exporter Full)
4. Create custom dashboard for MySQL + HAProxy

## Planned
- Alertmanager with webhook to Feishu
- Custom Grafana dashboards
- Long-term storage with Thanos
