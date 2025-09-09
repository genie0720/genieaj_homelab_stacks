{
  routers.jellyfin = {
    rule = "Host(`jellyfin.test.geniehome.net`)";
    entryPoints = [ "websecure" ];
    service = "jellyfin";
    tls.certResolver = "cloudflare";
  };

  services.jellyfin.loadBalancer = {
    passHostHeader = true;
    servers = [
      { url = "http://192.168.20.115:8096"; }
    ];
  };
}
