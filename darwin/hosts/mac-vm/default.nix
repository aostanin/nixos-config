{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        secrets.user.username
      ];
    };
    linux-builder.enable = true;
  };

  services.nix-daemon.enable = true;

  programs.zsh.enable = true;

  # Passwordless sudo
  security.sudo.extraConfig = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
