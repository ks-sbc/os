# GitLab to GitHub Script Migration Mapping

This document provides detailed mapping of GitLab-specific scripts to their GitHub equivalents.

## API and Authentication Scripts

### gitlab-api-token → GitHub Authentication
**GitLab version:**
```bash
gitlab-api-token
```

**GitHub equivalent:**
```bash
# Using GitHub CLI (gh)
gh auth token

# Or using environment variable
echo $GITHUB_TOKEN

# For GitHub App authentication
gh api /app -H "Authorization: Bearer $GITHUB_APP_TOKEN"
```

### gitlab-url → GitHub URL Helper
**GitLab version:**
```bash
gitlab-url
```

**GitHub equivalent:**
```bash
# Get current repository URL
gh repo view --json url -q .url

# Or construct manually
echo "https://github.com/$GITHUB_REPOSITORY"
```

## User and Organization Management

### gitlab-users-cleanup → GitHub Organization Member Management
**GitLab version:**
```bash
gitlab-users-cleanup
```

**GitHub equivalent:**
```bash
# List organization members
gh api orgs/tails/members --paginate

# Remove member
gh api -X DELETE orgs/tails/members/USERNAME

# Check member status
gh api orgs/tails/members/USERNAME
```

## Release and Triage Management

### gitlab-triage-post-release → GitHub Actions + CLI
**GitLab version:**
```bash
gitlab-triage-post-release
```

**GitHub equivalent:**
```bash
# Using GitHub CLI for issue/PR management
gh issue list --label "needs-triage"
gh pr list --label "post-release"

# Bulk operations with jq
gh issue list --json number,title,labels | jq '.[] | select(.labels[].name == "post-release")'
```

## Merge/Pull Request Management

### ensure-merge-request → GitHub Pull Request Creation
**GitLab version:**
```bash
ensure-merge-request
```

**GitHub equivalent:**
```bash
# Create pull request
gh pr create \
  --title "Title" \
  --body "Description" \
  --base main \
  --head feature-branch

# Check if PR exists
gh pr list --head feature-branch --base main

# Create or update PR
gh pr create || gh pr edit
```

## Changelog and Reporting

### generate-changelog → GitHub Release Notes
**GitLab version:**
```bash
generate-changelog
```

**GitHub equivalent:**
```bash
# Generate release notes
gh release create v1.0.0 --generate-notes

# Custom changelog from merged PRs
gh pr list \
  --state merged \
  --base main \
  --search "merged:>=2024-01-01" \
  --json number,title,author,mergedAt \
  | jq -r '.[] | "- \(.title) (#\(.number)) by @\(.author.login)"'
```

### generate-report → GitHub CLI Reporting
**GitLab version:**
```bash
generate-report
```

**GitHub equivalent:**
```bash
# Issues report
gh issue list \
  --json number,title,state,labels,assignees,createdAt,closedAt \
  | jq -r 'map(select(.labels[].name == "report")) | .[] | [.number, .title, .state] | @csv'

# PR metrics
gh pr list \
  --state all \
  --limit 1000 \
  --json number,title,state,createdAt,mergedAt,closedAt \
  | jq '
    group_by(.state) | 
    map({state: .[0].state, count: length})
  '
```

## Issue Analysis

### closed-issues-linked-from-website → GitHub Search API
**GitLab version:**
```bash
closed-issues-linked-from-website
```

**GitHub equivalent:**
```bash
# Find closed issues referenced in files
for issue in $(grep -h "#[0-9]\+" wiki/src/*.mdwn | grep -o "#[0-9]\+" | sort -u); do
  number=${issue#\#}
  state=$(gh issue view $number --json state -q .state 2>/dev/null || echo "not found")
  if [ "$state" = "CLOSED" ]; then
    echo "Issue $issue is closed but still referenced"
  fi
done
```

### ux-debt-changes → GitHub Project Tracking
**GitLab version:**
```bash
ux-debt-changes
```

**GitHub equivalent:**
```bash
# Track UX debt via labels and projects
gh issue list --label "ux-debt" --json number,title,labels

# Add to project
gh issue edit ISSUE_NUMBER --add-project "UX Debt"

# Generate UX debt report
gh api graphql -f query='
  query($org: String!, $number: Int!) {
    organization(login: $org) {
      projectV2(number: $number) {
        items(first: 100) {
          nodes {
            content {
              ... on Issue {
                number
                title
                labels(first: 10) {
                  nodes { name }
                }
              }
            }
          }
        }
      }
    }
  }
' -f org=tails -f number=PROJECT_NUMBER
```

## Environment Variables Mapping

| GitLab Variable | GitHub Variable |
|----------------|-----------------|
| `CI_PROJECT_URL` | `${{ github.server_url }}/${{ github.repository }}` |
| `CI_PROJECT_NAME` | `${{ github.event.repository.name }}` |
| `CI_COMMIT_REF_NAME` | `${{ github.ref_name }}` |
| `CI_COMMIT_SHA` | `${{ github.sha }}` |
| `CI_MERGE_REQUEST_IID` | `${{ github.event.pull_request.number }}` |
| `CI_PIPELINE_SOURCE` | `${{ github.event_name }}` |
| `GITLAB_USER_LOGIN` | `${{ github.actor }}` |

## General Migration Patterns

### API Calls
```bash
# GitLab
curl -H "PRIVATE-TOKEN: $TOKEN" https://gitlab.tails.boum.org/api/v4/...

# GitHub
gh api ...
# or
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/...
```

### Webhooks
- GitLab: Project Settings → Webhooks
- GitHub: Repository Settings → Webhooks

### CI Variables
- GitLab: Project Settings → CI/CD → Variables
- GitHub: Repository Settings → Secrets and variables → Actions

## Notes

1. GitHub CLI (`gh`) is the recommended tool for most operations
2. For complex queries, combine `gh` with `jq` for JSON processing
3. GitHub Actions can replicate most GitLab CI functionality
4. GitHub Apps provide more granular permissions than personal access tokens
5. Consider using GitHub's GraphQL API for complex queries