cask "operator" do
  version "0.1.1"
  sha256 "7eeb0371588947cf4fdcffa6663a265e088a7fcb5cb5d8b0202d40b09d338662"

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
