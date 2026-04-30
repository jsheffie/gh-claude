---
description: "Generate structured release notes from merged PRs between two refs or tags"
---

Generate release notes for $ARGUMENTS (e.g., "v1.2..v1.3", "v2.0", or "since last tag").

Use the gh-release-notes skill to find merged PRs in the range and produce structured, categorized release notes.

If $ARGUMENTS is empty, ask the user: "What range would you like release notes for? (e.g., v1.2..v1.3, or just the latest release)"
