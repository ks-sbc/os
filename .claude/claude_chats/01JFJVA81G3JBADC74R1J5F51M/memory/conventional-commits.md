# Conventional Commits Format for KSBC OS

## Standard Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Detailed Format Rules

1. **Structure**: `<type>(<scope>): <description>`
   - Type is REQUIRED
   - Scope is OPTIONAL, in parentheses
   - `: ` (colon space) REQUIRED after type/scope
   - Description is REQUIRED

2. **Breaking Changes**: Two ways to indicate:
   - Add `!` before the `:` → `feat(core)!: description`
   - Add `BREAKING CHANGE:` in footer

3. **Body**: 
   - OPTIONAL
   - MUST start one blank line after description
   - Free-form, multiple paragraphs allowed

4. **Footer**:
   - OPTIONAL
   - One blank line after body
   - Format: `token: value` or `token #value`
   - Use `-` instead of spaces in tokens (except BREAKING CHANGE)

## Types
- **feat**: New feature (DRUIDS components, OS capabilities)
- **fix**: Bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code change that neither fixes bug nor adds feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: CI/CD configuration changes
- **chore**: Other changes (updating gitignore, etc.)
- **revert**: Reverts a previous commit

## Scope Examples
- **druids**: DRUIDS-specific changes
- **security**: Security-related changes
- **core**: Core system changes
- **wiki**: Wiki/documentation system
- **hooks**: Build hooks modifications
- **config**: Configuration changes
- **apt**: Package management
- **tor**: Tor-related functionality

## Description Rules
- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end
- Keep under 50 characters (72 max)
- Be specific and meaningful

## Examples

### Feature
```
feat(druids): add distributed repository sync module

Implements the druids-sync component for organizational memory
distribution across nodes. Includes conflict resolution and
cryptographic verification.

Refs: #123
```

### Fix
```
fix(security): prevent AppArmor profile bypass in persistent storage

Closes: #456
```

### Docs
```
docs(wiki): migrate installation guide to GitHub Wiki format

Part of the IkiWiki to GitHub Wiki migration effort
```

### Breaking Change (with !)
```
feat(druids)!: redesign vault structure for better security

Existing vaults will need migration. The new structure provides
better encryption and distributed resilience.

Migration-Tool: tools/migrate-vault.sh
```

### Breaking Change (with footer)
```
feat(core): rebrand to KSBC OS with DRUIDS architecture

Transform Tails codebase into KSBC OS, implementing DRUIDS
architecture for revolutionary organizational infrastructure.

BREAKING CHANGE: Complete rebrand from Tails to KSBC OS. All 
references updated. This is now a new OS built on Tails' foundation.
```

### Multiple Footers
```
fix(security): patch critical vulnerability in key generation

Emergency fix for CVE-2024-XXXX affecting hardware key generation
when using specific Feitian models.

Fixes: #789
CVE: CVE-2024-XXXX
Reviewed-by: security-team
```

## Footer Tokens

Common footer tokens (use `-` for spaces except BREAKING CHANGE):
- `Fixes:` or `Closes:` - Issue references
- `Refs:` or `Ref:` - Related issues/commits
- `BREAKING CHANGE:` - Breaking changes (uppercase)
- `Reviewed-by:` - Code reviewer
- `Co-authored-by:` - Co-authors
- `Signed-off-by:` - DCO signoff
- `Acked-by:` - Acknowledgments
- `Tested-by:` - Testers
- `Migration-Tool:` - KSBC OS specific for migrations
- `CVE:` - Security vulnerabilities
- `See-also:` - Related resources

## Special Considerations for KSBC OS

1. **Security commits**: Always explain security implications
2. **DRUIDS commits**: Reference which principle (form governs function, etc.)
3. **Migration commits**: Clearly mark what's being migrated from Tails
4. **Revolutionary context**: When relevant, explain how change supports organizational continuity
5. **Breaking changes**: The rebrand from Tails → KSBC OS is breaking!

## Git Aliases for KSBC OS

Add to your `.gitconfig`:
```bash
[alias]
    # Quick conventional commits
    cfeat = "!f() { git commit -m \"feat($1): $2\"; }; f"
    cfix = "!f() { git commit -m \"fix($1): $2\"; }; f"
    cdocs = "!f() { git commit -m \"docs($1): $2\"; }; f"
    cbreak = "!f() { git commit -m \"feat($1)!: $2\"; }; f"
    
    # DRUIDS-specific
    druids = "!f() { git commit -m \"feat(druids): $1\"; }; f"
    dsec = "!f() { git commit -m \"fix(security): $1\"; }; f"
```

## Commit Message Template

Save as `.gitmessage`:
```
# <type>(<scope>): <description>
#
# [optional body]
#
# [optional footer(s)]
#
# === Format Rules ===
# - Type: feat, fix, docs, style, refactor, perf, test, build, ci, chore
# - Scope: druids, security, core, config, wiki, hooks, apt, tor
# - Description: imperative, lowercase, no period, <50 chars
# - Body: Start after blank line, wrap at 72 chars
# - Footer: token: value (use - for spaces except BREAKING CHANGE)
# - Breaking: Add ! before : OR use BREAKING CHANGE: in footer
#
# === Examples ===
# feat(druids): add vault encryption module
# fix(security)!: patch key generation vulnerability
# docs(wiki): update installation guide
```

Configure: `git config commit.template .gitmessage`

## Validation

Many tools can validate Conventional Commits:
- `commitlint` - Node.js based linter
- `gitlint` - Python based linter
- `cocogitto` - Rust based tool with auto-changelog
- Git hooks - Pre-commit validation