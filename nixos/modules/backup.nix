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
      "pikvm/password" = {};
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
      # TODO: Only on WiFi and charging
      backupPrepareCommand = let
        inherit (secrets.pikvm) baseUrl username;
        passwordFile = config.sops.secrets."pikvm/password".path;
      in ''
        ssh_available()
        {
          nc -zw3 elena 22 > /dev/null 2>&1
        }

        is_on()
        {
          ${lib.getExe pkgs.curl} -s -k -u "${username}:$(cat ${passwordFile})" "${baseUrl}/api/gpio" | \
            ${lib.getExe pkgs.jq} -e '.result.state.inputs.atx1_power_led.state == true'
        }

        toggle_power()
        {
          ${lib.getExe pkgs.curl} -X POST -s -k -o /dev/null -u "${username}:$(cat ${passwordFile})" "${baseUrl}/api/gpio/pulse?channel=atx1_power_button"
        }

        wait_on()
        {
          until ssh_available; do sleep 1; done
        }

        if ! is_on; then
          toggle_power
          sleep 30
        fi
      '';
    };
  };
}
