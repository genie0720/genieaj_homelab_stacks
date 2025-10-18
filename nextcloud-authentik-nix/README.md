## NixOS Nextcloud + Authentik Setup

Youtube Walkthrough: https://youtu.be/5Uib-kX8iGc?si=MvPAiV5ghyZqrIfB

NixOS setup for a self-hosted Nextcloud instance using Authentik for OAuth authentication and SOPS for secret management.

Nextcloud is a powerful, self-hosted platform that lets you run your own private cloud. Think of it as your personal alternative to services like Google Drive or Dropbox—but with full control over your data. You can store files, sync calendars and contacts, stream media, and even collaborate with others—all from your own server.

Authentik is an identity provider that handles authentication and access control. In this setup, Authentik is used to provide OAuth login for Nextcloud, which means users can securely sign in using centralized credentials. It’s a great way to manage access across multiple services while keeping everything tightly integrated.

### Prerequisites

Enable flakes and Docker running on your NixOS system.


add this to your configuration.nix
```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```
Authentik runs in containers, so we need Docker enabled.
```
virtualisation.docker.enable = true;
```

## Nextcoud Setup
First up: Nextcloud. I’ve enabled it directly in my NixOS configuration using this module. Here’s the breakdown:

```
{ pkgs, config, ... }:

  

{

  services.nextcloud = {

    enable = true;

    package = pkgs.nextcloud31; # Use the latest stable version available in nixpkgs

    https = true;

    hostName = "localhost";

    config = {

        adminpassFile = config.sops.secrets."nextcloud-admin-key".path;

        dbtype = "sqlite";

    };

    datadir = "/home/nix/nextcloud";

    settings.trusted_domains = [ "nextcloud.test.geniehome.net" "192.168.20.19" ];

  };

  

  networking.firewall.interfaces.allowedTCPPorts = [ 80 443 8080 ];

}
```

using adminpassFile  to pull the admin password from a SOPS-managed secret. This keeps credentials out of my git repo and ensures secure provisioning.


## Authentik Docker Compose systemd service

 running Authentik via Docker Compose, wrapped in a systemd service. This keeps it declarative."

```
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
```
This module ensures that Authentik is automatically pulled, started, and stopped using Docker Compose, all managed by systemd. It integrates Authentik into your NixOS system declaratively, so it starts on boot and restarts on failure.

### Traefik
As with all my services, I’m routing traffic through Traefik, which handles TLS, routing, and service discovery.

## Sops secret creation

include age, and sops in your nix packages.

create age key using the `age-keygen` command. This gives me a private key and a public key I can use for encryption:”

```
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```
Inside that file, you’ll find your identity (private key) and your recipient (public key). I copy the public key and use it to encrypt secrets.”

 create a txt file that has the nextcloud admin password. ideally, youll want to make sure to delete this file BEFORE commiting to your git repository.
 

📦 “Here’s how I encrypted my admin password file using that age key and SOPS:”

```
sops --age <public key> \
     --input-type binary \
     --output-type binary \
     --encrypt admin.txt > nextcloud-admin-key.txt.enc
```

“That command takes my plaintext file, encrypts it using my age identity, and outputs a binary .enc file inside my secrets repository. I can commit that encrypted file to Git, and NixOS decrypts it at build time using my age key.”

verify it encrypted correctly by using this command to decrypt it 

```
sops -d nextcloud-admin-key.txt.enc
```

🔗 “Then in my NixOS config, I reference the decrypted path like this:”

```
adminpassFile = config.sops.secrets."nextcloud-admin-key".path;
```
 “This keeps the password out of the repo and out of memory—only decrypted when needed, and only by the system that’s authorized.”

add to configuration.nix

```
sops = {
  secrets.nextcloud-admin-key = {
    sopsFile = ../../secrets/nextcloud-admin-key.env.enc;
    format = "binary";
    path = "/run/secrets/nextcloud-admin-key";
  };
  age.keyFile = "/home/nix/.config/sops/age/keys.txt";
  gnupg.sshKeyPaths = [];
};
```
include sops-nix in my flake inputs to make this all work declaratively:”

```
sops-nix.url = "github:Mic92/sops-nix";
```

and expose it in my outputs as well 

```
          sops-nix.nixosModules.default
```

lets also update our imports on our configuration.nix and include nextcloud and authentiik module

now we can run a nixos-rebuild switch command and configure authentik.

```
sudo nixos-rebuild switch --flake /home/nix/config#nixtest
```
## Configure Authentik

for authentik intial setup, youll go to this link and create an admin account

```
https://authentik.test.geniehome.net//if/flow/initial-setup/
```

youll log as akadmin. 

before we create the application and provider for nextcloud,  create a user first to use

enter the admin interface

go to directory, users, create

give it a username and name and email, then you can leave the rest the same and click create.

next, we need to set a password for the new user so click on the new user, and click set password

now lets log out and confirm you can log in as new user. 

log back in as akadmin

create the application and provider for nextcloud.

🛠️ Step 1: Create the OAuth2 Provider in Authentik

📍 “In the Authentik admin interface, go to:  
go to applications, and create with provider.

give it a name, and it will autopopulate the slug. 
click next

select oauth2 provider and next

ill leave the name the same and choose an authorization flow.

copy the client id and secret for use later.

leave everything else the same and click next

next again and click submit


## Configure Nextcloud

 log in as root first and youll use the password that we created earlier and had encrypted with sops

install the Social Login app from the Nextcloud app store.  go to apps social and communication, and look for social login

click download and enable

Once that’s done, head to:

Administration → Social Login → Custom OAuth2”

🧩 “Now let’s fill in the details for our Authentik provider:”
• 	Internal Name: Authentik
• 	Title: This is what users will see on the login button.

- API Base URL - `https://authentik.test.geniehome.net/application/o/
- **Authorize URL** - `  https://authentik.test.geniehome.net/application/o/authorize/`
- Token URL - `https://authentik.test.geniehome.net/application/o/token/`
- **Profile URL** - `https://authentik.test.geniehome.net/application/o/userinfo/`
• 	Client ID: Paste the one from your Authentik provider
• 	Client Secret: Same—copy it from Authentik

✅ “Once that’s saved, you should see a new login option on your Nextcloud login screen: Login with Authentik.

When you log in through Authentik for the first time, Nextcloud will automatically create a new user based on the identity information returned by Authentik. It’s seamless and secure.
