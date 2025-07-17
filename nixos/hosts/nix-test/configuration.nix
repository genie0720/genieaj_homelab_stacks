{config, pkgs, lib, inputs, ... }:

{
  imports = [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # System core modules
      ../../modules/base.nix
      ../../modules/system/ssh.nix
      ../../modules/system/firewall.nix
      # ../../modules/system/swarm_mount.nix

      # User and Homemanager modules
      ../../modules/users/nix.nix
      inputs.home-manager.nixosModules.default
      
      # Docker and Docker Compose modules
      # ../../modules/docker_compose/homarr.nix
      # ../../modules/docker/joplin.nix
      # ../../modules/docker_compose/ntfy.nix
      # ../../modules/docker/kuma.nix
      # ../../modules/docker/vault.nix
      # ../../modules/docker_compose/periphery.nix
      # ../../modules/docker_compose/mattermost.nix
      #../../modules/docker_compose/video_call.nix
      
  ];

  # Define the system hostname
  networking.hostName = "nix-test";

} 
