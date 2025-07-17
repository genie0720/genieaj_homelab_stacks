{ config, pkgs, lib, ... }:

{
  # Bootloader settings
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # Make sure to parameterize or override per-host if needed
    useOSProber = true;
  };

  # Timezone & Locale
  time.timeZone = "America/New_York";

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

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;

  # Default System Packages
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    zsh
    openssl
    git
    jq
  ];

  # Enable Docker and set backend
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

   # Enable networking
  networking.networkmanager.enable = true;


  # Nix experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Optional: Default shell
  programs.zsh.enable = true;

  # System version tracking
  system.stateVersion = "25.11";  # You can move this into `configuration.nix` if it needs host-specific tracking
}
