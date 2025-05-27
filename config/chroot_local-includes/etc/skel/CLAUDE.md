# CLAUDE.md - /config/chroot_local-includes/etc/skel/

This directory defines the default home directory template for new users in KSBC OS.

## Directory Overview

The `/etc/skel/` directory is a standard Linux convention. When a new user is created, the contents of this directory are copied to their home directory. In KSBC OS, this affects the `amnesia` user's initial home directory state and will be important for DRUIDS organizational templates.

## Current State

This directory is intentionally kept minimal in KSBC OS for several reasons:
- Privacy: No default files that could contain identifying information
- Security: Minimal attack surface
- Amnesia: Fits with the amnesic design philosophy
- DRUIDS: Organizational templates will be managed separately for security

## How It Works

1. During boot, when the `amnesia` user is created
2. Contents of `/etc/skel/` are copied to `/home/amnesia/`
3. Ownership is set to the new user
4. Additional configuration happens via other mechanisms

## KSBC OS User Configuration

Instead of `/etc/skel/`, KSBC OS configures the user environment through:

- **dconf/gsettings** - GNOME desktop settings
  - See: `/config/chroot_local-includes/etc/dconf/`
- **Desktop files** - Application shortcuts
  - See: `/config/chroot_local-includes/usr/share/applications/`
- **XDG autostart** - Session startup items
  - See: `/config/chroot_local-includes/etc/xdg/autostart/`
- **Live-config hooks** - Runtime configuration
  - See: `/config/chroot_local-includes/lib/live/config/`

## Adding Default User Files

If you need to add default files for users:

1. **Consider alternatives first**:
   - Can it be a system-wide config in `/etc/`?
   - Can it be set via dconf/gsettings?
   - Can it be created on-demand by an application?

2. **If you must use skel**:
   - Keep files minimal
   - Avoid any identifying information
   - Document why it's necessary
   - Consider privacy implications

## Example Use Cases

Typical files that might go in `/etc/skel/` (but don't in KSBC OS):
- `.bashrc`, `.profile` - KSBC OS uses system-wide `/etc/bash.bashrc`
- `.config/` directories - Created on-demand by applications
- Desktop wallpapers - System-wide in `/usr/share/tails/`
- Bookmarks - Added dynamically by hooks

## Future DRUIDS Considerations

When DRUIDS is implemented, we may need to:
- Create initial Git repository templates
- Set up Obsidian vault structures
- Configure organizational workflow templates
- These will likely be managed through persistent storage rather than skel

## Related Directories
- `/home/amnesia/` - The actual user home (not in git)
- `/config/chroot_local-includes/etc/dconf/` - Desktop settings
- `/config/chroot_local-hooks/70-xdg-user-dirs` - Creates user directories
- `/lib/live/config/` - Runtime user configuration