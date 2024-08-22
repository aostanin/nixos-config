{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.mpd;
in {
  options.localModules.mpd = {
    enable = lib.mkEnableOption "mpd";
  };

  config = lib.mkIf cfg.enable {
    programs.ncmpcpp = {
      enable = true;
      settings = {
        mpd_host = "tio";
        user_interface = "alternative";
      };
    };
  };
}
