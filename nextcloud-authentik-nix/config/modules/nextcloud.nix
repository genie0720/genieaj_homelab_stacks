{ pkgs, config, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32; # Use the latest stable version available in nixpkgs
    https = true;
    hostName = "localhost";
    config = {
        adminpassFile = config.sops.secrets."nextcloud-admin-key".path;
        dbtype = "sqlite";
    };
    datadir = "/media/nextcloud";
    settings.trusted_domains = [ "nextcloud.test.geniehome.net" "192.168.20.19" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
}
