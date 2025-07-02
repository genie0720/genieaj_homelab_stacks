{ config, lib, pkgs, ... }:

{
  config = {
    systemd.services.docker-compose = {
      description = "Run Docker Compose for Immich";
      after = [ "network.target" "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";

        # Pull the latest image before running
        ExecStartPre = "/run/current-system/sw/bin/docker compose -f /docker/immich/compose.yaml pull";

        # Bring the service up
        ExecStart = "/run/current-system/sw/bin/docker compose -f /docker/immich/compose.yaml up";

        # Take it down gracefully
        ExecStop = "/run/current-system/sw/bin/docker compose -f /docker/immich/compose.yaml down";

        WorkingDirectory = "/docker/immich";
        Restart = "on-failure";
      };
    };
  };
}
