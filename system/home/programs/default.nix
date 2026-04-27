let
  more =
    { config, pkgs, ... }:
    {
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
        ((pkgs.jetbrains.idea.override {
          vmopts = ''
            -Dawt.toolkit.name=WLToolkit
            -Xms512m
            -Xmx8192m
            -javaagent:/home/nonplay/.local/share/ja-netfilter/ja-netfilter.jar=jetbrains
          '';
        }).overrideAttrs (oldAttrs: {
          src = pkgs.fetchurl {
            url = builtins.replaceStrings
              [ "download.jetbrains.com" ]
              [ "download-cf.jetbrains.com" ]
              (oldAttrs.src.url or "");
            inherit (oldAttrs.src) outputHash outputHashAlgo;
          };
        }))
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
