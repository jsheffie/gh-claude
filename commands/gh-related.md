---
description: "Find all issues and PRs related to a given issue or PR number"
---

Find all GitHub issues and pull requests related to issue or PR number $ARGUMENTS in this repository.

Use the gh-related skill to run the full investigation and present grouped results.

If $ARGUMENTS is empty, ask the user: "Which issue or PR number would you like to find related items for?"

## Mindmap visualization (REQUIRED if tool is available)

After producing the text output, you **must** also render an interactive mindmap whenever the `mcp__fatbrainmap__render_mindmap` tool is available in your tool list. Do not skip it — the user explicitly wants the visualization alongside the text. Only skip if the tool is genuinely not in your tool list.

Build a graph in this exact JSON shape and pass it as the `graph` argument to `mcp__fatbrainmap__render_mindmap`:

```json
{
  "version": 1,
  "repo": "owner/name",
  "root": <the queried issue or PR number>,
  "nodes": [
    {
      "id": <number>,
      "kind": "issue" | "pr",
      "state": "open" | "closed" | "merged",
      "title": "<title>",
      "url": "https://github.com/owner/name/issues/<n>",
      "labels": ["<label>", ...],
      "milestone": "<name or null>"
    }
  ],
  "edges": [
    {
      "source": <root number>,
      "target": <related number>,
      "kind": "direct" | "semantic",
      "reason": "<short reason matching the text output>"
    }
  ]
}
```

Rules:
- Always include the queried item itself as a node (the root).
- Include every node that appears in the text output (Directly Referenced + Semantically Related). Skip items you couldn't fetch.
- One edge per related item, sourced from the root. `kind: "direct"` for items in "Directly Referenced", `kind: "semantic"` for "Semantically Related".
- For PRs use `https://github.com/owner/name/pull/<n>` for the URL; for issues use `/issues/<n>`.
- For PRs, `state` may be `open`, `closed`, or `merged`. For issues, only `open` or `closed`.

The tool returns a markdown string like `Mindmap ready: [Open visualization](http://localhost:8765/m/abc12345)`. Append it on a new line at the end of your response, prefixed with 🧠:

```
🧠 Mindmap ready: [Open visualization](http://localhost:8765/m/abc12345)
```

If the tool call fails, mention the failure briefly and continue with just the text output.
