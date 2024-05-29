{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.rsyncBackup;

  backupSubmodule = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        example = "root@machine:/storage/appdata";
        description = ''
          Backup source.
        '';
      };

      destination = lib.mkOption {
        type = lib.types.str;
        example = "/storage/backup";
        description = ''
          Backup destination.
        '';
      };
    };
  };
in {
  options.localModules.rsyncBackup = {
    enable = lib.mkEnableOption "rsync-backup";

    backups = lib.mkOption {
      type = lib.types.attrsOf backupSubmodule;
      description = ''
        Backups definition.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.timers = lib.mkMerge (lib.mapAttrsToList (name: backup: {
        "rsync-backup-${name}" = {
          wantedBy = ["timers.target"];
          partOf = ["rsync-backup-${name}.service"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "15m";
          };
        };
      })
      cfg.backups);

    systemd.services = lib.mkMerge (lib.mapAttrsToList (name: backup: {
        "rsync-backup-${name}" = {
          description = "rsync backup for ${name}";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          path = [pkgs.openssh];
          serviceConfig.Type = "oneshot";
          script = ''
            ${pkgs.rsync}/bin/rsync \
              -e "ssh -o StrictHostKeyChecking=no" \
              --verbose \
              --stats \
              --archive \
              --delete \
              --numeric-ids \
              --hard-links \
              --acls \
              --xattrs \
              --relative \
              --compress --compress-choice=lz4 \
              "${backup.source}" \
              "${backup.destination}"
          '';
        };
      })
      cfg.backups);
  };
}
