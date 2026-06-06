{
  description = "nixos & home-manager configs by nonplay";

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

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nsticky = {
      url = "github:lonerOrz/nsticky";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      overlays = [
        inputs.nur.overlays.default
        inputs.claude-code-nix.overlays.default
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
        stockholm = mkSystem {
          host = "stockholm";
          system = "x86_64-linux";
          base = ./server;
        };
      };
    };
}
