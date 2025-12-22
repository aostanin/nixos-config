{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.common;
in {
  options.localModules.common = {
    enable = lib.mkEnableOption "common";
  };

  config = lib.mkIf cfg.enable {
    localModules.homebrew.enable = lib.mkDefault true;

    system.primaryUser = secrets.user.username;

    nix = {
      enable = true;
      settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = [
          "root"
          "@admin"
        ];
      };
    };

    programs.zsh.enable = true;

    security.sudo.extraConfig = ''
      %admin ALL = (ALL) NOPASSWD: ALL
    '';

    fonts.packages = with pkgs; [
      nerd-fonts.hack
      noto-fonts
    ];

    environment.variables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
    };

    services = {
      openssh.enable = true;

      tailscale.enable = true;
    };
  };
}
