# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/users/nix.nix
      ../../modules/docker_compose/traefik.nix
      ../../modules/docker/gitea.nix
      ../../modules/docker/authentik.nix
      ../../modules/docker_compose/komodo.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Mount for NFS
  fileSystems."/swarm" = {
    device = "/dev/sdb1";
    fsType = "ext4"; # Change this based on your filesystem type
  };
  fileSystems."/export/swarm" = {
    device = "/swarm";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export         192.168.20.4(rw,fsid=0,no_subtree_check,no_root_squash) 192.168.20.5(rw,fsid=0,no_subtree_check,no_root_squash) 192.168.20.11(rw,fsid=0,no_subtree_check,no_root_squash)
    /export/swarm   192.168.20.4(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.20.5(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.20.11(rw,nohide,insecure,no_subtree_check,no_root_squash)
  '';
  networking.hostName = "nix01"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable the Docker service
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    zsh
    openssl
    inputs.agenix.packages.${system}.agenix
    ceph
    git
  ];
  programs.zsh.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
   services.openssh = {
     enable = true;
     extraConfig = ''
       MaxAuthTries 100
     '';
   };

   # Enable Ceph
   #services.ceph.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 2377 7946 2049 ];
  networking.firewall.allowedUDPPorts = [ 2377 7946 4789 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
