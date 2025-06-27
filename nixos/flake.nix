{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, home-manager, nixpkgs, vscode-server, agenix, ... }@inputs: {

    nixosConfigurations.nix01 = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nix-01/configuration.nix
        inputs.home-manager.nixosModules.default
        agenix.nixosModules.default
        {
          home-manager.users.nix = import ./hosts/nix-01/home.nix;
          home-manager.backupFileExtension = "hm-bak";
        }
        vscode-server.nixosModules.default
        ({ config, pkgs, ... }: {
          services.vscode-server.enable = true;
        })
      ];
    };

    nixosConfigurations.nix02 = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nix-02/configuration.nix
        inputs.home-manager.nixosModules.default
        agenix.nixosModules.default
        {
          home-manager.users.nix = import ./hosts/nix-02/home.nix;
          home-manager.backupFileExtension = "hm-bak";
        }
        vscode-server.nixosModules.default
        ({ config, pkgs, ... }: {
          services.vscode-server.enable = true;
        })
      ];
    };

    nixosConfigurations.nix03 = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nix-03/configuration.nix
        ./modules/docker_compose/immich.nix
        ./modules/docker_compose/crowdsec.nix
        inputs.home-manager.nixosModules.default
        agenix.nixosModules.default
        {
          home-manager.users.nix = import ./hosts/nix-03/home.nix;
          home-manager.backupFileExtension = "hm-bak";
        }
        vscode-server.nixosModules.default
        ({ config, pkgs, ... }: {
          services.vscode-server.enable = true;
        })
      ];
    };

  };
}
