cask "operator" do
  version "0.1.8"
  sha256 "5c7ec528ac491d7026fe58aea4f52e3b199c052f0076b33f70507189c7a270fd"

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
