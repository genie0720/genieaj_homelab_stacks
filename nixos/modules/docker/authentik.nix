{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers.containers = {
    postgresql = {
      image = "docker.io/library/postgres:16-alpine";
      networks = [ "authentik" ];
      hostname = "postgresql";
      environmentFiles = [ "/swarm/authentik/.env" ];
      volumes = [
        "/swarm/authentik/postgres:/var/lib/postgresql/data"
      ];
    };

    redis = {
      image = "docker.io/library/redis:alpine";
      networks = [ "authentik" ];
      cmd = ["--save 60 1" "--loglevel warning" ];
      environmentFiles = [ "/swarm/authentik/.env" ];
      volumes = [
        "/swarm/authentik/redis:/data"
      ];
    };

    authentik-server = {
      image = "ghcr.io/goauthentik/server:latest";
      hostname = "authentik";
      networks = [ "traefik" "authentik" ];
      cmd = [ "server" ];
      environmentFiles = [ "/swarm/authentik/.env" ];
      volumes = [
        "/swarm/authentik/media:/media"
        "/swarm/authentik/custom-templates:/templates"
      ];
    };

    authentik-worker = {
      image = "ghcr.io/goauthentik/server:latest";
      networks = [ "authentik" ];
      cmd = [ "worker" ];
      user = "root";
      environmentFiles = [ "/swarm/authentik/.env" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/swarm/authentik/media:/media"
        "/swarm/authentik/certs:/certs"
        "/swarm/authentik/custom-templates:/templates"
      ];
    };
  };
}%
