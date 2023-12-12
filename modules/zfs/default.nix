{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:
with lib; let
  cfg = config.localModules.zfs;
in {
  options.localModules.zfs = {
    enable = mkEnableOption "zfs";
  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = ["zfs"];
      zfs = {
        forceImportRoot = false;
        allowHibernation = true;
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      trim.enable = true;
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = secrets.user.emailAddress;
          ZED_NOTIFY_VERBOSE = true;
        };
      };
    };
  };
}
