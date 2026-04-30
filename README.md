# gh-claude

A GitHub workflow toolkit for [Claude Code](https://claude.ai/code). Six skills for working with GitHub issues and pull requests directly from your AI coding session.

## Skills

| Skill | Command | What it does |
|---|---|---|
| `gh-related` | `/gh-claude:related 42` | Find all issues and PRs related to issue/PR #42 |
| `gh-prs` | `/gh-claude:prs` | List your open PRs with review and CI status |
| `gh-pr-review` | `/gh-claude:pr-review 99` | Summarize PR #99, flag risks, suggest reviewers |
| `gh-issue-triage` | `/gh-claude:issue-triage 15` | Classify issue #15, estimate effort, find duplicates |
| `gh-release-notes` | `/gh-claude:release-notes v1.2..v1.3` | Generate release notes between two refs |
| `gh-stale-cleanup` | `/gh-claude:stale-cleanup` | Find stale issues/PRs and produce batch close commands |

All skills require `gh` CLI installed and authenticated (`gh auth login`).

## Installation

### Via Homebrew

```bash
brew tap jsheffie/gh-claude
brew install gh-claude
gh-claude-install        # registers the plugin with Claude Code
```

Then inside Claude Code:
```
/reload-plugins
```

### Updating

```bash
brew update && brew upgrade gh-claude
gh-claude-install
```

Then inside Claude Code:
```
/reload-plugins
```

### Manual

```bash
git clone https://github.com/jsheffie/gh-claude.git
cd gh-claude
bash scripts/install.sh
```

Then inside Claude Code:
```
/reload-plugins
```

### Registering the marketplace (one-time)

Claude Code requires `gh-claude` to be listed as a known marketplace before it will load skills and commands. Run one of the following once after installation, then `/reload-plugins`.

**Option A — via `settings.json`** (recommended):
```bash
python3 - <<'EOF'
import json
path = "/Users/jds/.claude/settings.json"
with open(path) as f: d = json.load(f)
d.setdefault("extraKnownMarketplaces", {})["gh-claude"] = {
    "source": {"source": "github", "repo": "jsheffie/gh-claude"}
}
with open(path, "w") as f: json.dump(d, f, indent=2); f.write("\n")
print("Done")
EOF
```

**Option B — via `known_marketplaces.json`**:
```bash
python3 - <<'EOF'
import json
path = "/Users/jds/.claude/plugins/known_marketplaces.json"
with open(path) as f: d = json.load(f)
d["gh-claude"] = {
    "source": {"source": "github", "repo": "jsheffie/gh-claude"},
    "installLocation": "/Users/jds/.claude/plugins/marketplaces/gh-claude",
    "lastUpdated": "2026-04-30T20:00:00.000Z"
}
with open(path, "w") as f: json.dump(d, f, indent=2); f.write("\n")
print("Done")
EOF
```

### Local development

```bash
claude --plugin-dir /path/to/gh-claude
```

## Requirements

- [Claude Code](https://claude.ai/code)
- [gh CLI](https://cli.github.com) — installed and authenticated

## License

MIT
