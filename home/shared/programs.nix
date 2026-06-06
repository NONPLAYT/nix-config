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
          matchBlocks = {
            "*" = {
              forwardAgent = false;
              addKeysToAgent = "240m";
              compression = false;
              serverAliveInterval = 0;
              serverAliveCountMax = 3;
              hashKnownHosts = false;
              userKnownHostsFile = "~/.ssh/known_hosts";
              controlMaster = "no";
              controlPath = "~/.ssh/master-%r@%n:%p";
              controlPersist = "no";
              identityFile = [ "~/.ssh/ssh.key" ];
            };
            "stockholm" = {
              hostname = "stockholm.bxteam.org";
              user = "root";
              port = 2022;
              identityFile = [ "~/.ssh/ssh.key" ];
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
