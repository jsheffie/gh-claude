class GhClaude < Formula
  desc "GitHub workflow toolkit as a Claude Code plugin"
  homepage "https://github.com/jsheffie/gh-claude"
  url "https://github.com/jsheffie/gh-claude/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "47e6b52e13b78809182beeb94e6468b9d7b5bfd0e9a6009d5e3c61fb1b11c63f"
  license "MIT"
  version "1.1.2"

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
