{
  description = "nixos & home-manager configs by nonplay";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    { nixpkgs, catppuccin, ... } @ inputs:
    let
      mkSystem =
        { host, system, base }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${base}/configuration.nix"
            "${base}/machines/${host}"
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
            catppuccin.nixosModules.catppuccin
            {
              home-manager.users = {
                nonplay = {
                  imports = [
                    catppuccin.homeManagerModules.catppuccin
                  ];
                };
              };
            }
            { nix.registry.nixpkgs.flake = nixpkgs; }
          ];
          specialArgs = { inherit inputs host; };
        };
    in
    {
      nixosConfigurations = {
        ms-7c56 = mkSystem {
          host = "ms-7c56";
          system = "x86_64-linux";
          base = ./system;
        };
      };
    };
}