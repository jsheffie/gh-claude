---
description: "List your currently open GitHub pull requests with review and CI status"
---

List your currently open GitHub pull requests in the current repo.

## Step 1 — Get repo and user

```bash
gh auth status
gh api user -q .login
gh repo view --json nameWithOwner -q .nameWithOwner
```

If `gh` is not authenticated, stop and tell the user to run `gh auth login`.
If not in a GitHub repo, stop and tell the user: "Run this from inside a GitHub repository."

Record the repo as `REPO` and the login as `GH_USER`.

## Step 2 — Fetch all open PRs authored by you in this repo

```bash
gh pr list --repo REPO --author @me --state open --json number,title,isDraft,reviewDecision,statusCheckRollup,updatedAt --limit 100
```

This is the only fetch. Do not fetch cross-repo PRs.

## Step 3 — Categorize every PR

Sort by `updatedAt` descending. Assign each PR to exactly one bucket — use the FIRST rule that matches:

1. **Ready to merge** — `reviewDecision` is `APPROVED` and no check is `FAILURE`/`ERROR`
2. **CI failing** — any check in `statusCheckRollup` has conclusion `FAILURE` or `ERROR`
3. **Drafts** — `isDraft` is `true`
4. **CI passing, awaiting review** — all checks `SUCCESS` (or no checks) and `reviewDecision` is not `APPROVED` and not a draft
5. **Pending** — everything else

CI icon per PR: if any check is `FAILURE` or `ERROR` → `❌`. If all checks `SUCCESS` → `✅`. If no checks or empty array → `—`.

## Step 4 — Output

Output MUST follow this EXACT format. No markdown headers with `##`, no tables, no prose.

```
Here are your N open PRs in REPO:

**Ready to merge**
- #12063 ✅ ✅ Approved — fix(frontend/api): title here

**CI failing**
- #12721 ❌ — deps(huvr-api): title here

**Drafts**
- #12830 ✅ — docs: title here
- #11220 — — fix(frontend): title here

**CI passing, awaiting review**
- #12945 ✅ — fix(audit): title here
- #12939 ✅ — feat(api): title here

**Pending**
- #11220 — — fix(frontend): title here
```

Rules:
- Section order: Ready to merge → CI failing → Drafts → CI passing, awaiting review → Pending
- Each line: `- #NUMBER CI_ICON — title`
- **Ready to merge** lines: `- #NUMBER ✅ ✅ Approved — title`
- Omit any section that has zero PRs
- Do NOT add branch names, dates, or extra review text — one line per PR, short
- Do NOT use markdown code blocks or tables in the output
- Use `**Bold**` for section headers only

## Step 5 — Mindmap (REQUIRED if tool is available)

After the text output, if `mcp__fatbrainmap__render_mindmap` is in your tool list, you MUST call it. Do not skip this step.

Build a graph JSON with:
- Root node: `{ "id": 0, "kind": "issue", "state": "open", "title": "Your open PRs — REPO", "url": "https://github.com/REPO/pulls", "labels": [], "milestone": null }`
- One node per PR: `{ "id": PR_NUMBER, "kind": "pr", "state": STATE, "title": TITLE, "url": "https://github.com/REPO/pull/PR_NUMBER", "labels": [BUCKET], "milestone": BUCKET_NAME }`
  - `state`: `"merged"` if ready-to-merge, `"closed"` if CI failing, `"open"` for everything else
  - `labels`: single-element array with the bucket slug: `["ready"]`, `["ci-failing"]`, `["draft"]`, `["ci-passing"]`, `["pending"]`
  - `milestone`: the bucket display name string
- One edge per PR: `{ "source": 0, "target": PR_NUMBER, "kind": "direct", "reason": "BUCKET_NAME" }`

Call `mcp__fatbrainmap__render_mindmap` with `{ "version": 1, "repo": "REPO", "root": 0, "nodes": [...], "edges": [...] }`.

After the tool returns, output this line exactly (replace URL with the returned URL):
```
🧠 Mindmap ready: [Open visualization](URL)
```
