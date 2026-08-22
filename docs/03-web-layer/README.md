# Stage 3: Web Layer — Nginx + PHP-FPM + NFS

## Goal
Deploy Nginx + PHP-FPM with NFS shared storage across web01/web02.

## What was done
1. Configured m1 as NFS server (export /data/web to 10.0.0.0/24)
2. Mounted NFS on web01/web02 at /data/web
3. Installed Nginx + PHP-FPM 8.0
4. Configured PHP-FPM to run as nginx user
5. Deployed test pages: index.php (hostname/IP), db_test.php (MySQL), health (OK)
6. HAProxy load balances traffic to web01/web02 via roundrobin

## Architecture
```
m1 (NFS server) /data/web ←──── web01, web02 (NFS clients)
                                    |
                              Nginx :80 → PHP-FPM (unix socket)
                                    |
                              /data/web/html/ (shared)
```

## Verification
```bash
# Round-robin test
curl http://10.0.0.100/index.php  # → web01.opslab.local
curl http://10.0.0.100/index.php  # → web02.opslab.local

# NFS sync test
# Write file on web01, read on web02 → same content

# Health check
curl http://10.0.0.100/health  # → OK
```

## Playbook
- `ansible/web_setup.yml`

## Troubleshooting
- PHP-FPM socket permission: changed user/group to nginx in www.conf
- NFS mount fails: firewalld needs nfs, rpc-bind, mountd services
- PHP session dir: /var/lib/php/session must be owned by nginx
