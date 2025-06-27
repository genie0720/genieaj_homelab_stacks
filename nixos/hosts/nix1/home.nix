{ config, pkgs, ... }:

{
  home.username = "nix";
  home.homeDirectory = "/home/nix";
  home.sessionVariables = {
   # PATH = "$HOME/.nix-profile/bin:$PATH";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      nrs1 = "sudo nixos-rebuild switch --flake /home/nix/configs#nix01";
      nrs2 = "sudo nixos-rebuild switch --flake /home/nix/configs#nix02 --target-host root@192.168.20.4";
      nrs3 = "sudo nixos-rebuild switch --flake /home/nix/configs#nix03 --target-host root@192.168.20.5";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "z" "extract" ];
      theme = "aussiegeek"; # Or another theme you like
    };
  };

  # Add autosuggestions and syntax highlighting as packages
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  # Source plugins manually
  programs.zsh.initContent = ''
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    # Show username@hostname followed by current working directory and a $ or #
    # PROMPT='%n@%m %~ %# '

  '';

  home.stateVersion = "23.11"; # Adjust to match your system version
}
