{ config, lib, pkgs, ... }:

{
  config = {
    systemd.services.immich = {
      description = "Run Docker Compose for Immich";
      after = [ "network.target" "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";

        # Pull the latest image before running
        ExecStartPre = "/run/current-system/sw/bin/docker compose -f /swarm/immich/compose.yaml pull";

        # Bring the service up
        ExecStart = "/run/current-system/sw/bin/docker compose -f /swarm/immich/compose.yaml up";

        # Take it down gracefully
        ExecStop = "/run/current-system/sw/bin/docker compose -f /swarm/immich/compose.yaml down";

        WorkingDirectory = "/swarm/immich";
        Restart = "on-failure";
      };
    };
  };
}
