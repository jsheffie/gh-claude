---
name: gh-pr-review
description: Use when the user asks to review, summarize, or assess a pull request. Trigger phrases include "review PR #N", "summarize PR #N", "flag risks in #N", "what does PR #N do", "is PR #N safe to merge", "review this PR", "look at pull request N". Also activate when the user shares a GitHub PR URL.
---

# GitHub PR Reviewer

Summarize a pull request, flag risks, and suggest reviewers. Follow these steps in order.

## Prerequisites

```bash
git rev-parse --git-dir
```
If that fails, tell the user: "You need to be inside a git repository to use gh-pr-review." Stop.

```bash
git remote -v | grep -i github
```
If no GitHub remote, tell the user: "This repo doesn't appear to have a GitHub remote." Stop.

```bash
gh auth status
```
If not authenticated, tell the user: "gh is not authenticated. Run `gh auth login`." Stop.

## Step 1 — Fetch PR Metadata

Replace `N` with the PR number before running.

```bash
gh pr view N --json number,title,body,state,author,headRefName,baseRefName,labels,milestone,reviewRequests,reviews,statusCheckRollup,additions,deletions,changedFiles,createdAt,updatedAt,comments
```

Record: number, title, body, state, author login, head branch, base branch, labels, milestone, requested reviewers, existing reviews, CI status, line stats (additions/deletions/changedFiles), and all comment bodies.

## Step 2 — Fetch the Diff

```bash
gh pr diff N
```

If the diff is very large (>500 lines), note that and focus analysis on the most impactful files. Do not truncate silently — tell the user if you sampled.

Also fetch changed file list with patch sizes:
```bash
gh api repos/{owner}/{repo}/pulls/N/files --jq '.[] | {filename, status, additions, deletions, patch}'
```

Derive `{owner}/{repo}` from:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## Step 3 — Identify Logical Owners

For each changed file, check git blame to find frequent recent contributors (potential reviewers):
```bash
git log --follow --format="%ae" -- PATH | sort | uniq -c | sort -rn | head -5
```

Run this for the 3–5 files with the most changes. Aggregate across files to find top 2–3 suggested reviewers (exclude the PR author).

## Step 4 — Analyze and Present

Format the response exactly as shown below.

```
## PR #N: "TITLE"
**Author:** @author | **Branch:** head → base | **State:** open/merged/closed
**Size:** +X / -Y lines across Z files | **CI:** ✓ passing / ✗ failing / ⚪ no checks

### Summary
2–4 sentence plain-English description of what this PR does and why, written for a reviewer
who hasn't read the code.

### Changed Areas
- `path/to/file.py` — what changed and why it matters (additions/deletions count)
- `path/to/other.js` — ...

### Risks & Concerns
- **[HIGH/MED/LOW]** Description of the concern and which file/line it relates to
  (omit this section entirely if no concerns found)

### Suggested Reviewers
- @username — reason (e.g., "last modified auth/session.py 3 times in past 30 days")

### Existing Reviews
- @reviewer — APPROVED / CHANGES_REQUESTED / COMMENTED
  (omit if no reviews yet)

### CI Status
- ✓ test-suite (2m 14s)
- ✗ lint (failed)
  (omit if no checks)
```

**Risk classification guide:**
- HIGH: security-sensitive changes (auth, permissions, secrets handling), data migrations without rollback, removing public API surface
- MED: business logic changes with no tests added, large diffs touching many unrelated files, dependency version bumps
- LOW: formatting, minor refactors, documentation, test-only changes

**Rules:**
- Always include Summary and Changed Areas
- Omit Risks section if no concerns
- Omit Existing Reviews if no reviews yet
- Omit CI Status if `statusCheckRollup` is null or empty
- Never fabricate risk items — only flag things actually visible in the diff
