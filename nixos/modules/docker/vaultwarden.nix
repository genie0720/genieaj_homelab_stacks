{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers.containers.vault = {
    image = "vaultwarden/server:latest";
    hostname = "vaultwarden";
    environmentFiles = [ "/swarm/vaultwarden/.env" ];
    networks = [ "traefik" ];
    # ports = [
    # "3001:3001"
    #];

    volumes = [
      #"/var/run/docker.sock:/var/run/docker.sock"
      "/swarm/vaultwarden/log:/data/log"
      "/swarm/vaultwarden/vw-data:/data"
    ];

  };
}% 
