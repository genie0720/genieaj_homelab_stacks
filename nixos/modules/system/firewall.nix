{ config, pkgs, lib, hostName, openTCPPorts ? [], openUDPPorts ? [], ... }:

{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = openTCPPorts;

    allowedUDPPorts = openUDPPorts;

    # Optional: Turn on logging based on hostname or config
    #logRefusedConnections = lib.mkIf (hostName == "nix03") true;
  };
}
