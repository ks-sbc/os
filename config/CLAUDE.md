# CLAUDE.md - /config/

This directory contains the core build configuration for KSBC OS. It defines what goes into the live system, how it's configured, and how the ISO/USB image is built.

## Directory Overview

This is the heart of KSBC OS build configuration, used by live-build to create the system. Beyond Tails' privacy features, this is where DRUIDS components get integrated into the OS.

## Key Subdirectories

### System Configuration
- **`chroot_local-includes/`** - Files copied directly into the live filesystem
  - Everything here ends up in the final system at the same path
  - See also: `/config/chroot_local-includes/etc/skel/` for default user home

- **`chroot_local-hooks/`** - Scripts run during build to configure the system
  - Numbered execution order (e.g., `01-*` runs before `99-*`)
  - Run in chroot environment during build
  - See: `/config/chroot_local-hooks/CLAUDE.md` for details

- **`chroot_local-patches/`** - Patches applied to installed packages
  - Applied after package installation
  - Filename format: `packagename_description.patch`

### Package Management
- **`chroot_local-packageslists/`** - Lists of packages to install
  - `tails-common.list` - Core packages for all KSBC OS systems
  - Component-specific lists (e.g., `whisperback.list`)
  - Future: DRUIDS component lists (e.g., `druids-core.list`)

- **`APT_overlays.d/`** - Additional APT repositories
- **`APT_snapshots.d/`** - Reproducible APT snapshots
  - `debian/`, `debian-security/`, `torproject/` - Snapshot serials

### ISO/USB Configuration
- **`binary_local-hooks/`** - Scripts for ISO filesystem setup
- **`binary_local-includes/`** - Files for ISO (not live system)
  - `EFI/` - UEFI boot files
  - `isolinux/` - BIOS boot files

## Important Files

- **`base_branch`** - Current Git branch (stable/testing/devel)
- **`variables`** - Build variables and settings
  - Shell script with build configuration
  - Contains kernel cmdline, version info, etc.
- **`chroot_apt/preferences`** - APT pinning configuration

## Build Process Flow

1. live-build reads this directory
2. Installs packages from `chroot_local-packageslists/`
3. Copies files from `chroot_local-includes/`
4. Runs hooks from `chroot_local-hooks/` in order
5. Applies patches from `chroot_local-patches/`
6. Creates ISO/USB image using `binary_*` configuration

## Working Tips

- To add a file to KSBC OS: Put it in `chroot_local-includes/`
- To configure during build: Create a hook in `chroot_local-hooks/`
- To add a package: Add to appropriate `.list` file
- Always check existing hooks before creating new ones
- For DRUIDS components: Ensure distributed operation and complete documentation

## Related Directories
- `/auto/` - Build scripts that use this configuration
- `/vagrant/` - Build environment setup
- `/lib/` - Source code that may be installed via hooks

## Important Note About `variables` File

The `variables` file contains critical build settings including:
- Kernel command line options (`CMDLINE_APPEND`)
- Version information from debian/changelog
- Security hardening options
- Build reproducibility timestamps