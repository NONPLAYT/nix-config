{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;
    mutableUserKeymaps = false;

    extensions = [
      "html"
      "toml"
      "java"
      "dockerfile"
      "vue"
      "macos-classic"
      "kotlin"
      "nix"
      "vscode-icons"
      "biome"
      "mcp-server-github"
      "discord-presence"
    ];

    userSettings = {
      base_keymap = "JetBrains";
      theme = "macOS Classic Dark";
      icon_theme = "VSCode Icons for Zed (Dark)";
      project_panel = {
        dock = "left";
      };
      git_panel = {
        dock = "left";
      };
      agent = {
        dock = "right";
        tool_permissions = {
          default = "allow";
        };
      };
      languages.Nix = {
        formatter.external = {
          command = "nixpkgs-fmt";
          arguments = [ ];
        };
      };
    };

    userKeymaps = [
      {
        context = "Pane";
        bindings = {
          "alt-2" = "git_panel::ToggleFocus";
        };
      }
      {
        context = "Workspace";
        bindings = {
          "alt-2" = "git_panel::ToggleFocus";
        };
      }
      {
        context = "Pane";
        bindings = {
          "alt-1" = "project_panel::ToggleFocus";
        };
      }
      {
        context = "Workspace";
        bindings = {
          "alt-1" = "project_panel::ToggleFocus";
        };
      }
    ];
  };

  home.packages = with pkgs; [
    # lsp servers
    lua-language-server # lua
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
    rustc
    cargo
    go
    nodejs
    ripgrep
    fd
  ];
}
