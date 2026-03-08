class Operator < Formula
  desc "Voice-first orchestration layer for multiple concurrent Claude Code sessions"
  homepage "https://github.com/Jud/operator"
  url "https://github.com/Jud/operator.git",
      tag:      "v0.1.0",
      revision: "HEAD"
  license "MIT"
  head "https://github.com/Jud/operator.git", branch: "main"

  depends_on :macos
  depends_on :xcode => ["16.0", :build]
  depends_on "node" => :build
  depends_on "swift" => :build

  def install
    # Build the Swift daemon
    cd "Operator" do
      system "swift", "build", "-c", "release", "--disable-sandbox"
      bin.install ".build/release/Operator" => "operator-daemon"
    end

    # Build the MCP server
    cd "mcp-server" do
      system "npm", "ci", "--ignore-scripts"
      system "npm", "run", "build"

      # Install MCP server to libexec (not user-facing)
      libexec.install "build", "package.json", "node_modules"
    end

    # Create wrapper script for MCP server
    (bin/"operator-mcp").write <<~SH
      #!/bin/bash
      exec node "#{libexec}/build/index.js" "$@"
    SH
    (bin/"operator-mcp").chmod 0755

    # Install setup script from source repo
    bin.install "bin/operator-setup.sh" => "operator-setup"
    (bin/"operator-setup").chmod 0755

    # Install audio resource files
    cd "Operator/Sources/Resources" do
      (share/"operator/sounds").install Dir["*.caf"] if Dir["*.caf"].any?
    end
  end

  def post_install
    (var/"operator").mkpath
  end

  def caveats
    <<~EOS
      Run setup to register with all Claude Code accounts:
        operator-setup

      Start the daemon:
        brew services start operator

      Requirements:
        - macOS 15+ (Sequoia)
        - iTerm2 with scripting enabled
        - Microphone permission (granted on first run)
    EOS
  end

  service do
    run [opt_bin/"operator-daemon"]
    keep_alive true
    log_path var/"log/operator.log"
    error_log_path var/"log/operator-error.log"
    environment_variables HOME: Dir.home
  end

  test do
    assert_predicate bin/"operator-daemon", :exist?
    assert_predicate bin/"operator-mcp", :exist?
    assert_predicate bin/"operator-setup", :exist?
  end
end
