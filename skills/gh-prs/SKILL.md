---
name: gh-prs
description: Use when the user asks to see their open pull requests. Trigger phrases include "my open PRs", "list my PRs", "what PRs do I have open", "show my pull requests", "what am I waiting on", "my active PRs". Also activate when the user mentions "my PRs" in passing while discussing review or merge status.
---

# GitHub Open PRs Lister

List all open pull requests authored by the current GitHub user. Follow these steps in order.

## Prerequisites

```bash
# Is gh installed and authenticated?
gh auth status
```

If `gh` is not installed, tell the user: "The `gh` CLI is required. Install it from https://cli.github.com." Stop.
If `gh` is not authenticated, tell the user: "gh is not authenticated. Run `gh auth login` to connect your GitHub account." Stop.

Get the authenticated username:
```bash
gh api user -q .login
```

Record as `GH_USER`.

## Step 1 — Determine Scope

Check whether we're in a git repo with a GitHub remote:
```bash
git rev-parse --git-dir 2>/dev/null && git remote -v | grep -i github
```

- If **inside a GitHub repo**: list PRs in that repo first, then offer cross-org view.
- If **not in a GitHub repo**: list PRs across all repos the user has access to.

## Step 2 — Fetch Open PRs

**If in a repo**, get the repo name:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

Then fetch PRs in this repo:
```bash
gh pr list --repo REPO --author @me --state open --json number,title,headRefName,isDraft,reviewDecision,statusCheckRollup,createdAt,updatedAt --limit 50
```

Also fetch PRs across all repos (broader view):
```bash
gh search prs --author GH_USER --state open --json number,title,repository,isDraft,createdAt,updatedAt --limit 30
```

## Step 3 — Present Output

Format the response as shown below. Sort by `updatedAt` descending (most recently active first).

For PRs in the current repo, show richer detail (review status, CI status). For cross-repo PRs, show repo name.

```
## Your Open PRs

### In this repo (REPO_NAME)
- #42 [DRAFT] "Add retry logic for webhook delivery" — branch `feat/webhook-retry`, updated 2h ago
  Reviews: 1 approved, 1 changes requested | CI: ✓ passing
- #38 "Fix session timeout calculation" — branch `fix/session-timeout`, updated 1d ago
  Reviews: awaiting review | CI: ✗ failing

### Other repos (5)
- #99 huvrdata/huvr — "Update IAM sync rules" — updated 3d ago
- #12 jsheffie/dotfiles — "Add zsh aliases" — updated 1w ago
```

**Rules:**
- Mark drafts as `[DRAFT]`
- Show review decision using plain English: `awaiting review`, `approved`, `changes requested`
- CI status: use ✓/✗/⚪ (passing/failing/no checks). Derive from `statusCheckRollup` — if any check is `FAILURE` or `ERROR`, show ✗; if all are `SUCCESS`, show ✓; otherwise ⚪.
- If there are no open PRs anywhere, output: "You have no open pull requests."
- Omit a section entirely if it has zero results.
