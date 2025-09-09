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

Once I’m in, I set up a clean directory structure for my Nix configs. I keep a top-level folder (I use `~/nixos`; use `~/nix-config` if you prefer).

I copy my `hardware-configuration.nix` and `configuration.nix` into the top-level—these are the base of the system setup.

Then I create a `modules` directory with a `services` subfolder to house service-specific modules (Traefik, CoreDNS, Jellyfin). Inside `services`, I keep host-specific Traefik configs in `traefik-hosts/` to stay modular and scalable.

Create the structure:

```bash
mkdir -p ~/nixos/modules/services/traefik-hosts
touch ~/nixos/modules/services/traefik.nix
touch ~/nixos/modules/services/jellyfin.nix
touch ~/nixos/modules/services/traefik-hosts/jellyfin.nix
```

Resulting layout:

```
~/nixos
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

## 🔗 Wiring modules into configuration.nix (placeholder)

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

## 🗝️ Secrets (SOPS + age) – Coming Soon

Planned:
- Integrate `sops-nix` to manage secrets (TLS certs, API keys, admin passwords) declaratively.
- Store encrypted files in `secrets/` and decrypt on activation using your age key.
- Recommended: generate an age key (`age-keygen -o ~/.age/key.txt`) and configure `sops.yaml` to target it.

---

## 🚦 Next Steps

- Add CoreDNS module (`modules/services/coredns.nix`) and configure zones/records for internal services.
- Define Traefik entrypoints, middleware, and TLS (LE or local CA).
- Populate `traefik-hosts/jellyfin.nix` with routers/services for Jellyfin.
- Add `sops-nix` and move secrets into encrypted files.

---

## ✅ Rebuild Cycle

After each change:

```bash
sudo nixos-rebuild switch
```

If using flakes:

```bash
sudo nixos-rebuild switch --flake ~/nixos#<hostname>
```

---

## Troubleshooting

- SSH not reachable? Verify `services.openssh.enable = true;` and that your firewall allows SSH (port 22).
- Flakes not working? Double-check `nix.settings.experimental-features = [ "nix-command" "flakes" ];`.
- `sops`/`age` not found? Ensure they’re in `environment.systemPackages`.

---

Happy homelabbing!
