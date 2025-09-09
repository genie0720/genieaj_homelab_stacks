{ config, pkgs, lib, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "jellyfin";
    group = "jellyfin";
  };

  # Bind Jellyfin to isolated subnet IP
  environment.etc."jellyfin/network.json".text = builtins.toJSON {
    host = "192.168.20.115";
    port = 8096;
    protocol = "http";
  };

  # Firewall scoped to correct NIC
  networking.firewall.allowedTCPPorts = [ 8096 ];
}
