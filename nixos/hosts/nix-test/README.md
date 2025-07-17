## Enable Flakes and SSH

ON MACHINE YOU WANT TO REMOTELY ACCESS: Navigate to /etc/nixos
Add the following lines to your `configuration.nix` file:

```
  # Enable the OpenSSH daemon.
  services.openssh = {
  enable = true;
  permitRootLogin = "yes"; # or "prohibit-password" if you prefer key-only logins
  passwordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMyaA0FK6e56QGOlleGGVdeUHOwRV22JXw0Dd0zo5Jd"
  ];


  nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Run the command:

```
sudo nixos-rebuild switch
```

## Create Directories on Main NixOS System / Update configuration.nix and flake.nix

ON MAIN NIXOS MACHINE (NOT REMOTE) create a new directory under `hosts` called `nix-test`. Inside this folder, copy over a `configuration.nix` file and a `hardware-confiuration.nix` file.

run command to push updates to remote nix machine:

```
sudo nixos-rebuild switch --flake .#nixtest --target-host root@{IP-ADDRESS}
```
replace IP-ADDRESS with IP address of remote machine.

.#nixtest is the name of configuration block in you flake.nix file 

```
nixtest = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
           hostName = "nixtest";
          # sshUser = "nix";
           openTCPPorts = [ 22 2377 7946 ];
           openUDPPorts = [ 2377 7946 4789 ];
        };
        modules = [
          ./hosts/nix-test/configuration.nix
          inputs.home-manager.nixosModules.default
          {
            home-manager.users.nix = import ./home.nix;
            home-manager.backupFileExtension = "hm-bak";
          }
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };
```

