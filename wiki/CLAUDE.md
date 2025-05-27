# CLAUDE.md - KSBC OS Wiki Migration Guide

This directory contains the legacy IkiWiki structure from Tails. KSBC OS is migrating to GitHub Wiki for better integration with our DRUIDS principles.

## Migration Status

**⚠️ DEPRECATED**: This IkiWiki structure is being replaced by GitHub Wiki.

## New Documentation Structure

KSBC OS documentation now lives in:
1. **GitHub Wiki** - User documentation and guides
2. **Repository docs** - Technical documentation
3. **DRUIDS vaults** - Organizational knowledge

### GitHub Wiki Structure
```
Home.md                    # Wiki homepage
_Sidebar.md               # Navigation sidebar
_Footer.md                # Common footer
Installation/             # Installation guides
  - USB-Installation.md
  - Verification.md
User-Guide/              # User documentation
  - Getting-Started.md
  - Security-Practices.md
DRUIDS/                  # DRUIDS documentation
  - Overview.md
  - Quick-Start.md
  - Architecture.md
```

### Why GitHub Wiki?

1. **Git-based** - Aligns with DRUIDS version control principles
2. **Distributed** - Can be cloned and backed up
3. **Markdown** - Simple, portable format
4. **No build step** - Reduces complexity
5. **Issue integration** - Links to development work

## Legacy IkiWiki Content

This directory structure remains for reference during migration:
- `/wiki/src/` - Original IkiWiki source files
- `/wiki/lib/` - Assets that need migration
- Translation files (`.po`) - Need new i18n strategy

## Migration Plan

See `/IKIWIKI_TO_GITHUB_WIKI_MIGRATION_PLAN.md` for detailed migration steps.

## DO NOT MODIFY

Do not update IkiWiki content. All documentation updates should go to:
1. GitHub Wiki for user docs
2. Repository `/docs/` for technical docs
3. DRUIDS vaults for organizational knowledge