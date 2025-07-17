{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;

    settings = {
      PermitRootLogin = "prohibit-password";  # Allows root login only via keys
      PasswordAuthentication = false;         # Enforce key-based access
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 100;
    };

    extraConfig = ''
      # Optional: Log connections, tweak behavior
    '';
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
