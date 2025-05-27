# Implementation Plan: KSBC Tails+Obsidian USB Drive Feature

## Overview

This plan outlines the implementation of a feature to create pre-configured Tails USB drives with Obsidian AppImage and hardware security key support for the Kansas Socialist Book Club (KSBC). The feature will enable secure, anonymous document collaboration while maintaining a "clone once, deploy many" distribution model.

## Goals

1. **Integrate Obsidian AppImage** into Tails as an optional persistent application
2. **Support hardware security keys** (specifically Feitian K9D) for SSH authentication
3. **Create deployment scripts** for easy cloning and distribution
4. **Provide user-friendly setup wizards** for first-time configuration
5. **Ensure persistence** of Obsidian vault, plugins, and security configurations

## Architecture Overview

The implementation will leverage Tails' existing infrastructure:

- **Additional Software** framework for installing Obsidian
- **Persistent Storage** features for storing the Obsidian vault and configuration
- **Hardware key support** through existing smartcard/FIDO2 infrastructure
- **First-boot scripts** using the live-config framework

## Implementation Components

### 1. Obsidian AppImage Integration

#### 1.1 Create Obsidian Persistence Feature
- **Location**: `/config/chroot_local-includes/usr/lib/python3/dist-packages/tps/configuration/features.py`
- **Task**: Add new `ObsidianVault` feature class
- **Components**:
  ```python
  class ObsidianVault(Feature):
      Id = "ObsidianVault"
      translatable_name = "Obsidian Vault"
      Bindings = (
          Binding("obsidian", "/home/amnesia/Persistent/Obsidian"),
          Binding("obsidian-config", "/home/amnesia/.config/obsidian"),
      )
      enabled_by_default = False
  ```

#### 1.2 AppImage Download and Installation Script
- **Location**: `/config/chroot_local-includes/usr/local/lib/tails-install-obsidian`
- **Task**: Create script to download and install Obsidian AppImage
- **Features**:
  - Download via Tor
  - Verify checksums
  - Install to persistent storage
  - Create desktop entry

#### 1.3 Obsidian Plugins Pre-configuration
- **Location**: `/config/chroot_local-includes/usr/share/tails/obsidian-plugins/`
- **Task**: Bundle the 17 required plugins
- **Plugins**: Advanced slides, Advanced tables, CSS editor, Dataloom, Dataview, Git, GPG encrypt, Kanban, Linter, Metaedit, Projects, Shell commands, Tag wrangler, Tagfolder, Tasks

### 2. Hardware Security Key Support

#### 2.1 Enhanced Hardware Key Packages
- **Location**: `/config/chroot_local-packageslists/tails-hardware-keys.list`
- **Task**: Create new package list for hardware key support
- **Packages**:
  ```
  libfido2-1
  opensc
  pcscd
  scdaemon
  yubikey-manager
  pcsc-tools
  ```

#### 2.2 Hardware Key Setup Scripts
- **Location**: `/config/chroot_local-includes/usr/local/bin/tails-hardware-key-setup`
- **Task**: Create user-friendly scripts for:
  - SSH key generation with hardware keys
  - GPG key creation
  - Key backup procedures

### 3. KSBC Feature Bundle

#### 3.1 KSBC Deployment Configuration
- **Location**: `/config/chroot_local-includes/usr/share/tails/ksbc/`
- **Task**: Create KSBC-specific configuration and scripts
- **Components**:
  - Welcome wizard
  - Setup scripts
  - Documentation
  - Default Obsidian vault template

#### 3.2 First-Boot Configuration Hook
- **Location**: `/config/chroot_local-includes/lib/live/config/9100-ksbc-setup`
- **Task**: Create live-config hook for first-boot setup
- **Features**:
  - Check for KSBC marker file
  - Launch welcome wizard
  - Guide through security key setup

### 4. Build System Integration

