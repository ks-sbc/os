# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KSBC OS** (KSBC Operating System) is a revolutionary operating system built on Tails that embeds organizational memory and democratic centralist principles into its technological infrastructure. It extends Tails' privacy and security foundation with the DRUIDS (Documentation for Revolutionary Unity, Ideological Development, and Security) architecture.

Building on Tails' core features:
- Debian-based live system running from USB
- All connections routed through Tor
- No traces left on host computer

KSBC OS adds:
- Living documentation systems for organizational continuity
- Embedded democratic centralist workflows
- Distributed resilience against state repression
- Git-based ideological evolution framework

## Repository Structure

### Core Build System
- **`/config/`** - Main build configuration directory
  - `chroot_local-includes/` - Files copied into the live system (see also: `/lib/`, `/wiki/src/`)
  - `chroot_local-hooks/` - Build-time configuration scripts
  - `chroot_local-patches/` - Patches for installed packages
  - `chroot_local-packageslists/` - Package lists (`.list` files)
  - `APT_overlays.d/`, `APT_snapshots.d/` - APT repository configs
  - `binary_*` - ISO/USB image configuration

### Testing Infrastructure
- **`/features/`** - Automated test suite (see also: `/run_test_suite`)
  - `.feature` files - Cucumber/Gherkin scenarios
  - `step_definitions/` - Ruby test implementations
  - `support/` - Test helpers and utilities
  - `images/` - Screenshots for visual testing with OpenCV

### Website & Documentation
- **`/wiki/`** - Website source (see also: `/po/` for translations)
  - `src/` - Content in Markdown with `.po` translation files
  - Built with IkiWiki (config: `/ikiwiki.setup`)

### Libraries & Code
- **`/lib/`** - Shared libraries
  - `perl5/` - Perl modules (IkiWiki plugins)
  - `python3/tailslib/` - Python libraries
  - `ruby/` - Ruby libraries

### Internationalization
- **`/po/`** - Software translations (50+ languages)
  - Related to website translations in `/wiki/src/`

### Build Tools
- **`/auto/`** - Core build scripts
  - `build`, `config`, `clean` - Main build commands
  - `scripts/` - Build utilities
- **`/vagrant/`** - Build VM configuration (see also: `/Vagrantfile`)
  - Ensures reproducible builds in isolated environment

### Development Files
- **`/Rakefile`** - Build orchestration (run with `rake`)
- **`/run_test_suite`** - Test runner script
- **`/submodules/`** - Git submodules for dependencies

## Build & Test Commands

- Full test suite: `./run_test_suite`
- Single feature test: `./run_test_suite -- features/[feature_name].feature`
- Single scenario: `./run_test_suite -- features/[feature_name].feature:LINE_NUMBER`
- Build: `rake build`
- Lint Ruby: `rubocop`
- Lint Python: `ruff check`
- Type check Python: `mypy`

## Code Style Guidelines

### Ruby
- Line length: 88 characters max
- Indentation: 2 spaces
- Style: Follow RuboCop rules in `.rubocop.yml`
- Hash style: table alignment
- Ruby version: 3.1+
- Class length max: 250 lines
- Method length max: 45 lines

### Python
- Line length: 88 characters max
- Use type hints
- Follow Ruff rules in `pyproject.toml`
- Target Python version: 3.11
- Use relative imports for project modules

### Git Workflow
- Base branches: stable, testing, devel, feature/DEBIAN_NEXT
- Feature branches: XXXX-* (where XXXX is GitLab issue number)
- Non-Debian packages should only be temporary during development

## Key Applications & Tools

### KSBC OS Applications (inherited from Tails)
- **tails-installer** - USB installation tool
- **tails-upgrader** - System upgrade tool (see: `/config/chroot_local-hooks/`)
- **whisperback** - Bug reporting tool
- **persistent-storage** - Encrypted persistence management (critical for DRUIDS)
- **tor-connection-assistant** - Tor configuration helper
- **onion-grater** - Tor control port filter

### DRUIDS-specific Components (planned)
- **druids-sync** - Distributed repository synchronization
- **druids-vault** - Organizational memory management
- **druids-workflow** - Democratic centralist decision tracking
- **druids-history** - Git-based organizational archaeology

### Important Configuration Files
- `/config/base_branch` - Current development branch
- `/config/variables` - Build variables
- `/config/chroot_apt/preferences` - APT pinning
- `/debian/` - Debian packaging files

## Working in Different Areas

### When working on build configuration:
- Start in `/config/`
- Check `/auto/scripts/` for build utilities
- Review `/config/chroot_local-hooks/` for system setup

### When working on tests:
- Start in `/features/`
- Look for existing similar tests
- Check `/features/support/` for test helpers

### When working on the website:
- Start in `/wiki/src/`
- Check `/po/` for translation updates
- Use `/ikiwiki.setup` for build config

### When working on KSBC OS applications:
- Check `/config/chroot_local-includes/usr/` for installed files
- Look in `/lib/python3/tailslib/` for shared Python code (will contain DRUIDS libraries)
- Review `/config/chroot_local-hooks/` for installation scripts
- Ensure all features support distributed operation
- Document organizational impact of technical decisions

## DRUIDS Development Principles

When developing for KSBC OS, remember:
1. **Form Governs Function** - Technology shapes consciousness; design features that naturally guide users toward collective action
2. **No Single Point of Failure** - Every component must work without central servers or authorities
3. **Complete History** - All decisions and changes must be traceable to their origins
4. **Embedded Discipline** - Make correct organizational practices easier than incorrect ones
5. **Revolutionary Reproducibility** - Successful patterns must be easily replicable across organizations

See [DRUIDS.md](./DRUIDS.md) for complete architectural philosophy.