{
  description = "nixos & home-manager configs by nonplay";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # firefox-beta 148.0b3 — pinned to avoid building from source
    nixpkgs-firefox.url = "github:NixOS/nixpkgs/dd7da344f8e927e961b6772b7562d1aefc086505";

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

    catppuccin.url = "github:catppuccin/nix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    { nixpkgs, catppuccin, ... } @ inputs:
    let
      mkSystem =
        {
          host,
          system,
          base,
          isServer ? false,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${base}/configuration.nix"
            "${base}/machines/${host}"
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
            catppuccin.nixosModules.catppuccin
            { nix.registry.nixpkgs.flake = nixpkgs; }
          ] ++ nixpkgs.lib.optionals (!isServer) [
            {
              home-manager.users.nonplay = {
                imports = [
                  catppuccin.homeModules.catppuccin
                ];
              };
            }
          ];
          specialArgs = {
            inherit inputs host isServer;
          };
        };
    in
    {
      nixosConfigurations = {
        ms-7c56 = mkSystem {
          host = "ms-7c56";
          system = "x86_64-linux";
          base = ./system;
        };
        stockholm = mkSystem {
          host = "stockholm";
          system = "x86_64-linux";
          base = ./server;
          isServer = true;
        };
      };
    };
}
