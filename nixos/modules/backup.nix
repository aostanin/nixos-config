{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.localModules.backup;
in {
  options.localModules.backup = {
    enable = lib.mkEnableOption "backup";

    paths = lib.mkOption {
      type = with lib.types; listOf path;
      description = "Which paths to backup.";
    };

    exclude = lib.mkOption {
      type = with lib.types; listOf path;
      default = [];
      description = "Which paths to exclude.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "restic/repository" = {};
      "restic/password" = {};
      "restic/ssh_key" = {};
    };

    services.restic.backups.remote = {
      inherit (cfg) paths exclude;
      repositoryFile = config.sops.secrets."restic/repository".path;
      passwordFile = config.sops.secrets."restic/password".path;
      extraOptions = [
        "sftp.args='-i ${config.sops.secrets."restic/ssh_key".path} -o StrictHostKeyChecking=no'"
      ];
      initialize = true;
      extraBackupArgs = [
        "--retry-lock=2h"
        "--exclude-caches"
      ];
      pruneOpts = [
        "--retry-lock=2h"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      timerConfig = {
        OnCalendar = "18:30";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
