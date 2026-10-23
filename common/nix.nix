{ lib, ... }:

{
  nix = {
    optimise.automatic = true;

    settings = {
      trusted-users = [ "root" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://bx-team.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "bx-team.cachix.org-1:tnGNc1rsS8QOav+VGxXCZzf/Y0/SGchOwVCCBA/eG6E="
      ];
    };
  };

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = lib.mkDefault "24.11";
}
