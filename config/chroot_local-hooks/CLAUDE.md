# CLAUDE.md - /config/chroot_local-hooks/

This directory contains hooks that run during the KSBC OS build process to configure the live system. These scripts run in the chroot environment after packages are installed but before the filesystem is finalized.

## Directory Overview

Hooks are executed in alphanumeric order. The numbering convention indicates execution order and purpose. Future DRUIDS components will be integrated through hooks in this directory.

## Execution Order & Categories

### 01-0X: Early Validation & Basic Setup
- **`01-check-*`** - Validation checks (dot-orig files, AppArmor, etc.)
- **`01-configure-pam`** - PAM (authentication) configuration

### 02-09: User & System Setup
- **`04-change-gids-and-uids`** - Set up user/group IDs
- **`05-adduser_*`** - Create system users (persistent-storage, etc.)
- **`06-adduser_*`** - More system users (clearnet, htp, upgrade users)
- **`08-install-Perl-programs`** - Install Perl-based tools
- **`09-*`** - Configure applications (torsocks, pidgin)

### 10-19: Browser Setup
- **`10-tbb`** - Tor Browser setup
- **`11-localize_browser`** - Browser localization
- **`11-patch-thunderbird`** - Thunderbird modifications
- **`11-unsafe-browser`** - Unsafe Browser configuration
- **`14-generate-tor-browser-profile`** - Create browser profile
- **`15-tor-browser-bookmarks`** - Set up bookmarks

### 20-29: Desktop Environment
- **`16-greeter`** - Tails Greeter setup
- **`17-locales`** - System locale configuration
- **`20-dconf_update`** - GNOME settings via dconf
- **`22-plymouth`** - Boot splash configuration
- **`23-fake-gnome-backgrounds`** - Minimize GNOME backgrounds

### 30-39: Additional Software
- **`30-flatpak`** - Flatpak configuration
- **`31-gdm-tails`** - GDM (login manager) setup

### 40-49: Security & System Configuration
- **`40-iptables`** - Firewall rules
- **`44-remove-unused-AppArmor-profiles`** - AppArmor cleanup
- **`45-enable-AppArmor-profiles`** - Enable AppArmor
- **`48-tweak-AppArmor-profiles`** - AppArmor adjustments
- **`49-generate-sudoers`** - sudo configuration

### 50-59: Services & Applications
- **`50-dkms`** - Dynamic Kernel Module Support
- **`52-update-systemd-units`** - systemd service configuration
- **`53-*-menu`** - Application menu entries
- **`55-update-mime-database`** - MIME type associations

### 60-79: Hardware & Network
- **`60-copy-syslinux-modules`** - Bootloader files
- **`62-haveged`** - Entropy daemon setup
- **`70-wget`** - wget configuration
- **`80-block-network`** - Network blocking setup

### 98-99: Final Cleanup & Validation
- **`98-remove_unwanted_*`** - Remove unnecessary files/packages
- **`99-*`** - Final cleanup and permission fixes
- **`99-zzz_*`** - Very last checks and cleanup

## Important Hooks

### Critical for KSBC OS Functionality
- **`04-change-gids-and-uids`** - Essential for user isolation
- **`10-tbb`** - Tor Browser is core to KSBC OS
- **`40-iptables`** - Firewall for traffic control
- **`45-enable-AppArmor-profiles`** - Security confinement
- **Future DRUIDS hooks** - Will configure organizational memory systems

### Build Reproducibility
- **`99-set_mtimes`** - Set modification times for reproducibility
- **`99-zzzzzz_reproducible-builds-post-processing`** - Final reproducibility tweaks

## Working Tips

- Hook names must start with NN- where NN is a number
- Make hooks executable: `chmod +x hookname`
- Test hooks in a chroot environment when possible
- Use `set -e` for error handling
- Log important actions for debugging
- Check existing hooks before adding new functionality
- For DRUIDS hooks: Ensure no network dependencies during build

## Common Patterns

```bash
#!/bin/sh
set -e  # Exit on error
set -u  # Exit on undefined variable

echo "Running hook: description"

# Your code here
```

## Related Files
- `/config/chroot_local-includes/` - Files these hooks might configure
- `/config/chroot_local-patches/` - Patches that complement hooks
- `/config/chroot_local-packageslists/` - Packages that hooks configure
- `/auto/build` - Build script that executes these hooks