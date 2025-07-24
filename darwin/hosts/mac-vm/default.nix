{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  nix = {
    enable = true;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [
        "root"
        "@admin"
      ];
    };
    linux-builder = {
      enable = true;
      ephemeral = true;
      config = {
        virtualisation = {
          darwin-builder = {
            memorySize = 8 * 1024;
          };
          cores = 4;
        };
      };
    };
  };

  programs.zsh.enable = true;

  # Passwordless sudo
  security.sudo.extraConfig = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
