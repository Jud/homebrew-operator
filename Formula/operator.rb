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

    # Create setup script that auto-registers MCP in all Claude Code configs
    (bin/"operator-setup").write <<~'SETUP'.gsub("%%MCP_CMD%%", "#{bin}/operator-mcp")
      #!/bin/bash
      set -e

      MCP_CMD="%%MCP_CMD%%"
      TOKEN_DIR="$HOME/.operator"
      REGISTERED=0
      SKIPPED=0

      # Generate auth token if needed
      if [ ! -f "$TOKEN_DIR/token" ]; then
        mkdir -p "$TOKEN_DIR"
        chmod 700 "$TOKEN_DIR"
        openssl rand -hex 32 > "$TOKEN_DIR/token"
        chmod 600 "$TOKEN_DIR/token"
        echo "Generated auth token at $TOKEN_DIR/token"
      fi

      # Find all Claude Code config directories by scanning for .claude.json
      # files that contain "numStartups" (Claude Code fingerprint).
      CONFIG_DIRS=()
      while IFS= read -r -d '' config_file; do
        dir="$(dirname "$config_file")"
        if grep -q '"numStartups"' "$config_file" 2>/dev/null; then
          CONFIG_DIRS+=("$dir")
        fi
      done < <(find "$HOME" -maxdepth 2 -name ".claude.json" -print0 2>/dev/null)

      if [ ${#CONFIG_DIRS[@]} -eq 0 ]; then
        echo "No Claude Code configs found."
        echo "Run Claude Code at least once, then re-run: operator-setup"
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
        LABEL="$(basename "$d")"

        # Check if already registered with correct command
        if python3 -c "
import json, sys
with open('$CONFIG_FILE') as f:
    d = json.load(f)
s = d.get('mcpServers', {}).get('operator', {})
if s.get('command') == '$MCP_CMD':
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
          echo "  $LABEL: already registered ✓"
          SKIPPED=$((SKIPPED + 1))
          continue
        fi

        # Add/update MCP server entry
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
"

        if [ $? -eq 0 ]; then
          echo "  $LABEL: registered ✓"
          REGISTERED=$((REGISTERED + 1))
        else
          echo "  $LABEL: failed ✗"
        fi
      done

      echo ""
      if [ $REGISTERED -gt 0 ]; then
        echo "Registered Operator MCP in $REGISTERED config(s)."
      fi
      if [ $SKIPPED -gt 0 ]; then
        echo "$SKIPPED config(s) already up to date."
      fi
      echo ""
      echo "Start the daemon: brew services start operator"
    SETUP

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
