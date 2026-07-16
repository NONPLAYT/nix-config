{
  description = "nixos & home-manager configs by nonplay";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://zed.cachix.org"
      "https://bx-team.cachix.org"
      "https://ayugram-desktop.cachix.org"
      "https://wrangler.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "bx-team.cachix.org-1:tnGNc1rsS8QOav+VGxXCZzf/Y0/SGchOwVCCBA/eG6E="
      "ayugram-desktop.cachix.org:AZ5EqHrJsAKL5YkZYLPEsb1FdD9QlypUwQ0REcJftgA="
      "wrangler.cachix.org-1:N/FIcG2qBQcolSpklb2IMDbsfjZKWg+ctxx0mSMXdSs="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:NixOS/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrangler = {
      url = "github:emrldnix/wrangler";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nsticky = {
      url = "github:lonerOrz/nsticky";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nexon.url = "github:BX-Team/Nexon";

    ayugram-desktop = {
      type = "git";
      submodules = true;
      url = "https://github.com/ndfined-crp/ayugram-desktop";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      overlays = [
        inputs.nur.overlays.default
      ];

      mkSystem =
        { host
        , system
        , base
        ,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (base + "/configuration.nix")
            (base + "/machines/${host}")
            ./secrets
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
            inputs.sops-nix.nixosModules.sops
            inputs.nix-flatpak.nixosModules.nix-flatpak
            { nix.registry.nixpkgs.flake = nixpkgs; }
            { nixpkgs.overlays = overlays; }
          ];
          specialArgs = {
            inherit inputs host;
            isServer = base == ./server;
          };
        };
    in
    {
      nixosConfigurations = {
        home = mkSystem {
          host = "home";
          system = "x86_64-linux";
          base = ./system;
        };
        finland = mkSystem {
          host = "finland";
          system = "x86_64-linux";
          base = ./server;
        };
        moscow = mkSystem {
          host = "moscow";
          system = "x86_64-linux";
          base = ./server;
        };
      };
    };
}
