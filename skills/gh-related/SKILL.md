---
name: gh-related
description: Use when the user asks about issues or PRs related to a specific issue or PR number. Trigger phrases include "related issues", "related PRs", "related to this issue", "related to this PR", "what else is connected to #N", "find issues related to", "show me related", "what's related". Also self-activate when the user is clearly asking about issue/PR relationships mid-conversation even without an explicit number — in that case, ask for the number before proceeding.
---

# GitHub Issue/PR Relationship Finder

Find all GitHub issues and pull requests related to a given issue or PR number. Follow these steps in order.

## Prerequisites

Before doing anything else, run these checks:

```bash
# Are we in a git repo?
git rev-parse --git-dir
```

If that fails, tell the user: "You need to be inside a git repository to use gh-related." Stop.

```bash
# Does it have a GitHub remote?
git remote -v | grep -i github
```

If no GitHub remote is found, tell the user: "This repo doesn't appear to have a GitHub remote. Run `gh repo view` to confirm." Stop.

```bash
# Is gh installed and authenticated?
gh auth status
```

If `gh` is not installed, tell the user: "The `gh` CLI is required. Install it from https://cli.github.com." Stop.
If `gh` is not authenticated, tell the user: "gh is not authenticated. Run `gh auth login` to connect your GitHub account." Stop.

## Step 1 — Identify the Target

You have a number N (from the slash command argument or conversation context).

Replace `N` with the actual issue or PR number before running.

Try fetching it as an issue first:
```bash
gh issue view N --json number,title,body,state,labels,milestone,assignees,comments
```

If that command exits with an error (issue not found), try as a PR:
```bash
gh pr view N --json number,title,body,state,labels,milestone,assignees,comments
```

If both fail, tell the user: "No issue or PR found with number #N in this repository." Stop.

Record: the number, type (issue or PR), title, body, state (for PRs, state may be `open`, `closed`, or `merged`; for issues, `open` or `closed`), array of label names, milestone name (if any), and all comment bodies.

## Step 2 — Extract Textual Cross-References

Scan the body and every comment body for these patterns (case-insensitive):

**Bare references:** `#NNN` (any sequence of digits preceded by `#`)

**Keyword references:** the following words immediately followed by `#NNN`:
- `fixes`, `fix`, `fixed`
- `closes`, `close`, `closed`
- `resolves`, `resolve`, `resolved`
- `related to`, `see also`, `references`, `ref`

If more than 20 unique reference numbers are found, process only the first 20 (in order of appearance).

For each reference number found (skip the target's own number):

Replace `REF` with each reference number before running.

```bash
gh issue view REF --json number,title,state 2>/dev/null || gh pr view REF --json number,title,state 2>/dev/null
```

If both fail for a reference, skip that reference silently.

Record for each: number, type (issue/PR), state (open/closed/merged), title, and where it was found ("body" or "comment").

## Step 3 — Semantic Search

**Build search terms:**
1. Take the target's title. Split into words. Remove words that are 3 characters or fewer. Remove these stop words (case-insensitive): `this`, `that`, `with`, `from`, `have`, `will`, `been`, `were`, `they`, `their`, `there`, `what`, `when`, `where`, `which`, `your`, `into`, `about`, `more`, `than`, `also`, `some`, `such`, `only`, `then`, `well`, `like`, `just`, `over`, `after`, `before`, `other`, `those`, `these`, `would`, `could`, `should`, `very`, `much`, `many`, `does`, `done`, `each`, `both`, `most`, `make`, `made`, `need`, `needs`, `using`, `used`, `adds`, `added`. Keep the 4 longest remaining words.
2. Add label names from the target (each as a separate term).
3. Add the milestone name if set.

Combine into a single search string (space-separated).

First, derive the current repo name:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```
Use the result as `REPO` in the commands below.

Then run:
```bash
gh issue list --repo REPO --search "SEARCH_TERMS" --state all --limit 20 --json number,title,state,labels,milestone
gh pr list --repo REPO --search "SEARCH_TERMS" --state all --limit 20 --json number,title,state,labels,milestone
```

**Filter results — keep an item only if at least one of:**
- It shares at least one label name with the target
- It shares the same milestone name as the target (and target has a milestone)
- At least one of the 4 title keywords appears in the result's title

**Deduplicate:** Remove the target itself. Remove any number already found in Step 2.

## Step 4 — Present Output

Format the final response exactly as shown below. Use actual values from your findings.

```
## Related to #N: "TARGET TITLE"

### Directly Referenced (COUNT)
- #38 (PR, merged) "Add session expiry config" — body says "fixes #38"
- #51 (Issue, open) "Users randomly logged out" — mentioned in comment

### Semantically Related (COUNT)
- #29 (Issue, closed) "Session management refactor" — shared label `auth`, milestone `v2.1`
- #44 (PR, open) "Update JWT expiry" — keyword match: "session", "timeout"
```

**Rules:**
- Omit a section entirely if it has zero results (do not show an empty section)
- If both sections have zero results, output: "No related issues or PRs found for #N."
- The reason field is required for every item — never omit it
- State values: open, closed, or merged (PRs only)
- List directly referenced items in the order they appear in the body/comments
- List semantically related items with the strongest signal first (label+milestone match beats label-only beats keyword-only)
- After printing the text output, proceed to Step 5 — do not stop the response here

## Step 5 — Mindmap Visualization (REQUIRED if tool is available)

**This step is mandatory whenever the `mcp__fatbrainmap__render_mindmap` tool appears in your available tools.** Do not skip it for "brevity" or because the text output is already informative — the user explicitly wants the visualization. Only skip if the tool is genuinely not in your tool list.

You MUST call `mcp__fatbrainmap__render_mindmap` with the findings as a JSON graph and append the returned URL to your response. The text output and the mindmap are complementary — both ship together.

**Build the graph:**

```json
{
  "version": 1,
  "repo": "owner/name",
  "root": N,
  "nodes": [
    {
      "id": <number>,
      "kind": "issue" | "pr",
      "state": "open" | "closed" | "merged",
      "title": "<title>",
      "url": "https://github.com/owner/name/issues/<n>"  // or /pull/<n> for PRs
      "labels": ["<label>", ...],
      "milestone": "<name>" | null
    }
  ],
  "edges": [
    {
      "source": N,
      "target": <related number>,
      "kind": "direct" | "semantic",
      "reason": "<same reason string used in the text output>"
    }
  ]
}
```

Rules for building the graph:
- Always include the target itself as a node (id = N), with `isRoot` semantics handled by the server.
- Include every node that appears in the text output (Directly Referenced + Semantically Related). Don't include items you couldn't fetch.
- One edge per related item, sourced from the target. `kind: "direct"` for items in "Directly Referenced", `kind: "semantic"` for "Semantically Related".
- The `url` field must point to the issue (`/issues/N`) or pull request (`/pull/N`) page on github.com.
- For PRs, `state` may be `open`, `closed`, or `merged`. For issues, only `open` or `closed`.

**Then call the tool:**

After printing the text output, invoke `mcp__fatbrainmap__render_mindmap` with the graph object as the `graph` argument. The tool returns a markdown string like `Mindmap ready: [Open visualization](http://localhost:8765/m/abc12345)`. Append exactly that string to your response on a new line, prefixed with the brain emoji:

```
🧠 Mindmap ready: [Open visualization](http://localhost:8765/m/abc12345)
```

If the tool call fails for any reason, do not retry — just continue with the text output already printed and mention the failure briefly.
