class GhClaude < Formula
  desc "GitHub workflow toolkit as a Claude Code plugin"
  homepage "https://github.com/jsheffie/gh-claude"
  url "https://github.com/jsheffie/gh-claude/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "7c2423577c5c5b09ceb14a0a03fb43cfbb3ab4a14282484034cea2754d6cc412"
  license "MIT"
  version "1.1.1"

  depends_on "gh"

  def install
    libexec.install Dir["*", ".*"].reject { |f| f == "." || f == ".." }
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
