# CLAUDE.md - Legacy Wiki Source

This directory contains the IkiWiki source files for the legacy Tails documentation.

## Status

**⚠️ DEPRECATED**: IkiWiki is being replaced by GitHub Wiki for KSBC OS.

## What's Here

This directory contains:
- `.mdwn` files - IkiWiki markdown dialect
- `.html` files - HTML with IkiWiki directives  
- `.po` files - Translations (gettext format)
- Various assets and includes

## Migration Status

See `/IKIWIKI_TO_GITHUB_WIKI_MIGRATION_PLAN.md` for migration progress.

Key content to migrate:
1. Installation guides → GitHub Wiki Installation section
2. User documentation → GitHub Wiki User Guide
3. Security warnings → GitHub Wiki Security section
4. Developer docs → Repository `/docs/`

## DO NOT EDIT

Do not update content in this directory. All new documentation should be created in:
- GitHub Wiki for user-facing docs
- Repository `/docs/` for developer docs
- DRUIDS vaults for organizational knowledge

## Translation Strategy

The `.po` translation files need a new strategy for GitHub Wiki. Options:
1. Separate wiki repos per language
2. Language subdirectories in main wiki
3. External translation platform integration

This is still being determined.