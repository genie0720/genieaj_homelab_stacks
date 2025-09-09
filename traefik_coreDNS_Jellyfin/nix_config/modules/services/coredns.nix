{ config, lib, pkgs, ... }:

let
  zoneFile = ''
    $TTL 2d
    $ORIGIN geniehome.net.

    @       IN  SOA ns.geniehome.net. genieaj.example.com (
                2603201833 ; Serial
                12h        ; Refresh
                15m        ; Retry
                3w         ; Expire
                2h         ; Minimum
              )

            IN  NS  ns.geniehome.net.

    ns         IN  A   192.168.20.115
    *.test     IN  A   192.168.20.115
  '';
in {
  options.genie.dns.enable = lib.mkEnableOption "Enable CoreDNS with geniehome.net zone";

  config = lib.mkIf config.genie.dns.enable {
    services.coredns = {
      enable = true;
      config = ''
    geniehome.net:53 {
      file /etc/coredns/geniehome.zone
      log
      errors
    }

    .:53 {
      acl {
        allow net 192.168.20.0/25
        allow net 192.168.30.0/25
        allow net 192.168.1.0/27
        block net *
      }

      forward . 192.168.20.107
      cache
      log . common
      errors
    }
  '';
    };

    environment.etc."coredns/geniehome.zone".text = zoneFile;
    
  };
}
