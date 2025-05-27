# CLAUDE.md - Legacy Wiki Assets

This directory contains graphical assets from the IkiWiki-based documentation system.

## Status

**⚠️ DEPRECATED**: These assets are part of the legacy IkiWiki system.

## Migration to GitHub Wiki

For KSBC OS GitHub Wiki, assets should be:

1. **Uploaded to Wiki repository** - GitHub Wiki has its own Git repo
2. **Stored in `assets/` directory** - Organized by type
3. **Referenced with relative paths** - `![alt text](assets/image.png)`

### New Asset Structure
```
wiki.git/                 # GitHub Wiki repository
├── assets/
│   ├── images/          # Screenshots, diagrams
│   ├── icons/           # UI icons
│   └── logos/           # KSBC OS branding
├── Home.md
└── [other pages].md
```

## Legacy Assets

Current SVG files that may need migration:
- `Gnome-computer.svg` - System representation
- `Gnome-network-server.svg` - Network services
- `man-in-the-middle.svg` - Security threats
- `onion.svg` - Tor network
- `Weather-storm.svg` - Warnings

## DO NOT UPDATE

Do not add new assets here. Use GitHub Wiki's asset management instead.