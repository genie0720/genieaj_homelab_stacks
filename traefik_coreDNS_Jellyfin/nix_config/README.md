# Traefik + CoreDNS + Jellyfin on NixOS

This stack documents how I bootstrap a fresh NixOS host, enable SSH and flakes, set up SOPS + age for secrets, and scaffold a clean module layout for Traefik, CoreDNS, and Jellyfin.

The goal: a reproducible, modular homelab foundation that’s easy to extend and maintain.

---

## 🧱 Step 1: Fresh NixOS Install + SSH Access

Starting from a clean NixOS install, I enable SSH so I can manage the server remotely. I’m also enabling flakes and adding `sops` and `age` to my system packages.

- SOPS (Secrets OPerationS) is a CLI for managing encrypted YAML/JSON/ENV files. We’ll use it later with `sops-nix` to manage secrets declaratively.
- age is a modern, minimal encryption tool with compact key pairs—great for infra workflows and pairs well with SOPS.

In `configuration.nix`, I uncomment:

```nix
services.openssh.enable = true;
```

and add:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

I also add `sops` and `age` to system packages:

```nix
environment.systemPackages = with pkgs; [
  sops
  age
];
```

Rebuild:

```bash
sudo nixos-rebuild switch
```

Now I can SSH in:

```bash
ssh nix@my-server-ip
```

---

## 📁 Directory Structure

Once I’m in, I set up a clean directory structure for my Nix configs. I keep a top-level folder `~/nix-config`.

I copy my `hardware-configuration.nix` and `configuration.nix` into the top-level—these are the base of the system setup.

Then I create a `modules` directory with a `services` subfolder to house service-specific modules (Traefik, CoreDNS, Jellyfin). Inside `services`, I keep host-specific Traefik configs in `traefik-hosts/` to stay modular and scalable.

Create the structure:

```bash
mkdir -p ~/nix_config/modules/services/traefik-hosts
touch ~/nix_config/modules/services/traefik.nix
touch ~/nix_config/modules/services/jellyfin.nix
touch ~/nix_config/modules/services/traefik-hosts/jellyfin.nix
```

Resulting layout:

```
~/nix_config
├─ configuration.nix
├─ hardware-configuration.nix
└─ modules
   └─ services
      ├─ traefik.nix
      ├─ jellyfin.nix
      └─ traefik-hosts
         └─ jellyfin.nix
```

Notes:
- `modules/services/traefik.nix`: Traefik service and global config.
- `modules/services/jellyfin.nix`: Jellyfin service config.
- `modules/services/traefik-hosts/jellyfin.nix`: Host-specific router/service definitions for Jellyfin via Traefik.
- CoreDNS will be added alongside these (e.g., `modules/services/coredns.nix`) in a later step.

---

## 🔗 Wiring modules into configuration.nix

If you’re using a traditional (non-flake) setup, you can import your modules like this:

```nix
# configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/services/traefik.nix
    ./modules/services/jellyfin.nix
    # ./modules/services/coredns.nix      # (add when ready)
    # ./modules/services/traefik-hosts/jellyfin.nix
  ];

  # ...rest of your config
}
```

If you’re using flakes, reference these from `flake.nix` under your system’s `modules = [ ... ]`.

---

## ✅ Rebuild Cycle

After each change:

```bash
sudo nixos-rebuild switch
```

If using flakes:

```bash
sudo nixos-rebuild switch --flake .
```

---

## flake.nix

Let’s break down the `flake.nix` that powers this NixOS configuration.

We define inputs (external sources the flake depends on):
- `nixpkgs`: from nixos-unstable — handy for fresh packages
- `nixpkgs-stable`: pinned to 25.05 for mixing stable where needed
- `sops-nix`: module to manage secrets securely with SOPS

In `outputs`, we produce a NixOS configuration. We target `x86_64-linux`, import `nixpkgs` for that system, and define a host called `nixos` via `nixpkgs.lib.nixosSystem`. We pass `specialArgs` so modules can access inputs (e.g., `sops-nix`). The `modules` list includes:
- `configuration.nix`: main system config
- `sops-nix.nixosModules.sops`: wires in SOPS support for secret management

This gives a clean, reproducible NixOS system with built-in support for encrypted secrets—ready to scale, share, and deploy.

Example:

```nix
# flake.nix
{
  description = "NixOS: Traefik + CoreDNS + Jellyfin with SOPS-managed secrets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, sops-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs nixpkgs nixpkgs-stable sops-nix; };
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
}
```

Build/apply:

```bash
sudo nixos-rebuild switch --flake .
```

---

## Traefik module (modules/services/traefik.nix)

I import all host definitions from `modules/services/traefik-hosts`. Each host (e.g., Jellyfin) gets its own file. I use `builtins.readDir` and `lib.mapAttrs` to import them dynamically, then merge routers/services with `lib.mkMerge`.

