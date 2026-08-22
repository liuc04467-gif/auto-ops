# VRRP Multicast Fails on VMware NAT

## Symptom
Keepalived MASTER/BACKUP both claim MASTER, VIP not stable.

## Root cause
- VMware NAT network doesn't forward multicast packets
- Default VRRP uses multicast (224.0.0.18)

## Fix
Configure Keepalived to use unicast:
```
vrrp_instance VI_1 {
    unicast_src_ip 10.0.0.11
    unicast_peer {
        10.0.0.12
    }
}
```

## Verification
```bash
# On lb01
ip addr show ens33 | grep 10.0.0.100
# VIP present on MASTER only

# Failover test: stop haproxy on lb01
systemctl stop haproxy  # on lb01
# VIP moves to lb02 within 2 seconds
```
