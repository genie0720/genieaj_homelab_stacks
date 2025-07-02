{ config, pkgs, ... }:

{
  users.users.genie = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    description = "genie";
    extraGroups = [ "networkmanager" "docker" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 "
      "ssh-ed25519 "
    ];
  };
}
