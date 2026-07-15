cask "operator" do
  version "0.1.11"
  sha256 "bf0bffda62f43649910d9412d0cd9a4aef6194522dd4a652187a8c61c1d277f1"

  url "https://github.com/Jud/operator-releases/releases/download/v#{version}/Operator-#{version}.zip"
  name "Operator"
  desc "Fast, private push-to-talk dictation for macOS"
  homepage "https://hardline.sh"

  auto_updates true            # Sparkle handles in-app updates
  depends_on macos: :sequoia

  app "Operator.app"
  binary "#{appdir}/Operator.app/Contents/MacOS/operator-cli", target: "operator"

  postflight do
    system_command "/usr/bin/xattr", args: ["-rd", "com.apple.quarantine", "#{appdir}/Operator.app"]
  end

  zap trash: ["~/.operator"]
end
