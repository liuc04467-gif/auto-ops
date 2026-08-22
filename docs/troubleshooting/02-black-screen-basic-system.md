# Black Screen at "Reached target Basic System"

## Symptom
VM boots, shows `Reached target Basic System.`, then black screen with blinking cursor.

## Root cause
- `crashkernel=auto` in bootloader config
- On 1G RAM VMs, kernel crash dump reservation fails
- `quiet` parameter hides the error messages

## Fix
- Remove `crashkernel` from kickstart `bootloader` line
- Remove `quiet` to see boot logs
```kickstart
bootloader --location=mbr
```

## Verification
- Boot logs scroll visible
- System reaches `login:` prompt
