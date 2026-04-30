---
name: gh-issue-triage
description: Use when the user asks to triage, label, classify, or assess an issue. Trigger phrases include "triage issue #N", "label this issue", "find duplicates of #N", "how hard is issue #N", "estimate effort for #N", "who should work on #N", "assess issue #N", "categorize this issue". Also activate when the user asks "what kind of issue is this" mid-conversation.
---

# GitHub Issue Triager

Triage an issue: classify it, estimate effort, find duplicates, and suggest an assignee. Follow these steps in order.

## Prerequisites

```bash
git rev-parse --git-dir
```
If that fails, tell the user: "You need to be inside a git repository to use gh-issue-triage." Stop.

```bash
git remote -v | grep -i github
```
If no GitHub remote, tell the user: "This repo doesn't appear to have a GitHub remote." Stop.

```bash
gh auth status
```
If not authenticated, tell the user: "gh is not authenticated. Run `gh auth login`." Stop.

## Step 1 — Fetch the Issue

Replace `N` with the issue number before running.

```bash
gh issue view N --json number,title,body,state,labels,milestone,assignees,author,comments,createdAt
```

If the issue is not found, tell the user: "No issue found with number #N." Stop.

Record: number, title, body, state, existing labels, milestone, assignees, author, and all comment bodies.

Get the repo name:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## Step 2 — Classify the Issue

Based on the title and body, determine:

**Type** (pick one):
- `bug` — something is broken or behaving incorrectly
- `feature` — new capability requested
- `enhancement` — improvement to existing behavior
- `docs` — documentation gap or error
- `question` — user seeking help or clarification
- `chore` — maintenance, dependency bump, refactor

**Priority signal** (pick one):
- `critical` — data loss, security vulnerability, production outage, blocking many users
- `high` — significant user-facing breakage, no workaround
- `medium` — moderate impact, workaround exists
- `low` — minor, cosmetic, or nice-to-have

**Effort estimate** (pick one):
- `XS` — < 1 hour, trivial change
- `S` — 1–4 hours, single file/component
- `M` — half day to 1 day, a few files
- `L` — 2–5 days, cross-cutting change
- `XL` — week+, requires design work

## Step 3 — Find Potential Duplicates

Build a search query from the issue title (same stop-word filtering as gh-related: remove words ≤3 chars and common stop words, keep 4 longest remaining words).

```bash
gh issue list --repo REPO --search "SEARCH_TERMS" --state all --limit 20 --json number,title,state,labels
```

Filter: keep only issues where at least one title keyword matches and the number is not N.

Limit to the 5 most likely duplicates.

## Step 4 — Suggest Assignee

Find who has resolved similar issues recently:
```bash
gh issue list --repo REPO --search "SEARCH_TERMS" --state closed --limit 10 --json number,assignees,closedAt
```

Collect all assignee logins from closed similar issues. The login appearing most often is the suggested assignee.

If no match, skip the suggestion.

## Step 5 — Present Output

```
## Triage: #N "TITLE"

### Classification
- **Type:** bug / feature / enhancement / docs / question / chore
- **Priority:** critical / high / medium / low
- **Effort:** XS / S / M / L / XL
- **Suggested labels:** `label-one`, `label-two`
  (based on classification + existing repo labels that match)

### Reasoning
2–3 sentences explaining the classification and effort estimate.

### Potential Duplicates (COUNT)
- #22 (open) "Similar title here" — likely duplicate because [reason]
- #31 (closed) "Another match" — may already be resolved
(omit section if no duplicates found)

### Suggested Assignee
@username — resolved N similar issues recently
(omit if no data)

### Suggested Actions
- [ ] Add labels: `bug`, `priority:high`
- [ ] Set milestone: v2.3 (if milestone matches existing ones)
- [ ] Assign to @username
- [ ] Link to duplicate #22 with "duplicate of #22" comment
(only include actions that are actually warranted)
```

**Rules:**
- Only suggest labels that already exist in the repo. Fetch available labels if needed:
  ```bash
  gh label list --repo REPO --json name --limit 100
  ```
- Never make write operations (no `gh issue edit`, no comments) unless the user explicitly asks
- If the issue is already labeled and assigned, note what's already done and only suggest gaps
