let
  more =
    { pkgs, lib, ... }:
    {
      programs = {
        bat.enable = true;

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        btop = {
          enable = true;
          package = pkgs.btop.override {
            rocmSupport = true;
          };
          settings = {
            color_theme = "gruvbox_material_dark";
            theme_background = false;
            rounded_corners = true;
            proc_sorting = "cpu direct";
            update_ms = 1000;
          };
        };

        java = {
          enable = true;
          package = pkgs.javaPackages.compiler.temurin-bin.jdk-25;
        };

        command-not-found.enable = false;

        mangohud.enable = true;

        ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              ForwardAgent = false;
              AddKeysToAgent = "240m";
              Compression = false;
              ServerAliveInterval = 0;
              ServerAliveCountMax = 3;
              HashKnownHosts = false;
              UserKnownHostsFile = "~/.ssh/known_hosts";
              ControlMaster = "no";
              ControlPath = "~/.ssh/master-%r@%n:%p";
              ControlPersist = "no";
              IdentityFile = "~/.ssh/ssh.key";
            };
            "stockholm" = {
              HostName = "stockholm.bxteam.org";
              User = "root";
              Port = 2022;
            };
          };
        };
      };
    };
in
[
  ../programs/dconf
  ../programs/git
  ../programs/firefox
  ../programs/zsh
  ../programs/zed
  ../programs/discord-canary
  more
]
