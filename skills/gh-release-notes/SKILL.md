---
name: gh-release-notes
description: Use when the user asks to generate release notes, a changelog, or a summary of changes between versions. Trigger phrases include "release notes", "what changed since v1.2", "changes between tags", "generate changelog", "what's in this release", "summarize changes from TAG to TAG", "what PRs are in v2.0". Also activate when the user mentions "cutting a release" and asks what's included.
---

# GitHub Release Notes Generator

Generate structured release notes from merged PRs between two refs or tags. Follow these steps in order.

## Prerequisites

```bash
git rev-parse --git-dir
```
If that fails, tell the user: "You need to be inside a git repository to use gh-release-notes." Stop.

```bash
git remote -v | grep -i github
```
If no GitHub remote, tell the user: "This repo doesn't appear to have a GitHub remote." Stop.

```bash
gh auth status
```
If not authenticated, tell the user: "gh is not authenticated. Run `gh auth login`." Stop.

## Step 1 — Determine the Range

You need a `FROM` ref and a `TO` ref (tags, branch names, or commit SHAs).

If the user provided both, use them directly.

If the user provided only one (e.g., "since v1.2"), use it as `FROM` and `HEAD` (or the default branch) as `TO`.

If the user provided neither, find the two most recent tags:
```bash
git tag --sort=-version:refname | head -5
```
Use the most recent tag as `TO` and the second most recent as `FROM`. Confirm with the user before proceeding if neither tag was mentioned.

Get the repo name:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## Step 2 — Find Merged PRs in Range

Get the commit SHAs between the two refs:
```bash
git log --oneline FROM..TO --merges --format="%H %s"
```

Extract PR numbers from merge commit subjects (pattern: `Merge pull request #NNN` or `(#NNN)` at end of subject).

For each PR number found:
```bash
gh pr view NNN --json number,title,body,labels,author,mergedAt,milestone
```

Also use the GitHub compare API to catch any PRs that may have been squash-merged:
```bash
gh api repos/OWNER/REPO/compare/FROM...TO --jq '.commits[].commit.message' 2>/dev/null
```

Deduplicate by PR number. Limit to 100 PRs.

## Step 3 — Categorize PRs

Group each PR into one of these categories based on labels and title keywords:

| Category | Labels or title signals |
|---|---|
| Breaking Changes | `breaking`, `breaking-change`, title starts with `BREAKING:` |
| New Features | `feature`, `feat`, `enhancement`, title starts with `feat:` or `add ` |
| Bug Fixes | `bug`, `fix`, `bugfix`, title starts with `fix:` or `bug:` |
| Performance | `performance`, `perf`, title starts with `perf:` |
| Documentation | `docs`, `documentation`, title starts with `docs:` |
| Dependencies | `dependencies`, `deps`, title starts with `chore(deps)` or `bump ` |
| Internal / Chores | `chore`, `refactor`, `test`, `ci`, everything else |

If a PR has no labels, classify by title keywords alone.

## Step 4 — Present Output

```
## Release Notes: FROM → TO
**X pull requests** | Released: DATE (if TO is a tag with a release) or as of DATE

### Breaking Changes
- **#42** Remove deprecated `old_auth()` endpoint (@author)
  > Migration: replace calls with `new_auth()`. See [migration guide](link).
(omit section if empty)

### New Features
- **#38** Add webhook retry with exponential backoff (@author)
- **#35** Support OAuth2 PKCE flow (@author)

### Bug Fixes
- **#40** Fix session expiry calculation for users in UTC+12 (@author)
- **#33** Resolve race condition in file upload handler (@author)

### Performance
(omit section if empty)

### Documentation
- **#36** Add API authentication guide (@author)

### Dependencies
- **#44** Bump django from 4.2.1 to 4.2.8 (@dependabot)

### Internal
- **#41** Refactor auth middleware for testability (@author)
(omit section if empty)

---
**Full changelog:** https://github.com/OWNER/REPO/compare/FROM...TO
```

**Rules:**
- Omit any section that has zero PRs
- For Breaking Changes, always include a migration note if the PR body mentions one
- List PRs within each section in merged-date order (newest first)
- If `FROM` and `TO` resolve to the same commit, output: "No changes found between FROM and TO."
- If fewer than 3 PRs are found but the commit range is large, warn: "Only N PRs found — some PRs may have been squash-merged without a PR number in the commit message."
