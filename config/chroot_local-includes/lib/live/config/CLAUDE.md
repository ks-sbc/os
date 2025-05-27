# CLAUDE.md - /config/chroot_local-includes/lib/live/config/

This directory contains live-config hooks that run at boot time to configure the KSBC OS live system.

## Directory Overview

These scripts are part of the live-config framework and run during system startup, after the live filesystem is mounted but before user login. They configure the running system based on boot parameters and system state. Future DRUIDS initialization will happen here.

## Hook Execution

Scripts are executed in numerical order by live-config during boot:
- Lower numbers run first (0000-9999)
- Scripts must be executable
- Run as root in the live environment

## Current Hooks

- **`0000-boot-profile`** - Early boot profiling setup
- **`0001-sane-clock`** - Set system clock to a sane value
- **`1000-remount-procfs`** - Remount /proc with security options
- **`1500-reconfigure-APT`** - Configure APT for the live environment
- **`1600-undivert-APT`** - Restore diverted APT files
- **`2000-aesthetics`** - UI/UX improvements
- **`2000-import-gnupg-key`** - Import GPG keys
- **`2030-systemd`** - systemd-specific configurations
- **`7000-debug`** - Debug mode setup
- **`8000-rootpw`** - Root password configuration
- **`9000-hosts-file`** - Configure /etc/hosts
- **`9980-permissions`** - Fix file permissions
- **`9999-unset-user-account-comment`** - Clean up user account

## How live-config Works

1. live-config runs at boot via systemd service
2. Executes all scripts in `/lib/live/config/` in order
3. Scripts can read boot parameters via `live-config` functions
4. Changes persist for the session but not across reboots

## Writing New Hooks

```bash
#!/bin/sh
# Hook description

. /lib/live/config.sh

# Define hook name
HOOK="hookname"

# Define configuration function
hookname() {
    # Your configuration code here
    echo "Configuring..."
}

# Standard live-config execution
Config
```

## Important Considerations

- These run at every boot (not during build)
- Must be fast - delays boot time
- Should be idempotent (safe to run multiple times)
- Use live-config functions for consistency
- Test thoroughly - errors can prevent boot
- For DRUIDS: Initialize organizational structures here, not in build hooks

## Related Directories
- `/config/chroot_local-hooks/` - Build-time hooks (different!)
- `/lib/live/mount/` - Live filesystem mount points
- `/etc/live/config/` - Runtime configuration
- `/lib/systemd/system/live-config.service` - Service that runs these