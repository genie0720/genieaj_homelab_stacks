{ config, lib, pkgs, ... }:

let
  jwksKey = ''
-----BEGIN PRIVATE KEY-----
private.pem_change_me
-----END PRIVATE KEY-----
  '';

in {

systemd.services.authelia-test.serviceConfig = {
  PrivateTmp = lib.mkForce false;
  ReadWritePaths = [ "/var/lib/authelia-test" ];
  ProtectSystem = lib.mkForce "default";
  ProtectHome = lib.mkForce false;
};


  services.authelia.instances.test = {
    enable = true;

    # Secret files (consider SOPS for secure injection)
    secrets = {
      jwtSecretFile = "/etc/authelia/jwt_secret.txt";
      storageEncryptionKeyFile = "/etc/authelia/encryption_key.txt";
    };

    settings = {
      log = {
        level = "debug";
        format = "text";
      };

      authentication_backend.file.path = "/etc/authelia/users_database.yml";
      theme = "dark";
session.cookies = [
  {
    domain = "yourdomain.net";
    authelia_url = "https://authelia.test.yourdomain.net";
    name = "authelia_test_session";
    inactivity = "30m";
    expiration = "3h";
    remember_me = "1d";
  }
];

      storage.local.path = "/var/lib/authelia-test/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-test/notifications.txt";

      access_control = {
        default_policy = "one_factor";
        rules = [
          {
            domain = ["immich.local.yourdomain.net"];
            policy = "one_factor";
            subject = [["group:users"]];
          }
          {
            domain = ["kuma.local.yourdomain.net"];
            policy = "two_factor";
            subject = [["group:admins"]];
          }
        ];
      };

      # OIDC identity provider configuration
      identity_providers.oidc = {
        hmac_secret = "hmac_secret_changeme";
        jwks = [
          {
            key = jwksKey;

          }
        ];

        clients = [
           {
            client_id = "client_id_changeme";
            client_secret = "client_secret_changeme";
            redirect_uris = [
                   "app.immich:///oauth-callback"
                   "https://immich.local.geniehome.net/auth/login"
                   "https://immich.local.geniehome.net/user-settings"

            ];
            scopes = [ "openid" "profile" "email" ];
            grant_types = [ "authorization_code" ];
            response_types = [ "code" ];
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
      };
    };
  };
}
