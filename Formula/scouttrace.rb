class Scouttrace < Formula
  desc "Local open-source CLI and MCP proxy for LLM tool-call observability"
  homepage "https://github.com/Applexica/ScoutTrace"
  url "https://github.com/Applexica/ScoutTrace/archive/refs/tags/v0.1.13.tar.gz"
  sha256 "b57d23c543b14b247cf85e0ff64fd34b827199c6f1694249c3f8ffc76c530c7e"
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

    hook_project = testpath/"hook-project"
    hook_project.mkpath
    hook_home = testpath/"hook-home"
    hook_home.mkpath
    shell_output("#{bin}/scouttrace --home #{hook_home} init --hosts none --destination stdout --yes")
    hook_transcript = testpath/"claude-transcript.jsonl"
    hook_transcript.write <<~JSONL
      {"type":"assistant","message":{"model":"claude-opus-4-7","usage":{"input_tokens":1,"cache_creation_input_tokens":999,"output_tokens":10}}}
    JSONL
    hook_payload = <<~JSON
      {"session_id":"s","hook_event_name":"PostToolUse","transcript_path":"#{hook_transcript}","tool_name":"mcp__playwright__browser_navigate","tool_input":{"url":"https://example.com"},"tool_response":{"ok":true}}
    JSON
    hook_output = pipe_output(
      "#{bin}/scouttrace --home #{hook_home} --json claude-hook post-tool-use --destination default",
      hook_payload,
    )
    assert_match "default", hook_output
    assert_match "llm_turn_count", hook_output
    shell_output(
      "#{bin}/scouttrace --home #{hook_home} claude-hook install " \
      "--scope local --project-dir #{hook_project} --destination default",
    )
    assert_match "claude-hook post-tool-use", (hook_project/".claude/settings.local.json").read
    assert_match "claude-hook stop", (hook_project/".claude/settings.local.json").read

    codex_home = testpath/"codex-home"
    codex_home.mkpath
    codex_config = testpath/"codex-config.toml"
    codex_config.write <<~TOML
      [mcp_servers.filesystem]
      command = "npx"
      args = ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    TOML
    shell_output("#{bin}/scouttrace --home #{codex_home} hosts patch --host codex --config-path #{codex_config}")
    assert_match "scouttrace", codex_config.read
    shell_output("#{bin}/scouttrace --home #{codex_home} hosts unpatch --host codex --config-path #{codex_config}")
    assert_match "command = \"npx\"", codex_config.read

    hermes_home = testpath/"hermes-home"
    hermes_home.mkpath
    hermes_config = testpath/"hermes-config.yaml"
    hermes_config.write <<~YAML
      mcp_servers:
        filesystem:
          command: npx
          args:
            - "-y"
            - "@modelcontextprotocol/server-filesystem"
            - "/tmp"
    YAML
    shell_output("#{bin}/scouttrace --home #{hermes_home} hosts patch --host hermes --config-path #{hermes_config}")
    assert_match "scouttrace", hermes_config.read
    shell_output("#{bin}/scouttrace --home #{hermes_home} hosts unpatch --host hermes --config-path #{hermes_config}")
    assert_match "command: npx", hermes_config.read
  end
end
