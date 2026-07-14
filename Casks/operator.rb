cask "operator" do
  version "0.1.3"
  sha256 "725b0dca7395d8d2403e40eac344e48db65d1cda4a6a23c2ae5e859c9e5448cd"

  url "https://github.com/Jud/operator-releases/releases/download/v#{version}/Operator-#{version}.zip"
  name "Operator"
  desc "Talk to your terminal: fast, local, minimal voice for terminal agents"
  homepage "https://hardline.sh"

  auto_updates true            # Sparkle handles in-app updates
  depends_on macos: ">= :sequoia"

  app "Operator.app"
  binary "#{appdir}/Operator.app/Contents/MacOS/operator-cli", target: "operator"

  postflight do
    system_command "/usr/bin/xattr", args: ["-rd", "com.apple.quarantine", "#{appdir}/Operator.app"]
  end

  zap trash: ["~/.operator"]
end
