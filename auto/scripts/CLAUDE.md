# CLAUDE.md - /auto/scripts/

This directory contains utility scripts used during the KSBC OS build process.

## Directory Overview

These scripts support the main build commands (`/auto/build`, `/auto/config`) with various utilities for package management, build manifest generation, and development tools. Future DRUIDS-specific build utilities will also be added here.

## Key Scripts

### APT/Package Management
- **`apt-mirror`** - Manages local APT mirror for builds
- **`apt-snapshots-serials`** - Manages reproducible APT snapshot serials
- **`apt-snapshots-serials-cat-json`** - JSON processing for snapshots
- **`apt-snapshots-serials-load-json`** - Load snapshot configurations
- **`tails-custom-apt-sources`** - Configure custom APT sources
- **`update-acng-config`** - Update Apt-Cacher NG configuration

### Build Tools
- **`create-usb-image-from-iso`** - Convert ISO to USB image format
- **`generate-build-manifest`** - Create manifest of installed packages
- **`generate-languages-list`** - Generate list of supported languages

### Development Utilities
- **`ikiwiki-supported-languages`** - List languages for website build
- **`website-cache`** - Manage website build cache
- **`utils.sh`** - Shared utility functions (sourced by other scripts)

## Usage Context

These scripts are typically called by:
- The main build system (`/auto/build`)
- Rake tasks (`/Rakefile`)
- Vagrant provisioning scripts
- CI/CD pipelines

## Important Notes

- Most scripts expect to run in the build environment (Vagrant VM)
- Scripts may require specific environment variables set by the build system
- `utils.sh` contains common functions - source it in new scripts

## Working Tips

- Always check `utils.sh` before implementing common functionality
- Scripts should be POSIX shell compatible when possible
- Use consistent error handling and logging patterns
- Document any required environment variables
- For DRUIDS utilities: Consider distributed build scenarios and reproducibility

## Related Directories
- `/auto/build` - Main build script that uses these utilities
- `/config/APT_snapshots.d/` - Snapshot data managed by these scripts
- `/vagrant/` - Build environment where these run
- `/config/` - Configuration that these scripts help process