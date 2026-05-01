class Scouttrace < Formula
  desc "Local open-source CLI and MCP proxy for LLM tool-call observability"
  homepage "https://github.com/Applexica/ScoutTrace"
  url "https://github.com/Applexica/ScoutTrace/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "b6e80d490edcb7d16aa1b51727ab2f526d12d796ea69b06881925a6d3c7993d7"
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
    output = shell_output("SCOUTTRACE_HOME=#{test_home} #{bin}/scouttrace init --hosts none --destination stdout --yes --dry-run")
    assert_match "dry", output.downcase
  end
end
