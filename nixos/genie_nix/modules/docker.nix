{ config, pkgs, ... }:

{
  virtualisation.docker.enable = true;

  # For more isolation, you can use systemd cgroups and enable layers if needed
}
