# Root SSH Login Denied

## Symptom
SSH connection to VM succeeds, but root password is rejected.

## Root cause
Rocky Linux 9 defaults to `PermitRootLogin prohibit-password` in sshd_config,
which means root can only login with SSH keys, not passwords.

## Fix
In kickstart `%post`:
```bash
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
```

## Alternative (more secure)
- Create `opsuser` in wheel group
- `echo "opsuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ops`
- Use `opsuser` for SSH, `sudo -i` for root
