let
  more =
    { config, pkgs, ... }:
    {
      nixpkgs.config.packageOverrides = prev: {
        jetbrains = prev.jetbrains // {
          idea = prev.jetbrains.idea.overrideAttrs (oldAttrs: 
            let
              origUrl = oldAttrs.src.url or "";
              newUrl = builtins.replaceStrings 
                ["download.jetbrains.com"] 
                ["download-cf.jetbrains.com"] 
                origUrl;
            in {
              src = prev.fetchurl {
                url = newUrl;
                hash = oldAttrs.src.outputHash;
              };
            });
        };
      };

      programs = {
        jq.enable = true;
        gpg.enable = true;
        htop = {
          enable = true;
          settings = {
            sort_direction = true;
            sort_key = "PERCENT_CPU";
          };
        };
      };

      home.packages = [
        (pkgs.jetbrains.idea.override {
          vmopts = ''
            -Dawt.toolkit.name=WLToolkit
            -Xms512m
            -Xmx8192m
            -javaagent:/home/nonplay/.local/share/ja-netfilter/ja-netfilter.jar=jetbrains
          '';
        })
      ];
    };
in
[
  ./albert
  ./dconf
  ./fastfetch
  ./firefox
  ./git
  ./kitty
  ./noctalia
  ./zsh
]
++ [ more ]
