class Scouttrace < Formula
  desc "Local open-source CLI and MCP proxy for LLM tool-call observability"
  homepage "https://github.com/Applexica/ScoutTrace"
  url "https://github.com/Applexica/ScoutTrace/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "715bf8f74e0f7b1584ae7c1c029d7538fc0505d8b13f3fab7790b08157f4c4fc"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/webhookscout/scouttrace/internal/version.Version=#{version}"
    system "go", "build", "-ldflags", ldflags, "-o", bin/"scouttrace", "./cmd/scouttrace"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/scouttrace version")
    assert_match "scouttrace", shell_output("#{bin}/scouttrace --help")

    test_home = testpath/"home"
    test_home.mkpath
    ENV["SCOUTTRACE_HOME"] = test_home.to_s
    output = shell_output(
      "#{bin}/scouttrace init --hosts none --destination stdout --yes --dry-run",
    )
    assert_match "default_destination", output
  end
end
