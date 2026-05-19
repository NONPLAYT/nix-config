{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      edit_predictions = {
        provider = "zed";
      };

      agent_servers = {
        github-copilot-cli = {
          type = "registry";
        };
        claude-acp = {
          default_config_options = {
            mode = "bypassPermissions";
          };
          type = "registry";
        };
      };

      context_servers = {
        nuxt = {
          enabled = true;
          url = "https://nuxt.com/mcp";
        };
      };

      autosave = "off";
      buffer_font_family = "JetBrains Mono";

      project_panel = {
        dock = "left";
      };

      outline_panel = {
        dock = "left";
      };

      collaboration_panel = {
        dock = "left";
      };

      agent = {
        default_model = {
          provider = "zed.dev";
          model = "claude-sonnet-4-6";
          enable_thinking = true;
          effort = "high";
        };
        dock = "right";
        favorite_models = [ ];
        model_parameters = [ ];
      };

      git_panel = {
        dock = "left";
      };

      base_keymap = "JetBrains";
      icon_theme = "VSCode Icons for Zed (Dark)";
      ui_font_size = 16.0;
      buffer_font_size = 13.0;

      theme = {
        mode = "dark";
        light = "Ayu Light";
        dark = "macOS Classic Dark";
      };

      language_servers = [ "!eslint" "..." ];
    };
  };
  home.packages = with pkgs; [
    # lsp servers
    typescript-language-server # ts/js
    vscode-langservers-extracted # html, css, js
    tailwindcss-language-server # tailwind
    vue-language-server # vue
    rust-analyzer # rust
    gopls # go
    clang-tools # clang
    basedpyright # python
    nil # nix
    nixd
    yaml-language-server # yaml

    # formatters
    stylua # lua
    prettierd # web
    black # python
    isort # python improrts
    nixpkgs-fmt # nix (less aggressive than nixfmt-rfc-style)
    shfmt # shell

    gcc
    gnumake
    cmake
    nodejs
    ripgrep
    fd
  ];
}
