{ inputs, pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
    enableMcpIntegration = true;
    settings = {
      permissions = {
        defaultMode = "bypassPermissions";
      };
      model = "opus";
      spinnerTipsEnabled = false;
      promptSuggestionEnabled = false;
      awaySummaryEnabled = false;
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      theme = "dark";
    };
    mcpServers = {
      nuxt = {
        type = "http";
        url = "https://nuxt.com/mcp";
      };
    };
  };
}
