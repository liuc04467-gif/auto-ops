# Stage 1: Foundation — VM Provisioning & Ansible Init

## Goal
Provision 11 Rocky Linux 9 VMs via kickstart, configure Ansible control node on m1.

## What was done
1. Created kickstart ISO for each VM with static IP, hostname, root password
2. Deployed 11 VMs in batches (memory-aware, max 8GB per batch)
3. Configured Ansible inventory with 7 active nodes
4. Set up SSH key-based authentication from m1 to all nodes
5. Disabled SELinux, configured firewalld, installed common tools

## Playbook
- `ansible/init_servers.yml` — installs EPEL, common tools, chrony, disables SELinux

## Verification
```bash
ansible all -m ping
# All nodes return SUCCESS
```

## Troubleshooting
- VM boot loop: kickstart `poweroff` + disconnect CD-ROM after install
- Black screen at "Basic System": removed `crashkernel=auto` (1G RAM too small)
- Root SSH denied: Rocky 9 defaults to `PermitRootLogin prohibit-password`, fixed in kickstart `%post`
- `missing packages: vim`: added `--ignoremissing` to `%packages`

## Key files changed
- `/etc/ansible/hosts` — Ansible inventory
- `/root/.ssh/authorized_keys` — SSH trust
- `/etc/selinux/config` — SELINUX=disabled
- `/etc/chrony.conf` — time sync
