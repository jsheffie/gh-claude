---
description: "List your currently open GitHub pull requests with review and CI status"
---

List your currently open GitHub pull requests with CI and review status.

## Step 1 — Get authenticated user

```bash
gh auth status
gh api user -q .login
```

If `gh` is not authenticated, stop and tell the user to run `gh auth login`.

Record the login as `GH_USER`.

## Step 2 — Fetch PRs

Check if we're in a GitHub repo:
```bash
git rev-parse --git-dir 2>/dev/null && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null
```

If in a repo, fetch that repo's PRs with full detail:
```bash
gh pr list --repo REPO --author @me --state open --json number,title,isDraft,reviewDecision,statusCheckRollup,updatedAt --limit 100
```

Also fetch cross-repo PRs:
```bash
gh search prs --author GH_USER --state open --json number,title,repository,isDraft,updatedAt --limit 50
```

## Step 3 — Categorize

Sort all PRs by `updatedAt` descending. Assign each to exactly one category in this order:

1. **Ready to merge** — `reviewDecision` is `APPROVED` and CI is passing
2. **CI passing, awaiting review** — CI passing, `reviewDecision` is not `APPROVED`
3. **CI failing** — any check in `FAILURE` or `ERROR` state
4. **Drafts** — `isDraft` is true (regardless of CI/review)
5. **Pending** — everything else (no CI data, no review decision yet)

CI status per PR: if any check is `FAILURE` or `ERROR` → ✅ = false, ❌. If all checks `SUCCESS` → ✅. If no checks → `—`.

## Step 4 — Output

Output MUST follow this exact format. No markdown headers with `##`, no tables, no prose paragraphs. Use plain bold text for section headers and plain list items.

```
Here are your N open PRs:

**Ready to merge**
- #12063 ✅ ✅ Approved — fix(frontend/api): title here

**CI passing, awaiting review**
- #12945 ✅ — fix(audit): title here
- #12939 ✅ — feat(api): title here

**CI failing**
- #12721 ❌ — deps(huvr-api): title here

**Drafts**
- #12830 ✅ — docs: title here
- #11220 — — fix(frontend): title here

**Pending**
- #99 huvrdata/other-repo — title here
```

Rules:
- Each line: `- #NUMBER CI_ICON — title`
- For **Ready to merge**: show two icons — CI icon then ✅ for approved: `✅ ✅ Approved —`
- For **Drafts**: prefix title with nothing special; CI icon still shown
- Cross-repo PRs: show `repo/name —` after the number instead of CI icon if CI data unavailable
- Omit any section that has zero PRs
- Do NOT add branch names, dates, or review text inline — keep lines short
- Do NOT use markdown code blocks or tables in the output
- Use plain `**Bold**` for section headers (renders in Claude's terminal)

## Step 5 — Mindmap (REQUIRED if tool is available)

After the text output, if `mcp__fatbrainmap__render_mindmap` is in your tool list, render a mindmap.

Build this JSON and call `mcp__fatbrainmap__render_mindmap` with it as the `graph` argument:

```json
{
  "version": 1,
  "repo": "GH_USER/open-prs",
  "root": 0,
  "nodes": [
    {
      "id": 0,
      "kind": "issue",
      "state": "open",
      "title": "Your open PRs",
      "url": "https://github.com/GH_USER",
      "labels": [],
      "milestone": null
    }
  ],
  "edges": []
}
```

Add one node per PR with:
- `id`: the PR number (integer)
- `kind`: `"pr"`
- `state`: `"open"` if CI passing or pending, `"closed"` if CI failing, `"merged"` if approved/ready to merge
- `title`: the PR title
- `url`: the PR URL (`https://github.com/REPO/pull/NUMBER`)
- `labels`: array of category strings, e.g. `["ready"]`, `["ci-failing"]`, `["draft"]`
- `milestone`: the category name as a string: `"Ready to merge"`, `"CI passing"`, `"CI failing"`, `"Draft"`, or `"Pending"`

Add one edge per PR: `{ "source": 0, "target": PR_NUMBER, "kind": "direct", "reason": "category: CATEGORY_NAME" }`

Show the returned URL to the user.
