cask "operator" do
  version "0.1.2"
  sha256 "f37343194bdb40967d7d13afa5f339b5801ae4b427920766b58d7ebb8674f075"

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
