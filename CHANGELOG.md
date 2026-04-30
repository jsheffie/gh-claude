# Changelog

## v1.1.0 — 2026-04-30

`gh-related` now optionally renders an interactive mindmap. If the
[`fatbrainmap`](https://github.com/jsheffie/gh-claude-fatbrainmap-mcp) MCP server
is connected, the skill builds a JSON graph and calls
`mcp__fatbrainmap__render_mindmap` with it, returning a clickable URL to a
React Flow visualization (elk hierarchical or d3-force organic layout, bezier
edges, drag, GitHub links). When the MCP server is not present, behavior is
unchanged.

## v1.0.0 — 2026-04-30

Initial release.

### Skills
- `gh-related` — Find all GitHub issues and PRs related to a given issue or PR number
- `gh-prs` — List your open pull requests with review and CI status
- `gh-pr-review` — Summarize a PR diff, flag risks, suggest reviewers
- `gh-issue-triage` — Classify an issue, estimate effort, find duplicates, suggest assignee
- `gh-release-notes` — Generate structured release notes from merged PRs between refs/tags
- `gh-stale-cleanup` — Find stale issues/PRs and generate batch close/label commands
