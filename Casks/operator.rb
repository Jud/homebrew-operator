cask "operator" do
  version "0.1.2"
  sha256 "2c5fb352c4b81315450fea94edecf36979408d38fb3542a2b3f517de17081d99"

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