I use `sops-nix` to manage secrets securely. `environmentFiles` pulls in a decrypted `.env` at runtime, so Traefik can access the Cloudflare API token and email without storing them in plaintext.

- Entrypoints:
  - `web` (80) redirects to HTTPS
  - `websecure` (443) terminates TLS

- ACME: Cloudflare DNS challenge for automatic certificates for internal domains
- Logging:
  - Access log and JSON logs with key headers (`X-Forwarded-For`, `CF-Connecting-IP`, `X-Real-IP`)
  - Buffered for performance

- Security middlewares:
  - `default-headers`: HSTS, XSS protection, frame deny
  - `https-redirect`: force HTTPS
  - `geniehome-ipwhitelist`: restrict to trusted subnets
  - `primary`: chain of the above for easy reuse

- Dynamic routing:
  - Merged routers/services from host modules

- Firewall:
  - Open TCP 80/443

Example:

```nix
# modules/services/traefik.nix
{ config, lib, pkgs, ... }:

let
  hostsDir = ./traefik-hosts;

  hostFiles = lib.filter (name: lib.hasSuffix ".nix" name)
    (builtins.attrNames (builtins.readDir hostsDir));

  importedHosts =
    map (name: import (hostsDir + "/${name}") { inherit lib; })
      hostFiles;

  mergedRouters = lib.mkMerge (map (m: m.routers or {}) importedHosts);
  mergedServices = lib.mkMerge (map (m: m.services or {}) importedHosts);
in
{
  services.traefik = {
    enable = true;

    # Pick up secrets from sops-nix at runtime
    environmentFiles = lib.optionals (config ? sops.secrets.traefik_env) [
      config.sops.secrets.traefik_env.path
    ];

    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      api = {
        dashboard = true;
        debug = false;
        insecure = false; # Expose via a secure router instead (see dashboard module)
      };

      entryPoints = {
        web = {
          address = ":80";
          http = {
            redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
        };
        websecure.address = ":443";
      };

      certificatesResolvers.cloudflare.acme = {
        # Email is also read by Traefik from env if provided (CF_API_EMAIL).
        # Here we set storage and enable DNS challenge via Cloudflare.
        email = "${builtins.getEnv "CF_API_EMAIL" or "admin@example.invalid"}";
        storage = "/var/lib/traefik/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          # disablePropagationCheck = true; # optional, speeds up in labs
        };
      };

      log = {
        level = "INFO";
        format = "json";
        filePath = "/var/lib/traefik/traefik.log";
      };

      accessLog = {
        filePath = "/var/lib/traefik/access.log";
        bufferingSize = 100;
        fields = {
          defaultMode = "keep";
          headers = {
            defaultMode = "keep";
            names = {
              "X-Forwarded-For" = "keep";
              "CF-Connecting-IP" = "keep";
              "X-Real-IP" = "keep";
            };
          };
        };
      };
    };

    dynamicConfigOptions.http = {
      middlewares = {
        default-headers.headers = {
          sslRedirect = true;
          stsSeconds = 31536000;
          stsIncludeSubdomains = true;
          stsPreload = true;
          forceSTSHeader = true;
          frameDeny = true;
          sslTemporaryRedirect = true;
          browserXssFilter = true;
          contentTypeNosniff = true;
          referrerPolicy = "same-origin";
        };

        https-redirect.redirectScheme = {
          scheme = "https";
          permanent = true;
        };

        geniehome-ipwhitelist.ipWhiteList.sourceRange = [
          "192.168.20.0/24"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "127.0.0.1/32"
        ];

        primary.chain.middlewares = [
          "geniehome-ipwhitelist"
          "https-redirect"
          "default-headers"
        ];
      };

      routers = mergedRouters;
      services = mergedServices;
    };
  };

  # Open only what Traefik needs
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Cloudflare DNS API token

- In Cloudflare: Profile → API Tokens → Create token
- Choose “Custom token”
- Permissions:
  - Zone: Zone: Read
  - Zone: DNS: Edit
- Zone Resources: “Specific zone” → choose your root domain
- Create token and copy it

Create a secrets file:

```bash
mkdir -p secrets
cat > secrets/traefik.env <<'EOF'
CF_DNS_API_TOKEN=your_cloudflare_dns_api_token_here
CF_API_EMAIL=your_email@example.com
EOF
```

---

## SOPS-Nix

Secure Cloudflare credentials with `sops-nix` and `age`. We’ll keep only the encrypted `.env` in Git.

Generate an age key:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Copy the public key printed by `age-keygen` for the next command (the part starting with `age1...`).

Encrypt the env file (binary mode preserves `.env` formatting):

```bash
cd secrets
sops --age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  --input-type binary --output-type binary \
  --encrypt traefik.env > traefik.env.enc
```

Verify:

```bash
sops -d traefik.env.enc
```
