class Scouttrace < Formula
  desc "Local open-source CLI and MCP proxy for LLM tool-call observability"
  homepage "https://github.com/Applexica/ScoutTrace"
  url "https://github.com/Applexica/ScoutTrace/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "24fba34d9b12ca4f0137fba89d8605a35db3e1c56556435b07dfab43928347c7"
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

    interactive_home = testpath/"interactive-home"
    interactive_home.mkpath
    interactive = pipe_output(
      "#{bin}/scouttrace --home #{interactive_home} init",
      "stdout\nnone\nstrict\ny\n",
    )
    assert_match "ScoutTrace setup wizard", interactive
    assert_match "Wrote", interactive
  end
end
