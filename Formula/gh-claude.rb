class GhClaude < Formula
  desc "GitHub workflow toolkit as a Claude Code plugin"
  homepage "https://github.com/jsheffie/gh-claude"
  url "https://github.com/jsheffie/gh-claude/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "de1bf4922530a58052f44f783489fd9e5a07b411e6179daba0057ec5894b3c44"
  license "MIT"
  version "1.0.1"

  depends_on "gh"

  def install
    libexec.install Dir["*"]
    (bin/"gh-claude-install").write <<~SH
      #!/bin/bash
      exec bash "#{libexec}/scripts/install.sh" "$@"
    SH
    chmod 0755, bin/"gh-claude-install"
  end

  def caveats
    <<~EOS
      To register gh-claude with Claude Code, run:
        gh-claude-install

      Then inside Claude Code, run:
        /reload-plugins

      Skills will be available as:
        /gh-claude:related, /gh-claude:prs, /gh-claude:pr-review,
        /gh-claude:issue-triage, /gh-claude:release-notes, /gh-claude:stale-cleanup
    EOS
  end

  test do
    assert_predicate libexec/"scripts/install.sh", :exist?
    assert_predicate libexec/".claude-plugin/plugin.json", :exist?
  end
end
