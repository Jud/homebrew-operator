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

    # Create setup script that auto-registers MCP in all Claude config dirs
    (bin/"operator-setup").write <<~SH
      #!/bin/bash
      set -e

      MCP_CMD="#{bin}/operator-mcp"
      TOKEN_DIR="$HOME/.operator"
      REGISTERED=0

      # Generate auth token if needed
      if [ ! -f "$TOKEN_DIR/token" ]; then
        mkdir -p "$TOKEN_DIR"
        chmod 700 "$TOKEN_DIR"
        openssl rand -hex 32 > "$TOKEN_DIR/token"
        chmod 600 "$TOKEN_DIR/token"
        echo "Generated auth token at $TOKEN_DIR/token"
      fi

      # Find all Claude Code config directories
      CONFIG_DIRS=()
      for d in "$HOME/.claude" "$HOME/.claude-"*; do
        if [ -f "$d/.claude.json" ]; then
          CONFIG_DIRS+=("$d")
        fi
      done

      if [ ${#CONFIG_DIRS[@]} -eq 0 ]; then
        echo "No Claude Code config directories found."
        echo "Run Claude Code at least once, then re-run this setup."
        exit 1
      fi

      echo "Found ${#CONFIG_DIRS[@]} Claude Code config(s):"
      for d in "${CONFIG_DIRS[@]}"; do
        echo "  $d"
      done
      echo ""

      # Register MCP server in each config
      for d in "${CONFIG_DIRS[@]}"; do
        CONFIG_FILE="$d/.claude.json"

        # Check if already registered
        if python3 -c "
import json, sys
with open('$CONFIG_FILE') as f:
    d = json.load(f)
servers = d.get('mcpServers', {})
if 'operator' in servers:
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
          echo "  $(basename "$d"): already registered ✓"
          REGISTERED=$((REGISTERED + 1))
          continue
        fi

        # Add MCP server entry
        python3 -c "
import json
with open('$CONFIG_FILE') as f:
    d = json.load(f)
servers = d.setdefault('mcpServers', {})
servers['operator'] = {
    'type': 'stdio',
    'command': '$MCP_CMD',
    'args': [],
    'env': {}
}
with open('$CONFIG_FILE', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null

        if [ $? -eq 0 ]; then
          echo "  $(basename "$d"): registered ✓"
          REGISTERED=$((REGISTERED + 1))
        else
          echo "  $(basename "$d"): failed ✗"
        fi
      done

      echo ""
      echo "Registered Operator MCP in $REGISTERED config(s)."
      echo "Start the daemon: brew services start operator"
    SH

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
