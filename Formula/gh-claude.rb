class GhClaude < Formula
  desc "GitHub workflow toolkit as a Claude Code plugin"
  homepage "https://github.com/jsheffie/gh-claude"
  # Update url and sha256 after tagging v1.0.0:
  #   url "https://github.com/jsheffie/gh-claude/archive/refs/tags/v1.0.0.tar.gz"
  #   sha256 "<run: shasum -a 256 on the downloaded tarball>"
  url "https://github.com/jsheffie/gh-claude.git", tag: "v1.0.0"
  license "MIT"
  version "1.0.0"

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
