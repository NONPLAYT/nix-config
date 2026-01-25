let
  scripts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      pactl-listner = pkgs.callPackage ./pactl-listner.nix { };
      proxy-status = pkgs.callPackage ./proxy-status.nix { };
      proxy-switch = pkgs.callPackage ./proxy-switch.nix { };
      proxy-profile-switch = pkgs.callPackage ./proxy-profile-switch.nix { };
    in
    {
      home.packages = [
        pactl-listner
        proxy-status
        proxy-switch
        proxy-profile-switch
      ];
    };
in
[ scripts ]
