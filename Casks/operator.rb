cask "operator" do
  version "0.1.0"
  sha256 "d7746ac2f579dd54743ff77fc36f00feda9e3fd01fd3e1c86f68c5a5ac024eec"

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
