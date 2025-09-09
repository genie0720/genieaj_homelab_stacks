{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    sops-nix.url = "github:Mic92/sops-nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

  };

  outputs = { self, nixpkgs, nixpkgs-stable, sops-nix, vscode-server, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {

    # NixOS system configurations
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          inputs.sops-nix.nixosModules.sops
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })

        ];
      };
    };
  };
}
