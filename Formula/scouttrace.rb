class Scouttrace < Formula
  desc "Local open-source CLI and MCP proxy for LLM tool-call observability"
  homepage "https://github.com/Applexica/ScoutTrace"
  url "https://github.com/Applexica/ScoutTrace/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "c3c91f73441dfffe323af156136bb71867f83ceba960413547361807699724bc"
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

    raw_key_home = testpath/"raw-key-home"
    raw_key_home.mkpath
    ENV["SCOUTTRACE_DISABLE_KEYCHAIN"] = "1"
    ENV["SCOUTTRACE_ENCFILE_PASSPHRASE"] = "homebrew-test-passphrase"
    raw_key_output = pipe_output(
      "#{bin}/scouttrace --home #{raw_key_home} init",
      "webhookscout\nhttps://api.webhookscout.com\nagent_homebrew_test\nwhs_homebrew_fake_key\nnone\nstrict\ny\n",
    )
    assert_match "stored securely", raw_key_output
    ref_output = shell_output("#{bin}/scouttrace --home #{raw_key_home} config show --json")
    assert_match "encfile://default-api-key", ref_output
    refute_match "whs_homebrew_fake_key", ref_output
  end
end
