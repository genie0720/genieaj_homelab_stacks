{ config, pkgs, ... }:

{
  users.users.nix = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "nix";
    extraGroups = [ "networkmanager" "docker" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-keys"
    ];
  };
}
