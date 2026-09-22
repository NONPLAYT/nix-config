{ inputs, pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
    enableMcpIntegration = true;
    skills.handoff = ./skills/handoff/SKILL.md;
    settings = {
      permissions = {
        defaultMode = "bypassPermissions";
      };
      model = "opus";
      spinnerTipsEnabled = false;
      promptSuggestionEnabled = false;
      awaySummaryEnabled = false;
      remoteControlAtStartup = false;
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      theme = "dark";
    };
    mcpServers = {
      nuxt = {
        type = "http";
        url = "https://nuxt.com/mcp";
      };
      cloudflare = {
        type = "http";
        url = "https://mcp.cloudflare.com/mcp";
      };
      rbxstudio = {
        command = "/home/nonplay/.var/app/org.vinegarhq.Vinegar/data/vinegar/kombucha-stable+20260614215204/bin/wine";
        args = [ "/home/nonplay/.var/app/org.vinegarhq.Vinegar/data/vinegar/versions/version-55808de4b1914919/StudioMCP.exe" ];
        env = {
          WINEPREFIX = "/home/nonplay/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio";
        };
      };
    };
  };
}