#### 4.1 Build Profile for KSBC
- **Location**: `/config/build-profiles/ksbc`
- **Task**: Create build profile that enables KSBC features
- **Configuration**:
  - Enable ObsidianVault persistence feature
  - Include hardware key packages
  - Include KSBC deployment scripts

#### 4.2 Build Script Enhancement
- **Location**: `/auto/scripts/build-ksbc-image`
- **Task**: Create specialized build script
- **Features**:
  - Build Tails with KSBC profile
  - Pre-configure persistent storage
  - Generate deployment documentation

### 5. User Interface Components

#### 5.1 Tails Greeter Integration
- **Location**: `/config/chroot_local-includes/usr/lib/python3/dist-packages/tailsgreeter/settings/ksbc.py`
- **Task**: Add KSBC mode to Tails Greeter
- **Features**:
  - Detect KSBC USB drives
  - Show specialized welcome message
  - Guide to persistent storage unlock

#### 5.2 GNOME Shell Extension
- **Location**: `/config/chroot_local-includes/usr/share/gnome-shell/extensions/ksbc@tails.boum.org/`
- **Task**: Create extension for KSBC status and shortcuts
- **Features**:
  - Obsidian quick launch
  - Hardware key status indicator
  - Setup wizard launcher

### 6. Documentation and Help

#### 6.1 User Documentation
- **Location**: `/wiki/src/doc/ksbc/`
- **Task**: Create comprehensive user documentation
- **Topics**:
  - Getting started guide
  - Security best practices
  - Troubleshooting
  - Emergency procedures

#### 6.2 In-System Help
- **Location**: `/config/chroot_local-includes/usr/share/help/C/tails/ksbc.page`
- **Task**: Create Yelp help pages
- **Content**:
  - Quick reference
  - Common tasks
  - Security reminders

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
1. Create ObsidianVault persistence feature
2. Implement AppImage download/install script
3. Add hardware key packages
4. Basic testing

### Phase 2: User Experience (Week 3-4)
1. Create welcome wizard
2. Implement hardware key setup scripts
3. Add Greeter integration
4. Create GNOME extension

### Phase 3: Build System (Week 5)
1. Create KSBC build profile
2. Implement build scripts
3. Test full build process
4. Create deployment tools

### Phase 4: Documentation & Testing (Week 6)
1. Write user documentation
2. Create help pages
3. Comprehensive testing
4. Security audit

### Phase 5: Deployment Preparation (Week 7)
1. Create cloning procedures
2. Test multi-USB deployment
3. Prepare distribution packages
4. Training materials

## Security Considerations

1. **AppImage Verification**: Implement checksum verification for Obsidian downloads
2. **Plugin Security**: Audit all bundled Obsidian plugins
3. **Key Management**: Secure storage of GPG/SSH keys in persistent storage
4. **Hardware Key PIN**: Enforce strong PIN policies
5. **Network Isolation**: Ensure Obsidian operates within Tor network constraints

## Testing Strategy

1. **Unit Tests**: For individual scripts and Python modules
2. **Integration Tests**: Using Tails test suite framework
3. **Security Tests**: Verify no data leaks, proper Tor routing
4. **User Acceptance Tests**: With KSBC members

## Maintenance Plan

1. **Obsidian Updates**: Monthly check for new versions
2. **Plugin Updates**: Quarterly plugin security review
3. **Security Patches**: Follow Tails security update cycle
4. **User Support**: Establish support channel for KSBC users

## Success Criteria

1. Obsidian launches successfully with all plugins
2. Hardware keys work for SSH/GPG operations
3. Cloning process takes < 30 minutes per USB
4. First-time setup completed in < 15 minutes
5. All security requirements maintained

## Next Steps

1. Create feature branch: `ksbc-obsidian-integration`
2. Implement Phase 1 components
3. Set up CI/CD for KSBC builds
4. Begin security audit process
5. Coordinate with KSBC for testing

This plan provides a comprehensive roadmap for integrating Obsidian and hardware security key support into Tails while maintaining security and usability standards.