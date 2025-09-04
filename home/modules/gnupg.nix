{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.gnupg;
in {
  options.localModules.gnupg = {
    enable = lib.mkEnableOption "gnupg";
  };

  config = lib.mkIf cfg.enable {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
    };
  };
}
