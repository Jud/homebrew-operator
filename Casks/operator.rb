cask "operator" do
  version "0.1.19"
  sha256 "0533aaa1b515d9f4fbc35bc4d5710cd51bb20d46a4bd8bd2bbe8453df71e7b73"

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
