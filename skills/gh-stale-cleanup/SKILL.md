---
name: gh-stale-cleanup
description: Use when the user asks to find or clean up stale, abandoned, or inactive issues and pull requests. Trigger phrases include "stale issues", "clean up old PRs", "find abandoned issues", "what's been sitting around", "inactive PRs", "close stale items", "housekeeping on issues", "audit open issues". Also activate when the user says something like "our issue tracker is a mess".
---

# GitHub Stale Cleanup

Find stale issues and pull requests and generate a batch action list. Follow these steps in order.

## Prerequisites

```bash
git rev-parse --git-dir
```
If that fails, tell the user: "You need to be inside a git repository to use gh-stale-cleanup." Stop.

```bash
git remote -v | grep -i github
```
If no GitHub remote, tell the user: "This repo doesn't appear to have a GitHub remote." Stop.

```bash
gh auth status
```
If not authenticated, tell the user: "gh is not authenticated. Run `gh auth login`." Stop.

Get the repo name:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## Step 1 — Determine Staleness Threshold

Default thresholds (use these unless the user specifies):
- **Issues:** stale if no activity (comments, labels, assignee change) in **90 days**
- **PRs:** stale if no activity in **60 days** (PRs block merges, so shorter window)

If the user provides a different threshold (e.g., "6 months", "30 days"), use that.

Calculate the cutoff date as `TODAY - THRESHOLD_DAYS`.

## Step 2 — Fetch Candidates

```bash
gh issue list --repo REPO --state open --limit 200 --json number,title,labels,assignees,createdAt,updatedAt,comments,milestone
```

```bash
gh pr list --repo REPO --state open --limit 200 --json number,title,labels,author,assignees,createdAt,updatedAt,reviewDecision,isDraft,statusCheckRollup,headRefName
```

## Step 3 — Filter Stale Items

For **issues**: mark stale if `updatedAt` < cutoff AND no `pinned` label AND state is open.

For **PRs**: mark stale if `updatedAt` < cutoff AND not a draft marked as WIP AND state is open.

Skip items with any of these labels: `pinned`, `wip`, `in-progress`, `do-not-close`, `blocked`, `waiting-for-upstream`.

For each stale PR, also note:
- Does it have a failing CI status? → `ci-failing`
- Does it have unresolved `CHANGES_REQUESTED` review? → `needs-changes`
- Is it a draft? → `draft`

## Step 4 — Categorize for Action

Classify each stale item into a recommended action:

| Condition | Recommended action |
|---|---|
| PR with ci-failing + no recent author activity | Close with "CI failing, closing stale" |
| PR with needs-changes + no response in threshold | Close with "awaiting changes, closing stale" |
| Issue with no assignee, no milestone, no activity | Close with "no activity, closing stale" |
| Issue with milestone set | Add `stale` label — may be planned work |
| PR that is draft + stale | Add `stale` label — author may return |
| Issue with many comments (≥5) but stale | Flag for human review — was active, now quiet |

## Step 5 — Present Output

```
## Stale Cleanup: REPO
Threshold: issues > 90 days, PRs > 60 days | Cutoff: DATE
Found: X stale issues, Y stale PRs

### Recommended: Close (Z items)

#### Issues to Close
- #12 "Old feature request: dark mode" — 8 months inactive, no assignee, no milestone
  > gh issue close 12 --comment "Closing due to inactivity. Reopen or comment if still relevant."
- #7 "Question about API rate limits" — answered in comments, 6 months no follow-up
  > gh issue close 7 --comment "Closing as answered. Feel free to reopen if you have more questions."

#### PRs to Close
- #55 "WIP: experimental caching layer" — 4 months, CI failing, no recent commits
  > gh pr close 55 --comment "Closing stale PR. CI has been failing and there's been no recent activity."

### Recommended: Add `stale` Label (N items)
- #88 "Refactor user model" — milestone v3.0 set but 3 months quiet; may be planned
  > gh issue edit 88 --add-label stale
- #91 (PR, draft) "New import flow" — draft, 2 months inactive; author may return
  > gh pr edit 91 --add-label stale

### Flag for Human Review (N items)
- #44 "Performance regression on large datasets" — was very active (12 comments), quiet for 95 days
  Last comment: @username said "I'll look at this next sprint" — may need a ping

### Batch Commands
Copy-paste to close all recommended items at once:

```bash
# Close stale issues
gh issue close 12 --comment "Closing due to inactivity. Reopen or comment if still relevant."
gh issue close 7 --comment "Closing as answered. Feel free to reopen if you have more questions."

# Close stale PRs
gh pr close 55 --comment "Closing stale PR. CI has been failing and there's been no recent activity."

# Add stale labels
gh issue edit 88 --add-label stale
gh pr edit 91 --add-label stale
```
```

**Rules:**
- Never run any write commands automatically — output them for the user to review and run
- If `stale` label doesn't exist in the repo, note it and suggest creating it: `gh label create stale --color "#e4e669" --description "No recent activity"`
- If all items look healthy (nothing past threshold), output: "No stale items found — everything is active within the last THRESHOLD days."
- Cap the close list at 20 items per run to avoid overwhelming the user
