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

    allowHibernation = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = ["zfs"];
      zfs = {
        forceImportRoot = !cfg.allowHibernation;
        allowHibernation = cfg.allowHibernation;
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
