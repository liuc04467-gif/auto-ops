# VM Boot Loop After Installation

## Symptom
After kickstart installation completes, VM reboots and enters installation again.

## Root cause
- CD-ROM still connected
- BIOS boot order set to `cdrom`
- VM boots from ISO instead of disk

## Fix
1. After kickstart `poweroff`, disconnect CD-ROM in .vmx:
   ```
   sata0:0.present = "FALSE"
   sata0:1.present = "FALSE"
   ```
2. Boot again → boots from disk

## Prevention
Always disconnect CD-ROM after installation in automation scripts.
