let
  scripts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      proxy-status = pkgs.callPackage ./proxy-status.nix { };
      proxy-switch = pkgs.callPackage ./proxy-switch.nix { };
      proxy-profile-switch = pkgs.callPackage ./proxy-profile-switch.nix { };
    in
    {
      home.packages = [
        proxy-status
        proxy-switch
        proxy-profile-switch
      ];
    };
in
[ scripts ]
