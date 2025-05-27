# Tails Repository Migration from GitLab to GitHub

This document outlines the comprehensive plan for migrating the Tails repository from GitLab to GitHub.

## Overview

The Tails project currently uses a self-hosted GitLab instance (gitlab.tails.boum.org) for:
- Source code hosting
- Issue tracking and project management
- CI/CD pipelines
- Container registry
- Automated triage and release management

## Major Migration Areas

### 1. CI/CD Pipeline Migration (GitLab CI → GitHub Actions)

**Current GitLab CI Structure:**
- `.gitlab-ci.yml` - Main CI configuration
- `.gitlab-ci-pipeline.yml` - Regular pipeline jobs
- `.gitlab-ci-schedule.yml` - Scheduled automation jobs
- Custom Docker images from `registry.gitlab.tails.boum.org`

**GitHub Actions Equivalents:**
- `.github/workflows/*.yml` - Workflow files
- Schedule triggers using cron syntax
- GitHub Container Registry (ghcr.io) for custom images
- GitHub-hosted runners or self-hosted runners

**Key Jobs to Migrate:**
- `build-website` - Website building with ikiwiki
- `lint-po` - Translation file linting
- `ruff` - Python linting
- Scheduled jobs for automated merge requests

### 2. API Script Migration

**Scripts in `/bin/` that need GitHub equivalents:**

| GitLab Script | GitHub Equivalent |
|--------------|-------------------|
| `gitlab-api-token` | GitHub CLI authentication or GitHub App |
| `gitlab-url` | GitHub repository URL helpers |
| `gitlab-users-cleanup` | GitHub organization member management |
| `gitlab-triage-post-release` | GitHub Actions + GitHub CLI |
| `ensure-merge-request` | GitHub CLI: `gh pr create` |
| `generate-changelog` | GitHub CLI: `gh release` + custom logic |
| `generate-report` | GitHub CLI: `gh issue list`, `gh pr list` |

### 3. Issue/PR Reference Format Changes

**Current GitLab format:**
- Issues: `#1234`
- Merge Requests: `!1234`
- Branch naming: `XXXX-description` (issue number prefix)

**GitHub format:**
- Issues: `#1234` (same)
- Pull Requests: `#1234` (same as issues)
- Branch naming: Can keep same convention

### 4. GitLab Triage System Migration

**Current Setup:**
- `/config/gitlab-triage/` - Docker-based triage automation
- Policy files for automated issue/MR management

**GitHub Equivalent:**
- GitHub Actions with scheduled workflows
- GitHub Projects for project management
- Labels and milestones automation
- Probot apps or custom GitHub Apps

### 5. Container Registry Migration

**Current:**
- `registry.gitlab.tails.boum.org`

**GitHub:**
- `ghcr.io/[organization]/[image-name]`
- Requires updating all Dockerfiles and CI references

### 6. Documentation Updates

**Files to update:**
- `/wiki/src/contribute/working_together/GitLab/*` → GitHub equivalents
- All references to `gitlab.tails.boum.org`
- Development workflow documentation
- Contributor guides

## Migration Steps

### Phase 1: Repository Migration
1. Create GitHub organization (if not exists)
2. Import repository with full history
3. Set up branch protection rules
4. Configure repository settings

### Phase 2: CI/CD Migration
1. Convert GitLab CI YAML to GitHub Actions workflows
2. Set up GitHub Container Registry
3. Build and push custom Docker images
4. Test all CI jobs

### Phase 3: Automation Scripts
1. Rewrite GitLab API scripts using GitHub CLI
2. Update all automation workflows
3. Test release and triage processes

### Phase 4: Issue/PR Migration
1. Export GitLab issues/MRs
2. Import to GitHub (preserving numbers if possible)
3. Update all cross-references

### Phase 5: Documentation
1. Update all documentation
2. Update contributor guides
3. Update URLs and references

### Phase 6: Cutover
1. Freeze GitLab instance
2. Final sync
3. Update DNS/redirects
4. Announce migration

## Technical Considerations

### Authentication
- GitLab personal access tokens → GitHub personal access tokens
- GitLab project tokens → GitHub Apps or OAuth Apps
- SSH keys migration

### Webhooks
- Update all external integrations
- Update notification systems

### Security
- Set up GitHub security features
- Configure Dependabot
- Set up code scanning

### Preservation
- Archive GitLab instance for historical reference
- Set up redirects from old URLs

## Risk Mitigation

1. **Data Loss**: Full backups before migration
2. **Broken Links**: Comprehensive URL mapping and redirects
3. **CI/CD Failures**: Parallel run period
4. **Contributor Confusion**: Clear communication plan

## Timeline Estimate

- Phase 1: 1 week
- Phase 2: 2-3 weeks
- Phase 3: 2 weeks
- Phase 4: 1-2 weeks
- Phase 5: 1 week
- Phase 6: 1 week

**Total: 8-11 weeks**

## Next Steps

1. Review and approve migration plan
2. Set up GitHub organization
3. Begin Phase 1 preparations
4. Create detailed task breakdown for each phase