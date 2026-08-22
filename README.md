# OpsLab 全栈实战项目
用户 → VIP 10.0.0.100 → HAProxy (lb01/lb02) → web01/web02 → db01(写) / db02(读)
                                 │                                  │
                           Keepalived VRRP                     binlog 复制
                                 │                                  │
                           NFS 共享存储 (m1) ←─────────────────┘
                                 │
                           Prometheus 监控 (monitor)


























