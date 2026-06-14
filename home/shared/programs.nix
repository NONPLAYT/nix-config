let
  more =
    { pkgs, ... }:
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
            color_theme = "tokyo_storm";
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

        obs-studio = {
          enable = true;
          plugins = with pkgs.obs-studio-plugins; [
            obs-pipewire-audio-capture
          ];
        };

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
              IdentityFile = "/run/secrets/home/ssh/key";
              IdentitiesOnly = true;
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
  ../programs/claude
  ../programs/dconf
  ../programs/easyeffects
  ../programs/fastfetch
  ../programs/firefox
  ../programs/git
  ../programs/zed
  ../programs/zsh
  more
]
