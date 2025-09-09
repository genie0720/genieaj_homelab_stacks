{ config, lib, pkgs, ... }:

let
  serviceModules = builtins.attrValues (
    lib.mapAttrs (name: _: import (./traefik-hosts + "/${name}"))
      (lib.filterAttrs (_: type: type == "regular") (builtins.readDir ./traefik-hosts))
  );

  mergedRouters = lib.mkMerge (map (m: m.routers) serviceModules);
  mergedServices = lib.mkMerge (map (m: m.services) serviceModules);
in
{
  services.traefik = {
    enable = true;
    environmentFiles = [ config.sops.secrets.traefik_env.path ];

    staticConfigOptions = {
      serversTransport.insecureSkipVerify = true;

      entryPoints = {
        web = {
          address = ":80";
          asDefault = true;
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          asDefault = true;
          http.tls.certResolver = "cloudflare";
        };
      };

      certificatesResolvers.cloudflare.acme = {
        email = "$CF_API_EMAIL";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          delayBeforeCheck = 0;
          resolvers = [ "1.1.1.1:53" "1.0.0.1:53" ];
        };
      };

      log = {
        level = "INFO";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };

      accessLog = {
        filePath = "${config.services.traefik.dataDir}/access.log";
        format = "json";
        bufferingSize = 100;
        fields = {
          defaultMode = "keep";
          headers = {
            defaultMode = "keep";
            names = {
              "X-Forwarded-For" = "keep";
              "CF-Connecting-IP" = "keep";
            };
          };
        };
      };
