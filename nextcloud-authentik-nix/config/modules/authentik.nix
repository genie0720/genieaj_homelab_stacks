{ config, lib, pkgs, ... }:

{
  config = {
    systemd.services.authentik = {
      description = "Run Docker Compose for authentik";
      after = [ "network.target" "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";

        # Pull the latest image before running
        ExecStartPre = "/run/current-system/sw/bin/docker compose -f /home/nix/docker/authentik/compose.yaml pull";

        # Bring the service up
        ExecStart = "/run/current-system/sw/bin/docker compose -f /home/nix/docker/authentik/compose.yaml up";

        # Take it down gracefully
        ExecStop = "/run/current-system/sw/bin/docker compose -f /home/nix/docker/authentik/compose.yaml down";

        WorkingDirectory = "/home/nix/docker/authentik";
        Restart = "on-failure";
      };
    };
  };
}
