{
  routers.traefik = {
    rule = "Host(`traefik.test.geniehome.net`)";
    entryPoints = [ "websecure" ];
    service = "api@internal";
    middlewares = [
      "default-headers"
      "https-redirect"
      "geniehome-ipwhitelist"
    ];
    tls = {
      certResolver = "cloudflare";
      domains = [
        {
          main = "*.test.geniehome.net";
          sans = [ "test.geniehome.net" ];
        }
      ];
    };
  };

  services = {}; # No external service needed; uses internal API
}
